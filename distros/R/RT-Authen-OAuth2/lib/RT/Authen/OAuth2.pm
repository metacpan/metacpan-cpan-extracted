use strict;
use warnings;
package RT::Authen::OAuth2;

our $VERSION = '0.14';

use Net::OAuth2::Profile::WebServer;

use RT::Authen::OAuth2::Unimplemented;
use RT::Authen::OAuth2::Google;
use Data::Dumper;

use URI::Escape;

RT->AddStyleSheets('rt-authen-oauth2.css');

=head1 NAME

RT-Authen-OAuth2 - External authentication for OAuth 2 sources, like Google, X, Authentik, okta, GitHub, etc.

=head1 DESCRIPTION

External authentication for OAuth2 sources.

=head1 RT VERSION

Works with RT 4.4, 5, and 6.0

=head1 DEPENDENCIES

Requires B<Net::OAuth2::Profile::WebServer>

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Authen::OAuth2');

Add (at least) configuration options:

    Set($OAuthIDP, 'your_idp_name');

    Set(%OAuthIDPSecrets,
        'your_idp_name' => {
            client_id => '.....',
            client_secret => '.....',
        },
    );

    Set(%OAuthIDPOptions,
        ...
    );

    - Plus any additional options needed for specific IDPs.

    - See OAuth2_Config.pm / perldoc OAuth2_Config.pm for examples and additional options.

    OAuth2_Config.pm includes working examples for google, auth0, okta and authentik.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Authen-OAuth2@rt.cpan.org|mailto:bug-RT-Authen-OAuth2@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Authen-OAuth2>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016-2025 by Best Practical Solutions LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

=head1 METHODS

=head2 C<RequestAuthorization()>

=over 4

Creates an Authorization Request on behalf of the Resource Owner (user), and
initiates the OAuth 2 protocol with the Authorization Server. The browser
will redirect to the C<$OAuthRedirect> endpoint specified in the config.

=back

=cut

sub RequestAuthorization {
    my ($session, $args) = @_;
    return if $session->{CurrentUser} and $session->{CurrentUser}->id;

    my $idp = RT->Config->Get('OAuthIDP');
    # my $idp_conf = RT->Config->Get('OAuthIDPs')->{$idp};
    my $idp_conf = _GetIDPConf($idp);

    $idp_conf->{state} = $args->{next} || '';
    $idp_conf->{client_id} = RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_id};
    $idp_conf->{client_secret} = RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_secret};

    die("OAuth2 client_id and client_secret must both be configured")
        unless $idp_conf->{client_id} and $idp_conf->{client_secret};

    my $auth = Net::OAuth2::Profile::WebServer->new(
        %$idp_conf,
        redirect_uri => RT->Config->Get('OAuthRedirect') || ( RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect' ),
    );

    my $ip = RT::Interface::Web::RequestENV('REMOTE_ADDR') || 'UNKNOWN';
    RT::Logger->info("OAuth2: redirect from RequestAuthorization() from $ip");
    RT::Interface::Web::Redirect($auth->authorize);
}


=head2 C<LogUserIn()>

=over 4

Called from the C<$OAuthRedirect> endpoint handler element. Validates the user
exists and is allowed to log in, auto-populates user metadata returned from
the OAuth 2 server, and sets up a session. If successful, returns to the
handler template element to redirect to the final destination.

=back

=cut

sub LogUserIn {
    my ($session, $args) = @_;

    # generic_error is displayed to the user to avoid leaking information
    # about the existance and status of user accounts in RT
    my $generic_error = RT->SystemUser->loc("Cannot login. Please contact your administrator.");
    my $ip = RT::Interface::Web::RequestENV('REMOTE_ADDR') || 'UNKNOWN';

    RT::Logger->info("OAuth2: User already logged in, aborting; new request from $ip") if $session->{CurrentUser} and $session->{CurrentUser}->Id;
    return (0, $generic_error) if $session->{CurrentUser} and $session->{CurrentUser}->Id;

    # Retrieve the Authorization Server configs
    my $idp = RT->Config->Get('OAuthIDP');
    # my $idp_conf = RT->Config->Get('OAuthIDPs')->{$idp};
    my $idp_conf = _GetIDPConf($idp);

    # Set up the Net::OAuth2 object to handle the requests
    my $auth = Net::OAuth2::Profile::WebServer->new(
        %$idp_conf,
        client_id => RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_id},
        client_secret => RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_secret},
        redirect_uri => RT->Config->Get('OAuthRedirect') || ( RT->Config->Get('WebURL') . 'NoAuth/OAuthRedirect' ),
    );

    # Call the Authorization Server and get an access token
    my $access_token = $auth->get_access_token($args->{code});

    # Do we clutter the log with the token data?
    my $debug_token =
        defined $idp_conf->{'OAuthDebugToken'}       ? $idp_conf->{'OAuthDebugToken'}
      : defined RT->Config->Get('OAuthDebugToken')   ? RT->Config->Get('OAuthDebugToken')
      : 0;

    if ($debug_token) { RT->Logger->debug( 'OAuth2: access_token: ' . Dumper($access_token) ); }

    # Retrieve the user's profile metadata from the protected resource
    my $response = $access_token->get($idp_conf->{protected_resource_url} || $idp_conf->{protected_resource_path});

    # Get the correct handler for the user's metadata, based on which IDP is in use
    my $idp_handler = $idp_conf->{MetadataHandler};
    my $metadata = $idp_handler->Metadata($response->decoded_content);
    RT->Logger->debug( 'OAuth2: metadata: ' . Dumper($metadata) );
    if ( $metadata->{result} && ref $metadata->{result} eq 'HASH' ) {
        $metadata->{$_} ||= $metadata->{result}{$_} for keys %{ $metadata->{result} };
    }

    my $loadcol = $idp_conf->{LoadColumn} || 'EmailAddress';
    my $name = $metadata->{ $idp_conf->{MetadataMap}->{$loadcol} };

    # email (or LoadColumn) is used to identify the user; bail out if we don't have one
    RT::Logger->error("OAuth2: Server return content didn't include $loadcol, aborting. Request from $ip") unless $name;
    return (0, $generic_error) unless $name;

    # Admin users from excluded from updates/checks:
    my $is_admin = grep { $_ eq $name } @{ $idp_conf->{Admins} || [] };

    if ( $idp_conf->{MetadataMap}->{VerifiedEmail} && !$metadata->{ $idp_conf->{MetadataMap}->{VerifiedEmail} } ) {
      RT::Logger->info( "OAuth2: Email for user $name not verified." );
      return ( 0, RT->SystemUser->loc( "Email [_1] not verified.", $name ) );
    }

    my $group_list    = $idp_conf->{'GroupListName'} || 'groups';    # Name of the list in the IDP response
    my $group_map     = $idp_conf->{'GroupMap'}          // {};
    my $update_groups = $idp_conf->{'LoginUpdateGroups'} // 0;       # Update RT groups on login?
    my $default_map   = $group_map->{'NoGroup'};

    # Load groups from the IDP list of groups if provided
    my @groups = @{ $metadata->{$group_list} // [] };

    # If RequireGroup is set, check if user is in an allowed group
    if ( !$is_admin && $idp_conf->{RequireGroup} ) {
        unless (@groups) {
            unless ( $idp_conf->{AllowLoginWithoutGroups} ) {
                RT::Logger->info("OAuth2: Login not allowed: user $name has no groups in OAuth2 response");
                return ( 0, RT->SystemUser->loc( "Login not allowed: user [_1] is not in any group.", $name ) );
            }
        }
        else {
            my $allowed = _CheckRequiredGroup( $idp_conf, @groups );
            unless ($allowed) {
                RT::Logger->info("OAuth2: Login not allowed: user $name is not in a required group");
                return ( 0, RT->SystemUser->loc( "Login not allowed: user [_1] is not in a required group.", $name ) );
            }
        }
    }

    # Try to find user in RT:
    my $user = RT::User->new( RT->SystemUser );
    $user->LoadByCol($loadcol, $name);
    my $newuser;

    # If the IDP returned a group list, match groups with GroupMap to RT groups
    my @rt_idp_groups;

    if ( $metadata->{$group_list} ) {

        my %seen;

        for my $group (@groups) {
            next if $group eq 'NoGroup';    # Hopefully there isn't an IDP group 'NoGroup'
            if ( my $mapped = $group_map->{$group} ) {
                for my $rt_group (@$mapped) {
                    push @rt_idp_groups, $rt_group unless $seen{$rt_group}++;
                }
            }
        }

        # If no matches, add NoGroup (if defined)
        if ( !@rt_idp_groups && defined $default_map && $user->id ) {
            for my $rt_group (@$default_map) {
                push @rt_idp_groups, $rt_group unless $seen{$rt_group}++;
            }
        }
    }

    # Get any default or group-specific options for user
    my $newuseropts = RT->Config->Get('OAuthNewUserOptions') || { Privileged => 1 };
    my %useropts    = %$newuseropts;

    my $has_mapped_groups = scalar @rt_idp_groups;

    # TODO future feature: add an option to auto-vivify only if email matches regex
    # TODO e.g., allow all people from mycompany.com to access RT automatically

    RT::Logger->info("OAuth2 user $name attempted login but no matching user found in RT. Request from $ip") unless $user->id;


    #### USER CREATE:

    if (RT->Config->Get('OAuthCreateNewUser') and not $user->id) {

        my $create_no_group_user = $idp_conf->{CreateNoGroupUser} // 0;

        # Add default NoGroup groups for new user if enabled
        if ( !@rt_idp_groups && $create_no_group_user && defined $default_map ) {
            my %seen;
            for my $rt_group (@$default_map) {
                push @rt_idp_groups, $rt_group unless $seen{$rt_group}++;
            }
            push @groups, 'NoGroup';
        }

        $has_mapped_groups = scalar @rt_idp_groups;

        # If IDP doesn't support groups, we can add some statically using OAuthNewUserGroups.
        my @rt_static_groups  = @{ ( RT->Config->Get('OAuthNewUserGroups') // {} )->{$idp} // [] };
        my $has_static_groups = scalar @rt_static_groups;

        RT::Logger->debug(
            "OAuth2: Debug: has_static_groups =  $has_static_groups, has_mapped_groups =  $has_mapped_groups, create_no_group_user = $create_no_group_user"
        );

        # Do not create user if no static or mapped groups and CreateNoGroupUser is disabled
        unless ( $has_mapped_groups || $has_static_groups || ( $create_no_group_user && defined $default_map ) ) {
            RT::Logger->error(
                "OAuth2: User not created: user $name - no group mapping or CreateNoGroupUser is disabled.");
            return ( 0, $generic_error );
        }

        my %seen;
        my @add_to_groups = grep { !$seen{$_}++ } ( @rt_static_groups, @rt_idp_groups );

        # Check all initial groups exist before adding the user account
        foreach my $add_group (@add_to_groups) {
            my $group = RT::Group->new($RT::SystemUser);
            $group->LoadUserDefinedGroup($add_group);
            unless ( $group->Id ) {
                $RT::Logger->error("OAuth2: Error adding account for $name - Group $add_group does not exist");
                return ( 0, $generic_error );
            }
        }

        # Update defaults/overrides per-group from GroupUserOptions if set.
        if ( $idp_conf->{GroupUserOptions} ) {
            for my $group (@groups) {
                if ( my $override = $idp_conf->{'GroupUserOptions'}{$group} ) {
                    %useropts = ( %useropts, %$override );    # override defaults with per-group
                }
            }
        }

        my @fields
            = ( ref( $idp_conf->{CreateUpdateFields} ) eq 'ARRAY' )
            ? @{ $idp_conf->{CreateUpdateFields} }
            : qw(RealName NickName Organization Lang EmailAddress);

        $newuser = RT::User->new($RT::SystemUser);

        $useropts{Comments} = 'Auto-created via OAuth2 authenticator ' . $idp unless ( $useropts{Comments} );

        RT::Logger->info("OAuth2: Attempting to create account for $name");
        my ( $id, $msg ) = $newuser->Create(
            %useropts,
            Name => $name,
            map { $_ => $metadata->{ $idp_conf->{MetadataMap}->{$_} } }
                grep { $metadata->{ $idp_conf->{MetadataMap}->{$_} } }
                @fields,
        );
        unless ($id) {
            RT::Logger->error("OAuth2: Error $msg creating account for $name");
            return ( 0, $generic_error );
        }

        # Add the new user to any initial group(s)
        foreach my $add_group (@add_to_groups) {
            my $status = _AddUserToGroup( $newuser, $add_group );
            unless ($status) {
                RT::Logger->error("OAuth2: Error adding user to group $add_group");
            }
        }

        $user = $newuser;

    }

    return(0, $generic_error) unless $user->id;


    RT::Logger->info("OAuth2: User $name configurfed in Admins; user group/attributes changes NOT updated.") if ($is_admin);

    #
    # USER LOGIN / UPDATE:
    #

    unless ( $newuser || $is_admin ) {

        if ( !@groups && defined $default_map ) {
            push @groups, 'NoGroup';
        }

        # Update defaults/overrides per-group from GroupUserOptions if set.
        if ( $idp_conf->{GroupUserOptions} ) {
            for my $group (@groups) {
                if ( my $override = $idp_conf->{GroupUserOptions}{$group} ) {
                    %useropts = ( %useropts, %$override );    # override defaults with per-group
                }
            }
        }

        # Populate fields in the RT user profile from the OAuth server metadata
        # May be able to expand the number of fields mapped here, if other servers return
        # appropriate data

        my @fields
            = ( ref( $idp_conf->{LoginUpdateFields} ) eq 'ARRAY' )
            ? @{ $idp_conf->{LoginUpdateFields} }
            : qw(RealName NickName Organization Lang);

        # Merge useropts and @fields, avoiding duplicates
        my %already        = map  { $_ => 1 } @fields;
        my @useropt_fields = grep { !$already{$_} } keys %useropts;
        my @all_attrs      = ( @fields, @useropt_fields );

        my %update_args = map {
            $_ => (
                exists $useropts{$_} ? $useropts{$_}
                : defined $metadata->{ $idp_conf->{MetadataMap}->{$_} }
                ? $metadata->{ $idp_conf->{MetadataMap}->{$_} }
                : $user->can($_) ? $user->$_()
                :                  ''
            )
        } @all_attrs;

        $user->Update(
            AttributesRef => [@all_attrs],
            ARGSRef       => \%update_args,
        );

    }

    # If LoginUpdateGroups is enabled and we haven't just created the user, update groups
    if ( !$newuser && !$is_admin && $update_groups && $has_mapped_groups ) {
        my @owngroups     = _GetOwnGroups($user);
        my $group_changes = _UpdateGroupsForUser( $user, \@owngroups, \@rt_idp_groups );
    }


    RT::Logger->info("OAuth2: User $name is disabled in RT; aborting OAuth2 login. Request from $ip") if $user->Disabled;
    return(0, $generic_error) if $user->Disabled;

    # Set up our session and return to the handler template element for the redirect
    RT::Logger->info( "OAuth2: Successful OAuth2 login for $name from $ip (provider $idp) ");
    RT::Interface::Web::InstantiateNewSession();
    $session->{CurrentUser} = RT::CurrentUser->new($user);

    # Write changes back to persistent session (RT >= 6.0.0):
    if ( $RT::MAJOR_VERSION >= 6 ) {
        RT::Logger->debug("OAuth2: RT version $RT::VERSION - using new session method");
        RT::Interface::Web::Session::Set(
            Key   => 'CurrentUser',
            Value => $session->{CurrentUser},
        );
    }

    # After successful SSO login, remove RT password if RemoveRTPassword enabled.
    # This disables password login for the user. Users configured as "Admins" are excluded.
    if ( ($idp_conf->{RemoveRTPassword} && $user->HasPassword && !$is_admin) ) {
        my ($ret, $msg) = _RemovePassword($user);
        if ( $ret ) {
            RT::Logger->info( "OAuth2: $msg" );
        }
        else {
            RT::Logger->error( "OAuth2: $msg" );
        }
    }

    return (1, "ok", $args->{state});
}


=head2 C<IDPLoginButtonImage()>

=over 4

Returns the appropriate login button image for the active OAuth 2 server. This
is displayed on the RT login page.

=back

=cut

sub IDPLoginButtonImage {
    my $self = shift;
    my $idp = RT->Config->Get('OAuthIDP');

    my $login_button
        = defined RT->Config->Get('OAuthIDPOptions')->{$idp}->{LoginPageButton}
        ? RT->Config->Get('OAuthIDPOptions')->{$idp}->{LoginPageButton}
        : defined RT->Config->Get('OAuthIDPs')->{$idp}->{LoginPageButton}
        ? RT->Config->Get('OAuthIDPs')->{$idp}->{LoginPageButton}
        : $idp;

    return RT->Config->Get('OAuthIDPs')->{$idp}->{LoginPageButton};
}


=head2 C<IDPName()>

=over 4

Returns the name configured for the active OAuth 2 provider.

=back

=cut


sub IDPName {
    my $self = shift;
    my $idp = RT->Config->Get('OAuthIDP');

    my $idp_name
        = defined RT->Config->Get('OAuthIDPOptions')->{$idp}->{name}
        ? RT->Config->Get('OAuthIDPOptions')->{$idp}->{name}
        : defined RT->Config->Get('OAuthIDPs')->{$idp}->{name} ? RT->Config->Get('OAuthIDPs')->{$idp}->{name}
        :                                                        $idp;

    return $idp_name;
}


=head2 C<LogOutURL()>

=over 4

Returns the appropriate logout URL active OAuth 2 server.

=back

=cut

sub LogoutURL {
    my $next = shift;
    my $idp = RT->Config->Get('OAuthIDP');

    my $logout_path
        = defined RT->Config->Get('OAuthIDPOptions')->{$idp}->{logout_path}
        ? RT->Config->Get('OAuthIDPOptions')->{$idp}->{logout_path}
        : defined RT->Config->Get('OAuthIDPs')->{$idp}->{logout_path}
        ? RT->Config->Get('OAuthIDPs')->{$idp}->{logout_path}
        : undef;

    unless ( defined $logout_path ) {
        return $next;
    }

    my $site = RT->Config->Get('OAuthIDPOptions')->{$idp}->{site} || RT->Config->Get('OAuthIDPs')->{$idp}->{site};

    my $url = $site . $logout_path;
    $next = uri_escape($next);
    $url =~ s/__NEXT__/$next/;
    return $url;
}

#
# Return array of all RT groups user is a direct member of
#
sub _GetOwnGroups {

    my ($user) = @_;

    my @group_names;

    my $groups = RT::Groups->new($RT::SystemUser);

    $groups->LimitToUserDefinedGroups;
    $groups->WithMember( PrincipalId => $user->PrincipalObj->Id, Recursively => 0 );

    push @group_names, map { $_->Name } @{ $groups->ItemsArrayRef };

    return @group_names;
}

#
# Add user to RT group. (Adapted from RT::LDAPImport)
#
sub _AddUserToGroup {

    my ( $user, $group_name ) = @_;

    return unless $user;
    return unless $group_name;

    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadUserDefinedGroup($group_name);

    unless ( $group->Id ) {
        $RT::Logger->error( "OAuth2: Couldn't add " . $user->Name . " to " . $group_name . " - group does not exist" );
        return;
    }

    if ( $group->HasMember( $user->id ) ) {
        $RT::Logger->debug( "OAuth2: " . $user->Name . " already a member of " . $group->Name );
        return 1;
    }

    my ( $status, $msg ) = $group->AddMember( $user->id );

    if ($status) {
        $RT::Logger->info( "OAuth2: Added " . $user->Name . " to " . $group->Name . " [$msg]" );
    }
    else {
        $RT::Logger->error( "OAuth2: Couldn't add " . $user->Name . " to " . $group->Name . " [$msg]" );
    }
    return $status;

}

#
# Delete user from RT group
#
sub _DeleteUserFromGroup {

    my ( $user, $group_name ) = @_;

    return unless $user;
    return unless $group_name;

    my $group = RT::Group->new($RT::SystemUser);
    $group->LoadUserDefinedGroup($group_name);

    unless ( $group->Id ) {
        $RT::Logger->error(
            "OAuth2: Couldn't delete  " . $user->Name . " from  " . $group_name . " - group does not exist" );
        return;
    }

    unless ( $group->HasMember( $user->id ) ) {
        $RT::Logger->debug( "OAuth2: " . $user->Name . " not in group " . $group->Name );
        return 1;
    }

    my ( $status, $msg ) = $group->DeleteMember( $user->id );

    if ($status) {
        $RT::Logger->info( "OAuth2: Deleted " . $user->Name . " from " . $group->Name . " [$msg]" );
    }
    else {
        $RT::Logger->error( "OAuth2: Couldn't delete " . $user->Name . " from " . $group->Name . " [$msg]" );
    }
    return $status;

}

#
# Update groups for user
#
sub _UpdateGroupsForUser {

    my ( $user, $owngroups_aref, $rt_idp_groups_aref ) = @_;

    my %own = map { $_ => 1 } @$owngroups_aref;
    my %idp = map { $_ => 1 } @$rt_idp_groups_aref;

    my $changed;

    # Remove user from groups not in mapped list
    for my $group ( keys %own ) {
        unless ( $idp{$group} ) {
            _DeleteUserFromGroup( $user, $group );
            $changed++;
        }
    }

    # Add user to groups they are missing from
    for my $group ( keys %idp ) {
        unless ( $own{$group} ) {
            _AddUserToGroup( $user, $group );
            $changed++;
        }
    }

    return $changed;
}

#
# Remove RT user password (Disables RT password login)
#
sub _RemovePassword {
    my $user = shift;
    my $name = $user->Name;

    my ( $val, $msg ) = $user->_Set( Field => 'Password', Value => '*NO-PASSWORD*' );

    if ($val) {
        return ( 1, RT->SystemUser->loc( "Password removed for user [_1]", $name ) );
    }
    else {
        return ( 0, RT->SystemUser->loc( "Password NOT removed for user [_1]", $name ) );
    }
}


#
# Check user groups from IDP matches one of the required groups
#
# Valid options for RequireGroup:
#
# 1. 'GroupMap':  - Allowed if they are in a group configured in GroupMap
# 2. 'Group Name' - Allow if exact group name matches
# 3. '^Name '     - Allow if name starts Name, e.g. "^RT_" matches any group starting "RT_"
#
# RequireGroup can be a single string or a list containing a combination of options.
#
sub _CheckRequiredGroup {
    my ( $idp_conf, @groups ) = @_;

    my $require_group = $idp_conf->{'RequireGroup'};

    unless ($require_group) {
        $RT::Logger->debug("OAuth2: did nothing - RequireGroup not set");
        return 1;
    }

    # Accept single scalar or array
    my @patterns = ref $require_group eq 'ARRAY' ? @$require_group : ($require_group);

    # Check if GroupMap mode is enabled
    my $group_map_enabled = grep { $_ eq 'GroupMap' } @patterns;
    my $group_map         = $idp_conf->{GroupMap} || {};
    my %map_keys          = map { $_ => 1 } grep { $_ ne 'NoGroup' } keys %$group_map;

    # Remove 'GroupMap' from patterns for pattern/prefix step
    @patterns = grep { $_ ne 'GroupMap' } @patterns;

    my @exact  = grep { $_ !~ /^\^/ } @patterns;
    my @prefix = map  { substr( $_, 1 ) } grep {/^\^/} @patterns;

    for my $group (@groups) {

        # 1. GroupMap match
        if ( $group_map_enabled && exists $map_keys{$group} ) {
            $RT::Logger->debug("OAuth2: '$group' matched GroupMap");
            return 1;
        }

        # 2. Exact match
        if ( grep { $_ eq $group } @exact ) {
            $RT::Logger->debug("OAuth2: '$group' matched exactly");
            return 1;
        }

        # 3. ^ Prefix match
        if ( grep { index( $group, $_ ) == 0 } @prefix ) {
            $RT::Logger->debug("OAuth2: '$group' matched prefix");
            return 1;
        }
    }
    $RT::Logger->info("OAuth2: No group matched in RequireGroup (including GroupMap if enabled)");
    return 0;
}

#
# Get config from OAuthIDPs, but allow override in OAuthIDPOptions if set.
#
sub _GetIDPConf {

    my ($idp) = @_;

    my %idp_conf          = %{ RT->Config->Get('OAuthIDPs')->{$idp}            || {} };
    my %idp_conf_defaults = %{ RT->Config->Get('OAuthIDPOptions')->{'default'} || {} };
    my %idp_conf_options  = %{ RT->Config->Get('OAuthIDPOptions')->{$idp}      || {} };

    my %merged_conf = ( %idp_conf, %idp_conf_defaults, %idp_conf_options );

    RT::Logger->debug( "OAuth2: Using config" . Dumper( \%merged_conf ) );

    return \%merged_conf;

}


1;
