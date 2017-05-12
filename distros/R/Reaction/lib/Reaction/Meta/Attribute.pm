package Reaction::Meta::Attribute;

use Moose;

extends 'Moose::Meta::Attribute';

with 'Reaction::Role::Meta::Attribute';

no Moose;

#__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__;

=head1 NAME

Reaction::Meta::Attribute

=head1 SYNOPSIS

    has description => (is => 'rw', isa => 'Str', lazy_fail => 1);

=head1 Method-naming conventions

Reaction::Meta::Attribute will never override the values you set for method names,
but if you do not it will follow these basic rules:

Attributes with a name that starts with an underscore will default to using
builder and predicate method names in the form of the attribute name preceeded by
either "_has" or "_build". Otherwise the method names will be in the form of the
attribute names preceeded by "has_" or "build_". e.g.

   #auto generates "_has_description" and expects "_build_description"
   has _description => (is => 'rw', isa => 'Str', lazy_fail => 1);

   #auto generates "has_description" and expects "build_description"
   has description => (is => 'rw', isa => 'Str', lazy_fail => 1);

=head2 Predicate generation

All non-required or lazy attributes will have a predicate automatically
generated for them if one is not already specified.

=head2 lazy_fail

lazy_fail will fail if it is called without first having set the value.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
