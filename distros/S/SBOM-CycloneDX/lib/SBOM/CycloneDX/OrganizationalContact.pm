package SBOM::CycloneDX::OrganizationalContact;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has name  => (is => 'rw', isa => Str);
has email => (is => 'rw', isa => Str);
has phone => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'} = $self->bom_ref if $self->bom_ref;
    $json->{name}      = $self->name    if $self->name;
    $json->{email}     = $self->email   if $self->email;
    $json->{phone}     = $self->phone   if $self->phone;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::OrganizationalContact - Organizational Contact

=head1 SYNOPSIS

    SBOM::CycloneDX::OrganizationalContact->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::OrganizationalContact> provides the organizational contact object.

=head2 METHODS

L<SBOM::CycloneDX::OrganizationalContact> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::OrganizationalContact->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An optional identifier which can be used to reference the
object elsewhere in the BOM. Every bom-ref must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<email>, The email address of the contact.

=item C<name>, The name of a contact

=item C<phone>, The phone number of the contact.

=back

=item $organizational_contact->bom_ref

=item $organizational_contact->email

=item $organizational_contact->name

=item $organizational_contact->phone

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
