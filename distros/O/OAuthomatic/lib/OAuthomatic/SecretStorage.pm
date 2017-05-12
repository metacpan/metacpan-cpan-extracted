package OAuthomatic::SecretStorage;
# ABSTRACT: Save and restore confidential OAuth tokens

use Moose::Role;
use OAuthomatic::Types;
use namespace::sweep;


# FIXME: SecretStorage/Fixed - implement and mention here


requires 'get_client_cred';


requires 'save_client_cred';


requires 'clear_client_cred';


requires 'get_token_cred';


requires 'save_token_cred';


requires 'clear_token_cred';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::SecretStorage - Save and restore confidential OAuth tokens

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Interface defining methods used to save and restore various
credentials. Implementations should use some kind of reasonably secure
persistent storage, to preserve data over reruns.

Note: methods below are parameterless (except saved tokens), but
should operate on access to specific remote site. Typical
implementation would have required parameers like C<site_name> and
C<password_group> in the constructor.

See L<OAuthomatic::SecretStorage::Keyring> for default implementation
(and example).

=head1 METHODS

=head2 get_client_cred() => ClientCred(...)

Return saved client tokens (client_key, client_secret), or undef if
those were not (yet) saved. Returns L<OAuthomatic::Types::ClientCred>.

=head2 save_client_cred(client_cred)

Save client tokens for future use.

Parameter is L<OAuthomatic::Types::ClientCred>.

Never called if L<get_client_cred> always returns some data. This method is used to save
keys user provided after beint interactively asked.

=head2 clear_client_cred()

Clear client tokens, if any are saved.

Called in case restored tokens turn out invalid, expired, etc.

=head2 get_token_cred() => TokenCred(...)

Restore previously saved token and secret (access token, access
secret), or undef if those were not (yet) saved. Returns
L<OAuthomatic::Types::ClientCred>.

=head2 save_token_cred(token_cred)

Saves token for future use, to be preserved over program restarts.
Parameter is of type L<OAuthomatic::Types::ClientCred>.

=head2 clear_token_cred()

Clear token, if it was saved. Called in case token is found to be
wrong or expired.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
