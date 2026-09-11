package Punk::SAML;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Punk::SAML', $VERSION);

1;

__END__

=head1 NAME

Punk::SAML - SAML 2.0 service provider for Punk applications

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Punk;
    plugin 'SAML' => {
        entity_id => 'https://app.example.com/saml',
        idp       => {
            entity_id => 'https://idp.example.com/entity',
            metadata  => 'https://idp.example.com/metadata',
        },
        on_login  => sub {
            my ($c, $identity) = @_;
            $c->login($identity->{name_id});
        },
    };

=head1 DESCRIPTION

This module is the facade: it carries the version and loads the shared
object. The documentation lives in L<Punk::Plugin::SAML>.

Punk::SAML is a service provider. It lets an identity provider sign
users into a Punk application, over the Web Browser SSO profile, with
HTTP-Redirect out and HTTP-POST in. It is not an identity provider and
will not become one.

=head1 SEE ALSO

L<Punk::Plugin::SAML>, the real documentation.

L<Punk::SAML::Response>, L<Punk::SAML::Signature>, L<Punk::SAML::IdP>,
which are usable with no application booted, because C<punk saml verify>
is a tool an operator runs against a saved Response.

L<Punk::SAML::Error>, and the list of codes.

L<Punk::OAuth2>, for the other half of the single sign-on question.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
