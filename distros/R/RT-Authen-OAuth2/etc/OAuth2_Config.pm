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

Set additional options when auto-creating new users. Default creates users as Privileged.

The default is to set C<Privileged =E<gt> 1>. Set C<Privileged =E<gt> 0> to create Unprivileged users.

    Set($OAuthNewUserOptions, {
            Privileged => 1,
        },
    );

Example with other user options to pass to RT

    Set($OAuthNewUserOptions,
        {   Privileged   => 1,
            Organization => 'ACME Inc.',
            Lang         => 'en-gb',
        },
   );


=back


=over 4

=item C<%OAuthNewUserGroups>

RT groups to always add new users to for each Identity Provider.

This is useful if the Identity Provider does not support groups.

     Set(%OAuthNewUserGroups,
        'authentik' => [ 'IT Support', 'Sales' ],
        'google' => [ 'Customer' ],
    );

=back

=cut

Set(%OAuthNewUserGroups, ());

=over 4

=item C<$OAuthIDP>

Set this to the label of the Identity Provider endpoint you want to use.
The list of IDPs is in the internal configuration option C<OAuthIDPs>.
Default is C<'google'>.

    Set($OAuthIDP, 'google');

B<NOTE>: This extension currently only supports a single OAuth2 provider. Even though
multiple providers can be configured, only one can be enabled.

Hopefully a future version of this extension will allow multiple OAuth2 providers.

=back

=cut

Set($OAuthIDP, 'google');


=over 4

=item C<%MetadataMap>

B<NOTE>: This is a sub-key of C<%OAuthIDPs>. Each IDP has a MetadataMap.

This defines a mapping from the fields returned in the user's metadata, to
fields needed by this extension in RT. The C<EmailAddress> field is required,
and is used (by default) to identify the user account in the RT database. It
must match with the email returned by the Identity Provider.

=back

=cut


=over 4

=item C<%OAuthIDPSecrets> Client ID and Secret

B<REQUIRED>

You must set the B<Client ID> and B<Client Secret> here. These are given
to you by your Identity Provider.  Each endpoint can have its own set of
secrets, so you must specify the endpoint name as found in the C<%OAuthIDPs>
internal config option.

For Google, they are found in the developer console where you configure the
OAuth login.

=back

=cut

Set( %OAuthIDPSecrets, () );

=over 4

=item C<%OAuthIDPOptions>

For convenience, any C<%OAuthIDPs> options can (optionally) be added to C<%OAuthIDPOptions> instead.

This avoids changing the plugin's default F<etc/OAuth_Config.pm> file, or copying entire C<%OAuthIDPs>
sections to your site config, only to change a couple of options.

Any C<%OAuthIDPOptions> options in your local RT_SiteConfig configuration (e.g. F<etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm>).
will replace any default C<%OAuthIDPs> options supplied in the extention's F<etc/OAuth_Config.pm> file,
which should normally not be changed.

Configure only those options you wish to add or change from the default C<%OAuthIDPs>.

C<%OAuthIDPOptions> also provides a C<default> section for settings which apply to all IDPs unless an option
has been explicitly configured for that IDP.

B<NOTE>: C<%OAuthIDPOptions> or C<%OAuthIDPs> cannot be used to set C<client_id> or C<client_secret> - these
must be configured in C<OAuthIDPSecrets>.

The following defaults are set by the extension's F<OAuth2_Config.pm>:

    Set(%OAuthIDPOptions,
        'default' => {
            'MetadataHandler'         => 'RT::Authen::OAuth2::Google',
            'GroupUserOptions'        => { 'NoGroup' => {}, },
            'GroupMap'                => { 'NoGroup' => [], },
            'GroupListName'           => 'groups',
            'AllowLoginWithoutGroups' => 1,
            'CreateNoGroupUser'       => 1,
            'LoginUpdateGroups'       => 0,
            'RemoveRTPassword'        => 0,
            'CreateUpdateFields'      => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
            'LoginUpdateFields'       => [ 'RealName', 'NickName', 'Organization', 'Lang' ],
            'Admins' = ['root'],
        },
    );

B<NOTE>: You can also replace the C<default> section by copying B<the whole> C<default' =E<gt> {...}, > section to your F<RT_SiteConfig>.
(The C<default> section is not merged but can be replaced.)

You can then add/change any C<%OAuthIDPs> options in your local RT_SiteConfig, e.g.
F<etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm>:

    # Options for authentik:

    Set($OAuthIDP, 'authentik');
    Set($AuthentikHost, "auth.example.com");
    Set($AuthentikSlug, "rt");

    Set(%OAuthIDPSecrets,
        'authentik' => {
            client_id => '.....',
            client_secret => '.....',
        },
    );

    # Our IDP settings for authentik:

    Set(%OAuthIDPOptions,
       'authentik' => {
           'GroupMap' => {
                    'NoGroup' => [ 'Staff' ],
                    'ACME Engineering' => [ 'Customer Support', 'Engineering' ],
                    'ACME Support' => [ 'Customer Support' ],
                    'ACME Sales' => [ 'Sales' ],
                    'ACME Finance' => [ 'Accounts' ],
                    'ACME Management' => [ 'Sales', 'Customer Support', 'Accounts' ],
                    'IT Administrators' => [ 'RT Admins' ],
           },
           'GroupUserOptions' => {
               'NoGroup' => { Privileged => 0,
                              Organization => '',
                            },
           },
           'LoginUpdateFields' => [ 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
           'RequireGroup' => 'GroupMap',
           'LoginUpdateGroups' => 1,
           'RemoveRTPassword' => 1,
        },
    );

(See below for a more detailed description of these options)

IDP config options are applied and inherited in the following order:

=over 8

=item 1
C<%OAuthIDPs> in RT database or plugin core config F<plugins/RT-Authen-OAuth2OAuth2_Config.pm>

=item 2
C<%OAuthIDPOptions> 'default' section in plugin core config (or if replaced in F<RT_SiteConfig>).

=item 3
C<%OAuthIDPOptions> IDP section in site config, e.g. F<etc/RT_SiteConfig.d/RT-Authen-OAuth2.pm>. Settings will replace any previous defaults.

=back

If you prefer, you can ignore this feature and simply copy C<%OAuthIDPs> to your F<RT_SiteConfig>
(as before), but you must set (and maintain) B<all> of the replaced config options even if they
are the same as the supplied defaults.

RT only merges "hash-style" configuration options for core and site config at the top level,
not recursively.

For example, if you set in your F<RT_SiteConfig>:

    Set(%OAuthIDPs,
       'authentik' => {
        ...
          <your config options>,
        ...
        },
    );

The C<%OAuthIDPs> options for C<authentik> will not be inherited from the plugin
core config, but other IDP sections are retained. (e.g. C<'google' = E<gt> { ... }> ).


=back

=cut

Set(%OAuthIDPOptions,
    'default' => {
        'MetadataHandler'         => 'RT::Authen::OAuth2::Google',
        'GroupUserOptions'        => { 'NoGroup' => {}, },
        'GroupMap'                => { 'NoGroup' => [], },
        'GroupListName'           => 'groups',
        'AllowLoginWithoutGroups' => 1,
        'CreateNoGroupUser'       => 1,
        'LoginUpdateGroups'       => 0,
        'RemoveRTPassword'        => 0,
        'Admins'                  => ['root'],
        'CreateUpdateFields'      => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
        'LoginUpdateFields'       => [ 'RealName', 'NickName', 'Organization', 'Lang' ],
    },
);

=head1 INTERNAL CONFIGURATION DEFAULTS

=over 4

=item C<$OAuthRedirect>

This parameter is used by the IdP provider to define where the results are
returned. Typically (always?) this must match what is configured in the IdP,
and the name and path of the template components that handle the request. You
should never need to change this.

This should be a full URI (see rfc6819 section 4.1.5). Note that you may not
be able to use RT->Config->Get('WebURL') at this point in the configuration
loading, so you may need to explicitly provide your WebURL.

    Set($OAuthRedirect, RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect');

=back

=cut

Set($OAuthRedirect, RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect');

=over 4

=item C<$OAuthDebugToken>

If an RT log level is set to debug, (e.g. C<$LogToSyslog>) this option enables or disables
debug logging of the OAuth access token received from the IDP.

To avoid cluttering the logs or logging potentially sensitive information, OAuth token
debug logging is disabled by default. (Usually only needed for debugging OAuth
authentication issues or testing new Identity Provider setups.)

This option can also be set for each IDP in C<%OAuthIDPs>.

=back

=cut

Set( $OAuthDebugToken, 0 );


=head1 SECURITY CONSIDERATIONS

=over 4

=item C<%OAuthIDPSecrets>

If your RT configuration files are backed up or stored in a repository, or you keep
multiple repositories for testing or development, take care that your secrets are
not accidentally committed to a repository where they are visible to others.

You may want to add C<Set(%OAuthIDPSecrets, ...> to a separate RT_SiteConfig.d file,
then add this file to your .gitignore, for example.


=item B<LoadColumn> option

B<NOTE>: This is a sub-key of C<%OAuthIDPs>. Each IDP has a C<LoadColumn> option.

C<LoadColumn> is set per IDP in C<%OAuthIDPs> (or C<%OAuthIDPOptions>) and specifies which
field from C<MetadataMap> to use as the RT username during user lookup or creation.

If not set, C<EmailAddress> might be used depending on the default IDP configuration
- B<but this may be insecure>.

It is important to note: username and email address are B<separate fields> and may
be editable in the IDP or in RT.

If the IDP and RT usernames happen to be the same as the user's email address and the IDP
supplies separate username and email address fields, B<DO NOT> set C<LoadColumn>
to C<EmailAddress>.

If the usernames in the IDP do not match your RT usernames, one option is to
rename the RT usernames to match the IDP. This is more secure, but may not
be practical in some situations.

Avoid setting C<EmailAddress> unless the IDP does not provide a suitable field for
the username which is unique and unchangeable.

It is safer to set C<LoadColumn> to C<Name> or another field users cannot change.
Otherwise there is nothing to prevent a user from changing the email address in their
IDP profile and logging in to RT as any other user (possibly even your RT root/admin user!)

B<If you must use email addresses, ensure users CANNOT change their email address in the IDP.>

For Authentik, set C<goauthentik.io/user/can-change-email: false> in a group attribute (or elsewhere)
to prevent users changing their email address.

Only set C<LoadColumn> to C<EmailAddress> if no other reliable username identifier exists,
and you are sure users cannot change their email address.

    'LoadColumn' => 'EmailAddress',

=back

=head1 UNIQUE EMAIL ADDRESS CONSTRAINT

RT requires email addresses to be unique across all users. Some IDPs allow multiple users to have
the same email address. If your usernames are not email addresses, attempting to add a second
user with the same email address as any existing RT user (enabled/privileged or otherwise) will fail.

=head1 GROUP AND USER CONFIGURATION OPTIONS

If the IDP supports groups, the following additional settings can be added to C<%OAuthIDPOptions> (or C<%OAuthIDPs>)
to control group behaviour and defaults for each IDP.

The following options are all subkeys of C<%OAuthIDPOptions> which are described below.

    Set(%OAuthIDPOptions,
       'authentik' => {
           'MetadataMap' => {
                ....
            },
           'GroupMap' => {
                ....
            },
           'GroupUserOptions' => {
                ....
           },
           'GroupListName' => 'groups',
           'RequireGroup' => 'GroupMap',
           'AllowLoginWithoutGroups' => 1,
           'CreateNoGroupUser' => 1,
           'LoginUpdateGroups' => 1,
           'LoginUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang' ],
           'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
           'LoadColumn' => 'Name',
           'RemoveRTPassword' => 0,
           'Admins' => [ 'root' ],
        },
    );

=over 4

=item C<GroupMap>

Mapping of IDP groups to one or more RT groups.

           'GroupMap' => {
               'NoGroup' => [ 'Staff' ],
               'ACME Engineering' => [ 'Customer Support', 'Engineering' ],
               'ACME Support' => [ 'Customer Support' ],
               'ACME Sales' => [ 'Sales' ],
               'ACME Finance' => [ 'Accounts' ],
               'ACME Management' => [ 'Sales', 'Customer Support', 'Accounts' ],
               'IT Administrators' => [ 'RT Admins' ],
            },

In the above example, a user in the I<IDP group> B<ACME Management> will be added to
the RT groups B<Sales>, B<Customer Support> and B<Accounts>.

B<NOTE>: RT groups B<MUST> already exist in RT or user creation / update will fail. Ensure the
spelling, any spaces and upper/lower case etc. is correct.

If a user is in multiple IDP groups, all unique mapped RT groups are added for all groups.

The special group B<NoGroup> is used to set some default RT groups if the IDP did not
return any groups for the user. Removing this option means no default groups are set.


=item C<GroupUserOptions>

Set per-group user options which override the same setting in C<OAuthNewUserOptions> if present.

        'GroupUserOptions' => {
            'NoGroup'  => { Privileged => 0, },
            'Customer' => {
                Privileged   => 0,
                Organization => '',
                Comments     => 'Customer user managed by OAuth2',
            },
            'ACME Staff' => {
                Privileged   => 1,
                Organization => 'ACME Inc.',
                Lang         => 'en-gb',
            },
        },

B<NOTE>: If a user is in IDP multiple groups, the last group matched is used. As Perl hashes do not preserve order,
this can have unpredictable results if the same option is repeated but different for multiple groups.

It is recommended for users to be in only a single group where C<GroupUserOptions> is set. Multiple groups
may still be used if the are no conflicting C<GroupUserOptions>.

If set in C<GroupMap>, the special group B<NoGroup> can be used to configure options for users
not in any IDP groups. In the above example, users who are not in any groups will be set as
Unprivileged users instead of the default Privileged.


=item C<GroupListName>

Configure the name of the groups list in the IDP payload. Default: C<groups>.

    'GroupListName' => 'groups',

Extracts the list named C<"groups": [...]> in the following payload:

    {
    ...
        "email": "....",
        "email_verified": true,
        "name": "....e",
        "given_name": "....",
        "preferred_username": "....",
        "nickname": "....",
        "groups": [
            "ACME Engineering",
            "ACME Staff",
            "authentik Admins",
            "Web Server Admins"
            "RT_Admins",
            "RT_Users",
        ]
    }

B<NOTE>: Groups is not part of the official userinfo OpenID schema, but is a quasi-standard. Only a single JSON group list "[ ]" is supported. Other nested lists or data structures are not (yet) supported.

=item C<RequireGroup>

Configure a list of required groups. A user must be a member of at least one C<RequireGroup>
to log in to RT.

By default, users in all groups (or none) are permitted.

    'RequireGroup' => ['GroupMap', '^RT_ ', 'Web Server Admins' ],

C<RequireGroup> can be a single option (as a string) or a list containing any or all of
the following:

=back

=over 8

=item *
C<GroupMap>

Permits users in any group listed in C<GroupMap>

=item *
I<Group Name>

Permits users in a specifc group (exact match)

=item *
C<^>I<Group Prefix>

Permits users in any group name starting with a given prefix. e.g.: C<^RT_> would match any group
beginning with C<"RT_">.

=back

=over 4

=item C<AllowLoginWithoutGroups>

If C<RequireGroups> is enabled, this option permits users with no groups (C<NoGroup>)
to login. If set to C<0>, users with no groups in the IDP will not be able to log in RT,
even if they have a matching RT user account and can log in with another method. Default: 1.

    'AllowLoginWithoutGroups' => '1',

=item C<CreateNoGroupUser>

If the global C<$OAuthCreateNewUser> option is enabled, this option enables or disables
creation of new RT user accounts for users with no groups in the IDP. Default: 1.

    'CreateNoGroupUser' => '1',

You may also need to set C<GroupUserOptions> for C<NoGroup>, for example if these
users should be created as Privileged. (Default is Unprivileged).

=item C<LoginUpdateGroups>

Enable this option to always update a user's RT groups at every login.

This means a user's RT groups will be controlled by their IDP group memberships
as configured by C<GroupMap>.

Upon login, users will be added to any RT groups mapped by C<GroupMap> they are
not a member of. Users will also be B<removed> from any RT groups not mapped in C<GroupMap>.

Default: 0 (Groups are only added for newly created RT users.)

=item C<LoginUpdateFields> / C<CreateUpdateFields>

Controls which fields are updated during login / for newly created RT users.

You may want to set all fields from the IDP when a new user is created,
but allow some fields to be subsequently changed in RT (and not be updated
again when the user logs in.)

Example:

Update all fields from the IDP for newly created RT users (default):

       'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],

Setting the following would allow users to change B<RealName> and B<NickName>:

       'LoginUpdateFields' => [ 'Organization', 'Lang', 'EmailAddress' ],


Defaults:

       'CreateUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang', 'EmailAddress' ],
       'LoginUpdateFields' => [ 'RealName', 'NickName', 'Organization', 'Lang' ],


B<NOTE>: B<EmailAddress> is not updated on login by default. RT requires unique email addresses.
This avoids a user being unable to login if we try to change B<EmailAddress> to an
address already in use by another user. If you are confident such conflicts are unlikely
to occur with your RT users, add C<EmailAddress> to your C<LoginUpdateFields> configuration.

B<Name> (the username itself) is also not updated for the same reason.


=item C<RemoveRTPassword>

Enable this option to remove the user's RT passsword after a successful OAuth2 login.

This means B<users will only be able to log in to RT using OAuth2 SSO>.

Passwords in RT will be deleted and cannot be used to login. (Non-admin users will also not
be able to set a new password.)

B<NOTE>: This action is irreversible: RT's password hashes are deleted and not retained.
It is therefore not possible to "reactivate" a previous password (unless you restore
it from a database backup.) To login again with RT username/password, an admin user
can set a new password for the user.

By default, the 'root' RT user's password is never updated.

See C<Admins> to configure special admin users.


=item C<Admins>

List of special / RT admin users.

No attribute or group changes will be applied for these users.

Default:

    'Admins' => [ 'root' ],


=over 8

=item *
No IDP group membership are enforced. (Configured in C<RequireGroup>).

=item *
No groups are updated on login if C<LoginUpdateGroups> is enabled.

=item *
No user attributes are updated on login.

=item *
No RT password update if C<RemoveRTPassword> is enabled.

=back


=back

=over 4

=item C<%OAuthIDPs> Internal Options

These are defaults for common endpoints. They should only be modified
by the RT admin with good cause; most will want to leave these as they are.

        'LoginPageButton' => '/static/images/your_login_button.png',
        'authorize_path' => '/o/oauth2/auth',
        'site' => 'https://your.auth.server',
        'name' => 'ACME SSO Server',
        'protected_resource_path' => '/application/o/userinfo',
        'scope' => 'openid profile email',
        'access_token_path' => '/o/oauth2/token',

See F<etc/OAuth_Config.pm> in this extension's directory tree for a full list.

Note, not all services listed here are tested and working. They may be added
as supported options in future releases, or by customer request.

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
        'state' => '',
    },
    'authentik' => {
        # You must Set($AuthentikHost, "auth.example.com");
        # You must Set($AuthentikSlug, "rt");
        'MetadataHandler' => 'RT::Authen::OAuth2::Google',
        'MetadataMap' => {
          Name => 'preferred_username',
          EmailAddress => 'email',
          RealName => 'name',
          NickName => 'nickname',
          Lang => 'not-provided',
          Organization => 'not-provided',
          VerifiedEmail => 'email_verified',
        },
        # LoadColumn - see SECURITY CONSIDERATIONS above.
        'LoadColumn' => 'Name',
        'name' => 'Authentik SSO',
        'site' => 'https://' . RT->Config->Get('AuthentikHost'),
        'LoginPageButton' => '/static/images/btn_authentik_signin.png',
        'protected_resource_path' => '/application/o/userinfo',
        'authorize_path' => '/application/o/authorize',
        'scope' => 'openid profile email',
        'access_token_path' => '/application/o/token/',
        'logout_path' => '/application/o/' . RT->Config->Get('AuthentikSlug') . '/end-session/',
        'state' => '',
    },
    'okta' => {
        # You must Set($OktaHost, "your-okta.okta.com");
        # See: https://developer.okta.com/docs/api/openapi/okta-oauth/guides/overview/#id-token
        'MetadataHandler' => 'RT::Authen::OAuth2::Google',
        'MetadataMap' => {
          Name => 'preferred_username',
          EmailAddress => 'email',
          RealName => 'name',
          NickName => 'nickname',
          VerifiedEmail => 'email_verified',
          Lang => 'locale',
          # Timezone => 'zoneinfo',
          # WorkPhone => 'phone_number',
        },
        # LoadColumn - see SECURITY CONSIDERATIONS above.
        'LoadColumn' => 'Name',
        'name' => 'okta SSO',
         #'LoginPageButton' => '/static/images/btn_btn_okta_signin.png',
        'access_token_path' => '/oauth2/v1/token',
        'site' => 'https://' . RT->Config->Get('OktaHost'),
        'scope' => 'openid profile email',
        'authorize_path' => '/oauth2/v1/authorize',
        'authorize_method' => 'GET',
        'protected_resource_path' => '/oauth2/v1/userinfo',
        'protected_resource_method' => 'GET',
        'state' => '',
    },
    'instagram' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'access_token_path' => '/oauth/access_token',
        'site' => 'https://api.instagram.com',
        'scope' => 'comments relationships likes',
        'authorize_path' => '/oauth/authorize',
        'state' => '',
    },
    '37signals' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'protected_resource_path' => '/authorization.xml',
        'authorize_path' => '/authorization/new',
        'name' => '37Signals',
        'access_token_path' => '/authorization/token',
        'site' => 'https://launchpad.37signals.com/',
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
        'state' => '',
    },
    'facebook' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'site' => 'https://graph.facebook.com',
        'name' => 'Facebook',
        'protected_resource_path' => '/me',
        'state' => '',
    },
    'mixi' => {
        'MetadataHandler' => 'RT::Authen::OAuth2::Unimplemented',
        'authorize_url' => 'https://mixi.jp/connect_authorize.pl',
        'name' => 'mixi',
        'access_token_url' => 'https://secure.mixi-platform.com/2/token',
        'site' => 'https://mixi.jp',
        'state' => '',
    },
);


Set(%OAuthIDPSecrets,
    'google' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'auth0' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'authentik' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'okta' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'instagram' => {
        'client_id' => '',
        'client_secret' => '',
     },
    '37signals' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'yandex' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'facebook' => {
        'client_id' => '',
        'client_secret' => '',
     },
    'mixi' => {
        'client_id' => '',
        'client_secret' => '',
     },
);
