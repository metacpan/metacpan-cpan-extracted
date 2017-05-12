package Reaction::Object;

use Reaction::Meta::Class;
use metaclass 'Reaction::Meta::Class';

use Moose qw(extends);

extends 'Moose::Object';

__PACKAGE__->meta->make_immutable;

no Moose;

1;

=head1 NAME

Reaction::Object

=head1 DESCRIPTION

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
