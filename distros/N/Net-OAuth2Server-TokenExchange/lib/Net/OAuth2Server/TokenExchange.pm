use strict; use warnings;

package Net::OAuth2Server::TokenExchange;
our $VERSION = '0.004';

use Net::OAuth2Server::Request::Token::TokenExchange ();

package Net::OAuth2Server::Response::Role::TokenExchange;
our $VERSION = '0.004';

use Role::Tiny;
use Class::Method::Modifiers 'fresh';

sub fresh__add_issued_token_type { shift->add( issued_token_type => @_ ) }
fresh add_issued_token_type => \&fresh__add_issued_token_type;
undef *fresh__add_issued_token_type;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OAuth2Server::TokenExchange - A Token Exchange extension for Net::OAuth2Server

=head1 DISCLAIMER

B<I cannot promise that the API is fully stable yet.>
For that reason, no documentation is provided.

=head1 DESCRIPTION

A simple implementation of OAuth 2.0 Token Exchange.

=head1 SEE ALSO

=over 2

=item *

L<RFCE<nbsp>8693, I<OAuth 2.0 Token Exchange>|https://www.rfc-editor.org/rfc/rfc8693.html>

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
