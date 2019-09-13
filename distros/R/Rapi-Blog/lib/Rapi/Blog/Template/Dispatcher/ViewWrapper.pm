package Rapi::Blog::Template::Dispatcher::ViewWrapper;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'Rapi::Blog::Template::Dispatcher';

use Types::Standard ':all';


has 'ViewWrapper',  is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->resolve_ViewWrapper($self->path)
}, isa => InstanceOf['Rapi::Blog::Scaffold::ViewWrapper'];


has 'subpath', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->ViewWrapper ? $self->ViewWrapper->resolve_subpath($self->path) : undef
}, isa => Maybe[Str];


sub rank { 30 }

has 'PostDispatcher', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->_factory_for('Post', name => $self->subpath);
};#, isa => InstanceOf['Rapi::Blog::Template::Dispatcher::Post'];


has '+exists',        default => sub { (shift)->PostDispatcher->exists         };
has '+mtime',         default => sub { (shift)->PostDispatcher->mtime          };
has '+template_vars', default => sub { (shift)->PostDispatcher->template_vars  };


has '+content', default => sub {
  my $self = shift;
  $self->ViewWrapper->render_post_wrapper($self->subpath)
};



sub resolved {
  my $self = shift;
  
  $self->subpath or return undef;

  my $FileDispatcher = $self->_factory_for('ScaffoldFile', path => $self->subpath);
  return $FileDispatcher if ($FileDispatcher->is_static);
  
  $self->exists ? $self : $self->_factory_for('NotFound')
  
}







1;