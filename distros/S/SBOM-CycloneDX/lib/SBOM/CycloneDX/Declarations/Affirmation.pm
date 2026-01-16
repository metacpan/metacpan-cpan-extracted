package SBOM::CycloneDX::Declarations::Affirmation;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(InstanceOf HashRef Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has statement => (is => 'rw', isa => Str);

has signatories => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Signatory']],
    default => sub { SBOM::CycloneDX::List->new }
);

has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{statement}   = $self->statement   if $self->statement;
    $json->{signatories} = $self->signatories if @{$self->signatories};
    $json->{signature}   = $self->signature   if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Affirmation - Affirmation

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Affirmation->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Affirmation> provides a concise statement affirmed
by an individual regarding all declarations, often used for third-party
auditor acceptance or recipient acknowledgment. It includes a list of
authorized signatories who assert the validity of the document on behalf of
the organization.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Affirmation> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Affirmation->new( %PARAMS )

Properties:

=over

=item C<signatories>, The list of signatories authorized on behalf of an
organization to assert validity of this document.

=item C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=item C<statement>, The brief statement affirmed by an individual regarding
all declarations.
*- Notes This could be an affirmation of acceptance by a third-party
auditor or receiving individual of a file.

=back

=item $affirmation->signatories

=item $affirmation->signature

=item $affirmation->statement

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

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
