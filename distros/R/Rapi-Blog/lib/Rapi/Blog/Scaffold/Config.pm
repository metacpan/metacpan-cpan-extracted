package Rapi::Blog::Scaffold::Config;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

use Moo;
use Types::Standard ':all';

use YAML::XS 0.64 'LoadFile';

has 'favicon',            is => 'rw', isa => Maybe[Str],        default => sub { 'favicon.ico' };
has 'landing_page',       is => 'rw', isa => Maybe[Str],        default => sub { 'index.html' };
has 'internal_post_path', is => 'rw', isa => Maybe[Str],        default => sub { 'private/post/' };
has 'default_view_path',  is => 'rw', isa => Maybe[Str],        default => sub { 'post/' };
has 'not_found',          is => 'rw', isa => Maybe[Str],        default => sub { undef };
has 'view_wrappers',      is => 'rw', isa => ArrayRef[HashRef], default => sub { [] };
has 'static_paths',       is => 'rw', isa => ArrayRef,          default => sub { [] };
has 'template_names',     is => 'rw', isa => ArrayRef,          default => sub { ['*'] };
has 'private_paths',      is => 'rw', isa => ArrayRef,          default => sub { [] };
has 'default_ext',        is => 'rw', isa => Maybe[Str],        default => sub { 'html' };

has 'preview_path', is => 'rw', lazy => 1, default => sub { (shift)->default_view_path }, isa => Maybe[Str];


has '_supplied_params', is => 'ro', isa => HashRef, required => 1;
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref

  $params{_supplied_params} = { %params };
  $class->$orig(%params)
};


sub BUILD {
  my $self = shift;
  $self->_apply_params( $self->_supplied_params )
}

 
has '_extra_params', is => 'rw', isa => HashRef, default => sub { {} };
sub AUTOLOAD {
  my $self = shift;
  my $meth = (reverse(split('::',our $AUTOLOAD)))[0];
  $self->_extra_params->{$meth}
}


sub _load_from_yaml {
  my $self = shift;
  my $yaml_file = shift or die "Missing required yaml_file argument";
  -e $yaml_file or die "YAML file '$yaml_file' not found";
  
  my $data = LoadFile( $yaml_file );
  
  $self->_apply_params( $data, 1 );
  
  #for (keys %$data) {
  #  if ($self->_supplied_params->{$_}) { # Don't override any user-supplied params
  #    delete $data->{$_}
  #  }
  #  elsif ($self->can($_)) {
  #    $self->$_( delete $data->{$_} ) 
  #  }
  #}
  #
  ## Save leftover params so they can still be accessed via AUTOLOAD
  #$self->_extra_params( $data );
 
}



sub _apply_params {
  my ($self, $new_params, $no_ovr) = @_;
  
  my $params = clone( $new_params );
  
  for (keys %$params) {
    if ($no_ovr && $self->_supplied_params->{$_}) { # Don't override any user-supplied params
      delete $params->{$_}
    }
    elsif ($self->can($_)) {
      $self->$_( delete $params->{$_} ) 
    }
  }
  
  # Save leftover params so they can still be accessed via AUTOLOAD
  my $extra = $self->_extra_params || {};
  $self->_extra_params( { %$extra, %$params } );
}



sub _has_param {
  my ($self, $p) = @_;
  $self->can($p) || exists $self->_extra_params->{$p}
}



sub _all_as_hash {
  my $self = shift;
  
  return {
    map  { $_ => $self->$_ }
     grep { ! /^_/ } # exclude "private" attributes with start with underscore '_'
     keys %{ $self->_extra_params },
     $self->meta->get_attribute_list
  }
}


1;