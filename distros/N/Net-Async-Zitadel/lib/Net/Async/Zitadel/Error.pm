package Net::Async::Zitadel::Error;

# ABSTRACT: Structured exception classes for Net::Async::Zitadel

use Moo;

# namespace::clean must NOT be used here: it would strip the overload
# operator stub installed by 'use overload' below.
use overload '""' => sub { $_[0]->message }, fallback => 1;

our $VERSION = '0.001';


has message => (
    is       => 'ro',
    required => 1,
);

package Net::Async::Zitadel::Error::Validation;

use Moo;
extends 'Net::Async::Zitadel::Error';
use namespace::clean;

package Net::Async::Zitadel::Error::Network;

use Moo;
extends 'Net::Async::Zitadel::Error';
use namespace::clean;

package Net::Async::Zitadel::Error::API;

use Moo;
extends 'Net::Async::Zitadel::Error';
use namespace::clean;


has http_status => ( is => 'ro' );
has api_message => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Zitadel::Error - Structured exception classes for Net::Async::Zitadel

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::Async::Zitadel::Error;

    $z->oidc->verify_token_f($jwt)->then(sub {
        my ($claims) = @_;
        ...
    })->catch(sub {
        my ($err) = @_;
        if (ref $err && $err->isa('Net::Async::Zitadel::Error::API')) {
            warn "API error (HTTP " . $err->http_status . "): $err";
        }
        elsif (ref $err && $err->isa('Net::Async::Zitadel::Error::Validation')) {
            warn "Bad argument: $err";
        }
        else {
            Future->fail($err);
        }
    });

=head1 DESCRIPTION

Three exception classes, all inheriting from C<Net::Async::Zitadel::Error>:

=over 4

=item C<Net::Async::Zitadel::Error::Validation>

Missing/invalid arguments, empty issuer/base_url.

=item C<Net::Async::Zitadel::Error::Network>

OIDC endpoint HTTP failures (discovery, JWKS, userinfo, token).

=item C<Net::Async::Zitadel::Error::API>

Management API non-2xx responses. Carries C<http_status> and C<api_message>.

=back

All classes stringify to C<message> for backward compatibility.

=head2 message

Human-readable error description. The object stringifies to this value,
so C<eval>/C<$@>/C<Future> failure string-matching patterns continue to work.

=head2 http_status

The HTTP status line returned by the server, e.g. C<"400 Bad Request">.

=head2 api_message

The C<message> field from the JSON error body, if present.

=head1 SEE ALSO

L<Net::Async::Zitadel>, L<Net::Async::Zitadel::OIDC>, L<Net::Async::Zitadel::Management>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-zitadel/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
