package Reaction::UI::ViewPort::SiteLayout;

use Reaction::Class;
extends 'Reaction::UI::ViewPort';

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Str HashRef/;

has 'title' => (isa => Str, is => 'rw', lazy_fail => 1);
has 'static_base_uri' => (isa => Str, is => 'rw', lazy_fail => 1);
has 'meta_info' => (
  is => 'rw',
  isa => HashRef,
  required => 1,
  default => sub { {} }
);

__PACKAGE__->meta->make_immutable;

1;
