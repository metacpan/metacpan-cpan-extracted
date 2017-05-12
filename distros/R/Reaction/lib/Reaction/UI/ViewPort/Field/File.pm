package Reaction::UI::ViewPort::Field::File;

use Reaction::Class;
use Reaction::Types::File;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field';

use MooseX::Types::Moose qw/CodeRef/;

has '+value' => (isa => Reaction::Types::File::File());

has uri    => ( is => 'rw', lazy_build => 1);

has action => (isa => CodeRef, is => 'rw', required => 1);

sub _build_uri {
  my $self = shift;
  my $c = $self->ctx;
  my ($c_name, $a_name, @rest) = @{ $self->action->($self->model, $c) };
  $c->uri_for($c->controller($c_name)->action_for($a_name),@rest);
}

sub _value_string_from_value {
    shift->value->stringify;
}

__PACKAGE__->meta->make_immutable;


1;
