package Reaction::InterfaceModel::Collection::Persistent;

use Reaction::Class;
use aliased 'Reaction::InterfaceModel::Collection';

use namespace::clean -except => [ qw(meta) ];
extends Collection;




__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::InterfaceModel::Collection::Persistent - Base class for Presistent Collections

=head1 DESCRIPTION

A subclass of L<Reaction::InterfaceModel::Collection>s, this class is a base
to Persistent collections.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
