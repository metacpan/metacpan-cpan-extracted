package Reaction::Meta::InterfaceModel::Object::DomainModelAttribute;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::Meta::Attribute';

__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

=head1 NAME

Reaction::Meta::InterfaceModel::Object::DomainModelAttribute

=head1 DESCRIPTION

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
