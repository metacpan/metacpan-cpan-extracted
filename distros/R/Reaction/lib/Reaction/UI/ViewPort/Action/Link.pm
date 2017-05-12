package Reaction::UI::ViewPort::Action::Link;

use Reaction::Class;
extends 'Reaction::UI::ViewPort';

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::URI qw/Uri/;
use MooseX::Types::Moose qw/Object CodeRef/;

has uri => ( is => 'rw', isa => Uri, lazy_build => 1);
has label => (is => 'rw', required => 1);

has target => (isa => Object, is => 'rw', required => 1);
has action => (isa => CodeRef, is => 'rw', required => 1);

sub BUILD {
  my $self = shift;
  $self->label( $self->label->($self->target) ) if ref $self->label eq 'CODE';
}

sub _build_uri {
  my $self = shift;
  my $c = $self->ctx;
  my ($c_name, $a_name, @rest) = @{ $self->action->($self->target, $c) };
  $c->uri_for($c->controller($c_name)->action_for($a_name),@rest);
}

__PACKAGE__->meta->make_immutable;

1;
