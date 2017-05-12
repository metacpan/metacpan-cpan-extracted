package MooseX::Alien;
## Copyright (C) Graham Barr
## vim: ts=8:sw=2:expandtab:shiftround

use strict;
use warnings;

our $VERSION = '1.01';

# Cannot import from Moose::Role as that would call init_meta, but without metaclass
use Moose::Role ();

Moose::Role->init_meta(
  for_class => 'MooseX::Alien',
  metaclass => 'MooseX::Alien::Meta'
);


($Moose::VERSION >= 0.90 ? __PACKAGE__->meta : __PACKAGE__)->Moose::Role::around(
  'new' => sub {
    my $orig   = shift;
    my $obj    = $orig->(@_);
    my $class  = shift;
    my $params = $class->BUILDARGS(@_);
    $params->{__INSTANCE__} = $obj;
    my $self = $class->meta->new_object($params);
    delete $params->{__INSTANCE__};
    $self->BUILDALL($params);
    return $self;
  }
);

package MooseX::Alien::Meta;
use base qw(Moose::Meta::Role);

sub apply {
  my $self   = shift;
  my $other  = shift;
  my @supers = $other->superclasses;

  my $moose_supers = grep { $_->isa('Moose::Object') } @supers;
  if (@supers == $moose_supers) {
    Moose->throw_error("Must call extends with alien class before applying MooseX::Alien role");
  }

  $other->superclasses(@supers, 'Moose::Object')
    unless $moose_supers;

  # Traverse superclasses, if first that defines a new method
  # is not a Moose::Object, then we need to wrap it
  foreach my $super (@supers) {
    return if $super->isa('Moose::Object');
    if ($super->can('new')) {
      $self->SUPER::apply($other, @_);
    }
  }
}

1;

__END__

=head1 NAME

  MooseX::Alien - Extend a non-Moose class with Moose

=head1 SYNOPSIS

  package MyApp::Context;

  use Moose;
  extends 'Mojolicious::Context';
  with 'MooseX::Alien;

=head1 DESCRIPTION

The fact that Moose objects are hashrefs means it is easy to use
Moose to extend non-Moose classes, as long as they too are hash
references.

This role usses an approach similar to the defined in L<Moose::Cookbook::FAQ>.
However this role will call BUILDARGS and BUILDALL

This approach may not work for all classes. The alien class must be implemented using
a HASHREF and the constructor must accept either a list of name/value pairs or a HASHREF

=head1 SEE ALSO

L<Moose::Cookbook::FAQ> L<MooseX::NonMoose>

=head1 AUTHOR

Graham Barr <gbarr@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Graham Barr

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

