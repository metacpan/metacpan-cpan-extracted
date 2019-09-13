package Rapi::Blog::Scaffold;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use Scalar::Util 'blessed';
use List::Util;
use String::Random;

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




sub owns_path {
  my ($self, $path) = @_;
  $self->owns_path_as($path) ? 1 : 0
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

has '_private_path_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->private_paths});
};

sub _compile_path_list_regex {
  my ($self, @paths) = @_;
  return undef unless (scalar(@paths) > 0);
  
  my @list = ();
  for my $path (@paths) {
    next if ($path eq ''); # empty string match nothing
    push @list, '^.*$' and next if($path eq '/') ; # special handling for '/' -- match everything

    $path =~ s/^\///; # strip and ignore leading /
    if ($path =~ /\/$/) {
      # ends in slash, matches begining of the path
      push @list, join('','^',$path);
    }
    else {
      # does not end in slash, match as if it did AND the whole path
      push @list, join('','^',$path,'/');
      push @list, join('','^',$path,'$');
    }
  }
  
  return undef unless (scalar(@list) > 0);
  
  my $reStr = join('','(',join('|', @list ),')');
  
  return qr/$reStr/
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

sub _is_private_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_private_path_regexp;
  $Regexp ? $template =~ $Regexp : 0
}


sub resolve_path {
  my $self = shift;
  my $path = shift or return undef;
  
  my $File = $self->resolve_file($path);
  
  # If not found, try once more by appending the default file extenson:
  $File = $self->resolve_file(join('.',$path,$self->default_ext)) if (!$File && $self->default_ext);
  
  $File
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