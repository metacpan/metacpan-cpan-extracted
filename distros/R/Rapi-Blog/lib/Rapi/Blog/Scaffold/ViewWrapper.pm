package Rapi::Blog::Scaffold::ViewWrapper;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

use Moo;
use Types::Standard ':all';

has 'Scaffold',  is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Scaffold'];

has 'path',      is => 'ro', required => 1, isa => Str;
has 'type',      is => 'ro', required => 1, isa => Enum[qw/include insert/];
has 'wrapper',   is => 'ro', required => 1, isa => Str;

has 'not_found_template', is => 'ro', isa => Maybe[Str], default => sub {undef};


sub BUILD {
  my $self = shift;
  
  my $path    = $self->path    or die "ViewWrapper: path is required";
  my $wrapper = $self->wrapper or die "ViewWrapper: wrapper is required";
  
  die "ViewWrapper: bad path '$path' - must start with a normal alpha character" unless ($path =~ /^\w/);
  die "ViewWrapper: bad path '$path' - must end with a trailing slash (/)" unless ($path =~ /\/$/);
}

sub _enforce_wrapper_exists {
  my $self = shift;
  my $wrapper = $self->wrapper;
  $self->Scaffold->resolve_file($wrapper) or die join('',
    "Error! view wrapper '$wrapper' not found within scaffold"
  )
}


sub valid_not_found_template {
  my $self = shift;
  my $nft = $self->not_found_template;
  $nft && $self->Scaffold->resolve_file($nft) ? $nft : undef
}

sub handles_not_found {
  my $self = shift;
  $self->valid_not_found_template ? 1 : 0
}


sub resolve_subpath {
  my $self = shift;
  my $template = shift or return undef;
  
  # First check to see if this is even our path prefix:
  my ($pfx,$name) = split($self->path,$template,2);

  ($name && $pfx eq '') ? $name : undef
}



#sub template_content_for {
#  my ($self, $path) = @_;
#  my $name = $self->resolve_claimed_post_name($path) or return undef;
#  
#  unless ($self->Scaffold->Post_exists_fn->($name)) {
#    $name = $self->not_found_template or return undef;
#  }
#
#  my $directive = 
#    $self->type eq 'include' ? 'INCLUDE' :
#    $self->type eq 'insert'  ? 'INSERT'  :
#    die "Unexpected error -- 'type' must be 'include' or 'insert'";
#  
#  return join("\n",
#    join('','[% META local_name = "',$name,'" %]'),
#    join('','[% WRAPPER "',$self->wrapper,'" %]'),
#    join('','[% ', $directive, ' "',$self->Scaffold->unique_int_post_path,$name,'" %]'),
#    '[% END %]'
#  )
#}



sub render_post_wrapper {
  my ($self, $name) = @_;
  
  $self->_enforce_wrapper_exists;
  
  my $directive = 
    $self->type eq 'include' ? 'INCLUDE' :
    $self->type eq 'insert'  ? 'INSERT'  :
    die "Unexpected error -- 'type' must be 'include' or 'insert'";
  
  return join("\n",
    join('','[% META local_name = "',$name,'" %]'),
    join('','[% WRAPPER "',$self->wrapper,'" %]'),
    join('','[% ', $directive, ' "',$self->Scaffold->unique_int_post_path,$name,'" %]'),
    '[% END %]'
  )
}




1;