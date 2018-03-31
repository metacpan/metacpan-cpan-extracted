use warnings;
use strict;
package RT::Authen::OAuth2::Google;

our $VERSION = '0.01';

use Net::OAuth2::Profile::WebServer;
use JSON;

=head1 NAME

RT::Authen::OAuth2::Google - Handler for Google OAuth2 logins

=cut

=head2 Example Metadata

=over 4

Google returns something like this:

 "id": "123456789012345678901",
 "email": "alice@wonderland.com",
 "verified_email": true,
 "name": "Alice Smith",
 "given_name": "Alice",
 "family_name": "Smith",
 "picture": "https://lh6.googleusercontent.com/big-ugly-url-path/photo.jpg",
 "locale": "en",
 "hd": "wonderland.com"

=back

=cut


=head2 Configuring Google

=over 4

Set up a Google Developer's console associated with your organization's Google
account. See B<https://console.developers.google.com>

Create a project. Under B<Credentials>, create an B<OAuth Client ID>, and
select B<Web Application>. Enter your B<Authorized Redirect URI> in this form:

    https://www.your-rt-domain.com/NoAuth/OAuthRedirect

The path C</NoAuth/OAuthRedirect> must be exactly as listed here, but you
should change your protocol and domain to match your configuration.

Make a note of the B<Client ID> and B<Client secret> listed on this page.
You will need to put these in your F<RT_SiteConfig.pm> - documentation is
in the F<etc/OAuth_Config.pm> file in this module.

Click B<Create>. Note if you edit the URI later, you may need to click
B<Save> twice. The Google user interface is a bit finicky.

=back

=cut


=head2 C<Metadata()>

=over 4

Takes one scalar string arg, containing the decoded response from the
protected resource server. Returns a hash containing key/value pairs of user
profile metadata items. Google returns JSON.

=back

=cut


sub Metadata {
    my ($self, $response_content) = @_;
    return (decode_json($response_content));
}

