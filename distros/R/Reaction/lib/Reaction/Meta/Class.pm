package Reaction::Meta::Class;

use Moose;
use Reaction::Meta::Attribute;

extends 'Moose::Meta::Class';

with 'Reaction::Role::Meta::Class';

no Moose;

#__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::Meta::Class

=head1 DESCRIPTION

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
