package Punk::SAML::Response;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Response - a Response, verified

=head1 DESCRIPTION

Verifies a Response and returns the identity it carries.

Usable with no application booted, which is what lets C<punk saml verify>
run against a saved document and the suite run this a thousand times with
no HTTP at all.

=head1 METHODS

=head2 verify ($bytes, %opts)

The decoded XML in, an identity hashref out, or a L<Punk::SAML::Error>
thrown. Required options are C<entity_id> (this application's),
C<idp_entity_id> (the provider's), C<acs_url> and C<certs>. Optional:
C<idp>, C<now>, C<skew>, C<require_signed>, C<allow_sha1>,
C<allow_idp_initiated>, C<in_response_to> and C<seen>.

C<now> is an argument rather than a call to C<time>, so a test and
C<punk saml verify --at> can move it without sleeping.

C<seen> is the replay store: a coderef called with the assertion id,
returning true if it has been presented before. It is an argument because
whether the store is shared across the worker pool is the application's
decision, and this method has no application.

=head2 The identity

    {
        idp             => 'okta',
        name_id         => 'jo@example.com',
        name_id_format  => '...',
        attributes      => { groups => ['staff', 'eng'] },
        friendly        => { 'E-Mail Address' => ['jo@example.com'] },
        session_index   => '_a1b2...',
        authn_instant   => 1725600000,
        not_on_or_after => 1725600300,
        assertion_id    => '_c3d4...',
        raw             => $bytes,
    }

B<Every attribute value is an arrayref, always,> including when there is
one value. SAML attributes are multi-valued and C<groups> is the one
everybody uses; an API that returned a scalar for one value and an
arrayref for two would be the bug every C<on_login> body has on the day a
user joins a second group. A provider that sends the same C<Name> twice
has its values merged rather than replaced.

=head1 WHAT IS CHECKED

In order, and the order matters: cheap before expensive, structural
before cryptographic, and B<the signature before anything the signature
protects is read>.

The element whose child the C<Signature> is, is the element the signature
covers, is the element the identity is read from. Every SAML
authentication bypass of the last decade is a document where those three
were allowed to differ.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
