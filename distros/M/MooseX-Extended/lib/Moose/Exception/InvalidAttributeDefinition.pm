package Moose::Exception::InvalidAttributeDefinition;

# ABSTRACT: MooseX::Extended exception for invalid attribute definitions.

use Moose;
extends 'Moose::Exception';
our $VERSION = '0.10';
with 'Moose::Exception::Role::Class';

has 'attribute_name' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "This exception is thrown if an attribute definition is invalid.",
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Exception::InvalidAttributeDefinition - MooseX::Extended exception for invalid attribute definitions.

=head1 VERSION

version 0.10

=head1 WHY NOT MOOSEX?

This is not called C<MooseX::Exception::InvalidAttributeDefinition> because
L<Moose::Util>'s C<throw_exception> function assumes that all exceptions begin
with C<Moose::Exception::>.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
