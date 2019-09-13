package Rapi::Blog::Template::Dispatcher::ScaffoldFile;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';

has 'File', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->is_static
    ? $self->Scaffold->resolve_file($self->path)
    : $self->Scaffold->resolve_path($self->path)
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


sub resolved {
  my $self = shift;
  $self->exists ? $self : $self->_factory_for('NotFound')
}


sub rank { 100 }




has '+maybe_psgi_response', default => sub {
  my $self = shift;
  
  # Deny *outside* requests to private paths
  $self->is_private and return $self->_factory_for('NotFound')->maybe_psgi_response;
  
  $self->is_static and $self->File or return undef;
  
  my $tpl = $self->path;

  $self->Scaffold->static_path_app->({
    %{ $self->ctx->req->env },
    PATH_INFO   => "/$tpl",
    SCRIPT_NAME => ''
  })
};
  


1;