=head1 NAME

RT::Authen::OAuth2 Configuration

=head1 USER-CONFIGURABLE OPTIONS

=over 4

=item C<$EnableOAuth2>

Set this to enable the OAuth2 button on the login page.

    Set($EnableOAuth2, 1);

=back

=cut

Set($EnableOAuth2, 1);

=over 4

=item C<$OAuthCreateNewUser>

Set this to enable auto-creating new users based on the OAuth2 data.

    Set($OAuthCreateNewUser, 1);

=back

=cut

Set($OAuthCreateNewUser, 0);


=over 4

=item C<$OAuthNewUserOptions>

Set this to enable auto-creating new users based on the OAuth2 data.

    Set($OAuthNewUserOptions, {
            Privileged => 1,
        },
    );

=back

=cut

=over 4

=item C<$OAuthIDP>

Set this to the label of the Identity Provider endpoint you want to use.
The list of IDPs is in the internal configuration option C<OAuthIDPs>.
Default is C<'google'>.

    Set($OAuthIDP, 'google');

=back

=cut

Set($OAuthIDP, 'google');


=over 4

=item C<%MetadataMap>

B<NOTE>: This is a sub-key of C<$OAuthIDPs>. Each IDP has a MetadataMap.

This defines a mapping from the fields returned in the user's metadata, to
fields needed by this extension in RT. The C<EmailAddress> field is required,
and is used to identify the user account in the RT database. It must match
with the email returned by the Identity Provider.

=back

=cut


=over 4

=item C<%OAuthIDPSecrets> Client ID and Secret

B<REQUIRED>

You must set the B<Client ID> and B<Client Secret> here. These are given
to you by your Identity Provider. For Google, they are found in the
developer console where you configure the OAuth login. Each endpoint can
have its own set of secrets, so you must specify the endpoint name as
found in the C<%OAuthIDPs> internal config option.

    Set(%OAuthIDPSecrets,
        'google' => {
            client_id => '...',
            client_secret => '...',
        },
        ...
    );

=back

=cut

Set( %OAuthIDPSecrets, () );


=head1 INTERNAL CONFIGURATION DEFAULTS

=over 4

=item C<$OAuthRedirect>

This parameter is used by Google to define where the results are returned.
Must match what is configured in the Google Developer console, and the name
and path of the template components that handle the request. You should never
need to change this.

This should be a full URI (see rfc6819 section 4.1.5)

    Set($OAuthRedirect, RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect');

=back

=cut

Set($OAuthRedirect, RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect');


=over 4

=item C<%OAuthIDPs> Internal Options

These are defaults for common endpoints. They should only be modified
by the RT admin with good cause; most will want to leave these as they are.

Note, not all services listed here are tested and working. They may be added
as supported options in future releases, or by customer request.

See F<etc/OAuth_Config.pm> in this extension's directory tree for a list.

=back

=cut

# Note, Initial list borrowed from Net::OAuth2

Set(%OAuthIDPs,
    'google' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Google',
        'MetadataMap' => {
            EmailAddress => 'email',
            RealName => 'name',
            NickName => 'given_name',
            Lang => 'locale',
            Organization => 'hd',
        },
        'LoadColumn' => 'EmailAddress',
        'LoginPageButton' => '/static/images/btn_google_signin_dark_normal_web.png',
        'authorize_path' => '/o/oauth2/auth',
        'site' => 'https://accounts.google.com',
        'name' => 'Google Login',
        'protected_resource_url' => 'https://www.googleapis.com/userinfo/v2/me',
        'scope' => 'openid profile email',
        'access_token_path' => '/o/oauth2/token',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    'auth0' => {
        # You must Set($Auth0Host, "something.auth0.com");
        'MetadataHandler' => 'RT::Authen::OAuth2::Google',
        'MetadataMap' => {
            EmailAddress => 'email',
            RealName => 'name',
            NickName => 'nickname',
            Lang => 'not-provided',
            Organization => 'not-provided',
            VerifiedEmail => 'email_verified',
        },
        'LoginPageButton' => '/static/images/btn_auth0_signin.png',
        'authorize_path' => '/authorize',
        'site' => 'https://' . RT->Config->Get('Auth0Host'),
        'logout_path' => '/v2/logout?returnTo=__NEXT__&client_id=' . RT->Config->Get('OAuthIDPSecrets')->{'auth0'}->{'client_id'},
        'name' => 'Auth0',
        'protected_resource_path' => '/userinfo',
        'scope' => 'openid profile email',
        'access_token_path' => '/oauth/token',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    'instagram' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'access_token_path' => '/oauth/access_token',
        'site' => 'https://api.instagram.com',
        'scope' => 'comments relationships likes',
        'authorize_path' => '/oauth/authorize',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    '37signals' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'protected_resource_path' => '/authorization.xml',
        'authorize_path' => '/authorization/new',
        'name' => '37Signals',
        'access_token_path' => '/authorization/token',
        'site' => 'https://launchpad.37signals.com/',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    'yandex' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'protected_resource_url' => 'http://api-fotki.yandex.ru/api/me/',
        'name' => 'Yandex Direct',
        'site' => 'https://oauth.yandex.ru',
        'authorize_path' => '/authorize',
        'access_token_path' => '/token',
        'bearer_token_scheme' => 'auth-header',
        'username' => '',
        'password' => '',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    'facebook' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'site' => 'https://graph.facebook.com',
        'name' => 'Facebook',
        'protected_resource_path' => '/me',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
    'mixi' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'authorize_url' => 'https://mixi.jp/connect_authorize.pl',
        'name' => 'mixi',
        'access_token_url' => 'https://secure.mixi-platform.com/2/token',
        'site' => 'https://mixi.jp',
        'client_id' => '',
        'client_secret' => '',
        'state' => '',
    },
);

