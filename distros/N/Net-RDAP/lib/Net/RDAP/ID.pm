package Net::RDAP::ID;
use base qw(Net::RDAP::Base);
use strict;
use warnings;

=head1 NAME

L<Net::RDAP::ID> - a module representing a public identifier in an RDAP
response.

=head1 DESCRIPTION

RDAP objects may have zero or more "public identifiers", which map a
public identifier to an object class.

Any object which inherits from L<Net::RDAP::Object> will have an
C<ids()> method which will return an array of zero or more
L<Net::RDAP::ID> objects.

=head1 METHODS

=head2 ID Type

    $type = $id->type;

Returns a string containing the type of public identifier.

=cut

sub type { $_[0]->{'type'} }

=pod

=head2 Identifier

    $identifier = $id->identifier;

Returns a string containing a public identifier of the type denoted by
the C<type>.

=cut

sub identifier { $_[0]->{'identifier'} }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
