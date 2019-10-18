package Rapi::Blog::Scaffold;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use Scalar::Util 'blessed';
use List::Util;
use String::Random;
require Text::Glob;

use Moo;
use Types::Standard ':all';

use Rapi::Blog::Scaffold::Config;
use Rapi::Blog::Scaffold::ViewWrapper;

use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;

require Path::Class;
use YAML::XS 0.64 'LoadFile';


sub factory {
  my ($self, $new) = @_;
  
  # passthrough is its already one of us:
  return $new if (ref($new) && ref($new) eq __PACKAGE__);
  
  __PACKAGE__->new( dir => $new )
}


has 'uuid', is => 'ro', init_arg => undef, 
  default => sub { join('-','scfld',String::Random->new->randregex('[a-z0-9A-Z]{20}')) };

has 'dir', 
  is       => 'ro', 
  required => 1, 
  isa      => InstanceOf['Path::Class::Dir'],
  coerce   => sub { Path::Class::dir($_[0]) };


has 'config', 
  is      => 'ro',
  isa     => InstanceOf['Rapi::Blog::Scaffold::Config'],
  default => sub {{}},
  coerce  => sub { blessed $_[0] ? $_[0] : Rapi::Blog::Scaffold::Config->new($_[0]) };

# The Scaffold needs to be able to check if a given Post exists in the database  
#has 'Post_exists_fn', is => 'ro', required => 1, isa => CodeRef;


sub static_paths       { (shift)->config->static_paths       }
sub template_names     { (shift)->config->template_names     }
sub private_paths      { (shift)->config->private_paths      }
sub default_ext        { (shift)->config->default_ext        }
sub view_wrappers      { (shift)->config->view_wrappers      }
sub internal_post_path { (shift)->config->internal_post_path }

# This is a unique, private path which is automatically generated that allows this
# scaffold to own a path which it can use fetch a post, and be sure another scaffold
# wont claim the path
has 'unique_int_post_path', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  join('','_',$self->uuid,'/private/post/')
};

sub not_found_template { (shift)->config->not_found }



has 'ViewWrappers', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return [ map {
    Rapi::Blog::Scaffold::ViewWrapper->new( 
      Scaffold => $self, %$_ 
    ) 
  } @{$self->config->view_wrappers} ]
}, isa => ArrayRef[InstanceOf['Rapi::Blog::Scaffold::ViewWrapper']];




sub BUILD {
  my $self = shift;
  $self->_load_yaml_config;
}


sub _load_yaml_config {
  my $self = shift;
  
  my $yaml_file = $self->dir->file('scaffold.yml');
  $self->config->_load_from_yaml($yaml_file) if (-f $yaml_file);
}


sub resolve_ViewWrapper {
  my $self = shift;
  my $path = shift or return undef;
  
  my $subpath;
  my $VW = List::Util::first { $subpath = $_->resolve_subpath($path) } @{ $self->ViewWrappers };
  return undef unless $VW;
  
  wantarray ? ($VW, $subpath) : $VW
}



sub _resolve_path_to_post {
  my ($self, $path) = @_;
  
  my ($pfx,$name) = split($self->unique_int_post_path,$path,2);
  ($name && $pfx eq '') ? $name : undef
}



has '_static_path_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->static_paths});
};

has '_template_name_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->template_names});
};

has '_private_path_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->private_paths});
};


sub _compile_path_list_regex {
  my ($self, @paths) = @_;
  my $reStr = $self->_get_path_list_regex_string(@paths);# or return undef;
  qr/$reStr/
}


sub __re_always    { '(^.+$)'    } # Always matches
sub __re_never     { '(?=a)[^a]' } # Never matches

sub _glob_to_re_str {
  my ($self,$glob) = @_;
  
  my $re = Text::Glob::glob_to_regex_string($glob);
  
  # unless the glob ends in a *, we do not 
  # want to match past the end of the pattern
  $glob =~ /\*$/ ? $re : $re.'$'
}

sub _get_path_list_regex_string {
  my ($self, @paths) = @_;
  return undef unless (scalar(@paths) > 0);
  
  my @gList  = ();
  my @eqList = ();
  for my $path (@paths) {
    next if ($path eq ''); # empty string match nothing
    
    # Either * or / match everything. Bail out and return the match everything regex
    return $self->__re_always if ($path eq '*' || $path eq '/');

    $path =~ s/^\///; # strip and ignore leading /
    $path .= '*' if ($path =~ /\/$/); # append wildcard if we end in / we want to match everything that follows
    
    # Check for any glob pattern special characters:
    $path =~ /[\*\?\[\]\{\}]/ ? push(@gList, $path) : push(@eqList,$path);
  }
  
  local $Text::Glob::strict_leading_dot    = 0;
  local $Text::Glob::strict_wildcard_slash = 0;
  
  my @re_list = (
    (map { $self->_glob_to_re_str($_) } @gList ),
    (map { join('','^',quotemeta($_),'$') } @eqList )
  );
  
  my $reStr = join('','(',join('|', @re_list ),')');
  
  $reStr ? $reStr : $self->__re_never
}




has 'static_path_app', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $app = builder {
    enable "ConditionalGET";
    Plack::App::File->new(root => $self->dir)->to_app;
  };
  
  sub {
    my $env = shift;
    my $res = $app->($env);
    # limit caching to 10 minutes now that we return 304s
    push @{$res->[1]}, 'Cache-Control', 'public, max-age=600';
    
    $res
  }
};



sub _is_static_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_static_path_regexp;
  $Regexp ? $template =~ $Regexp : 0
}

sub _is_valid_template_name {
  my ($self, $name) = @_;
  my $Regexp = $self->_template_name_regexp;
  $Regexp ? $name =~ $Regexp : 0
}

sub _is_private_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_private_path_regexp;
  $Regexp ? $template =~ $Regexp : 0
}


sub resolve_file {
  my $self = shift;
  my $path = shift or return undef;
  
  my $File = $self->dir->file($path);
  -f $File ? $File : undef
}


sub resolve_static_file {
  my ($self, $path) = @_;
  $path && $self->_is_static_path($path) or return undef;
  $self->resolve_file($path)
}


1;