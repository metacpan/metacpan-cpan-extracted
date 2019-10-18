package Rapi::Blog::Template::Dispatcher::ScaffoldFile;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';


has '_resolve_file_cache', is => 'ro', default => sub {{}};
sub _resolve_file {
  my ($self,$path) = @_;
  my $h = $self->_resolve_file_cache;
  $h->{$path} = $self->Scaffold->resolve_file($path) unless (exists $h->{$path});
  $h->{$path}
}

has 'effective_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->path if (
    $self->is_static 
    || ! $self->Scaffold->default_ext 
    || $self->_resolve_file($self->path)
  );
  
  my $epath = join('.',$self->path,$self->Scaffold->default_ext);
  $self->_resolve_file($epath) ? $epath : $self->path
}, isa => Str;


has 'File', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->_resolve_file( $self->effective_path )
}, isa => Maybe[InstanceOf['Path::Class::File']];


has '+exists', default => sub {
  my $self = shift;
  $self->File ? 1 : 0
};

has '+mtime', default => sub {
  my $self = shift;
  my $File = $self->File or return undef;
  my $Stat = $File->stat or return undef;
  $Stat->mtime
};

has '+content', default => sub {
  my $self = shift;
  my $File = $self->File or return undef;
  scalar $File->slurp
};


has 'renders_static', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return 0 unless $self->File;
  return 1 if $self->is_static;

  my ($path_fn) = reverse split(/\//,$self->effective_path);

  $path_fn eq $self->File->basename && ! $self->Scaffold->_is_valid_template_name($self->effective_path)

}, isa => Bool;


sub resolved {
  my $self = shift;
  $self->exists ? $self : $self->_factory_for('NotFound')
}


sub rank { 100 }




has '+maybe_psgi_response', default => sub {
  my $self = shift;
  
  # Deny *outside* requests to private paths
  $self->is_private and return $self->_factory_for('NotFound')->maybe_psgi_response;
  
  $self->renders_static or return undef;
  
  my $tpl = $self->path;

  $self->Scaffold->static_path_app->({
    %{ $self->ctx->req->env },
    PATH_INFO   => "/$tpl",
    SCRIPT_NAME => ''
  })
};
  


1;