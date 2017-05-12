package RT::Authen::ExternalAuth;

our $VERSION = '0.26';

=head1 NAME

RT::Authen::ExternalAuth - RT Authentication using External Sources

=head1 DESCRIPTION

This module provides the ability to authenticate RT users against one or
more external data sources at once. It will also allow information about
that user to be loaded from the same, or any other available, source as
well as allowing multple redundant servers for each method.

The extension currently supports authentication and information from
LDAP via the Net::LDAP module, and from any data source that an
installed DBI driver is available for.

It is also possible to use cookies set by an alternate application for
Single Sign-On (SSO) with that application.  For example, you may
integrate RT with your own website login system so that once users log
in to your website, they will be automagically logged in to RT when they
access it.

=head1 INSTALLATION

Note that the features provided by this module have been made into core
features in RT 4.4 and greater.

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using the RT 4.2 series, add this line:

    Plugin('RT::Authen::ExternalAuth');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Authen::ExternalAuth) );

or add C<RT::Authen::ExternalAuth> to your existing C<@Plugins> line.

See L</CONFIGURATION> for additional configuration to add to your
F<RT_SiteConfig.pm> file.

=back

=head1 UPGRADING

If you are upgrading from an earlier version of this extension, you must
remove the following files manually:

    /opt/rt4/local/plugins/RT-Authen-ExternalAuth/lib/RT/User_Vendor.pm
    /opt/rt4/local/lib/RT/User_Vendor.pm
    /opt/rt4/local/lib/RT/Authen/External_Auth.pm

Otherwise you will most likely encounter an error about modifying a read
only value and be unable to start RT.

You may not have all of these files.  It depends what versions you are
upgrading between.

If you are using a vendor packaged RT, your local directories are likely
to be somewhere under /usr/local instead of in /opt/rt4 so you will need
to visit Configuration -> Tools -> System Configuration to find your
plugin root.

=head1 CONFIGURATION

L<RT::Authen::ExternalAuth> provides a lot of flexibility with many
configuration options.  The following desc these configuration options,
and provides a complete example.

=over 4

=item C<$ExternalAuthPriority>

The order in which the services defined in L</$ExternalSettings> should
be used to authenticate users.  Once the user has been authenticated by
one service, the rest are skipped.

You should remove services you don't use. For example, if you're only
using C<My_LDAP>, remove C<My_MySQL> and C<My_SSO_Cookie>.

    Set($ExternalAuthPriority,  [ 'My_LDAP',
                                  'My_MySQL',
                                  'My_SSO_Cookie'
                                ]
    );

=item C<$ExternalInfoPriority>

When multiple auth services are available, this value defines the order
in which the services defined in L</$ExternalSettings> should be used to
get information about users. This includes C<RealName>, telephone
numbers etc, but also whether or not the user should be considered
disabled.

Once a user record is found, no more services are checked.

You CANNOT use a SSO cookie to retrieve information.

You should remove services you don't use, but you must define
at least one service.

    Set($ExternalInfoPriority,  [ 'My_LDAP',
                                  'My_MySQL',
                                ]
    );

=item C<$AutoCreateNonExternalUsers>

If this is set to 1, then users should be autocreated by RT
as internal users if they fail to authenticate from an
external service. This is useful if you have users outside
your organization who might interface with RT, perhaps by sending
email to a support email address.

=item C<$ExternalSettings>

These are the full settings for each external service as a hash of
hashes.  Note that you may have as many external services as you wish.
They will be checked in the order specified in L</$ExternalAuthPriority>
and L</$ExternalInfoPriority> directives above.

The outer structure is a key with the authentication option (name of
external source). The value is a hash reference with configuration keys
and values, for example:

    Set($ExternalSettings, {
        My_LDAP => {
            type => 'ldap',
            ... other options ...
        },
        My_MySQL => {
            type => 'db',
            ... other options ...
        },
        ... other sources ...
    } );

As shown above, each description should have 'type' defined.
The following types are supported:

=over 4

=item ldap

Authenticate against and sync information with LDAP servers.  See
L<RT::Authen::ExternalAuth::LDAP> for details.

=item db

Authenticate against and sync information with external RDBMS, supported
by Perl's L<DBI> interface. See L<RT::Authen::ExternalAuth::DBI> for
details.

=item cookie

Authenticate by cookie. See L<RT::Authen::ExternalAuth::DBI::Cookie> for
details.

=back

See the modules noted above for configuration options specific to each
type.  The following apply to all types.

=over 4

=item attr_match_list

The list of RT attributes that uniquely identify a user. These values
are used, in order, to find users in the selected authentication
source. Each value specified here must have a mapping in the
L</attr_map> section below. You can remove values you don't expect to
match, but we recommend using C<Name> and C<EmailAddress> at a
minimum. For example:

    'attr_match_list' => [
        'Name',
        'EmailAddress',
    ],

You should not use items that can map to multiple users (such as a
C<RealName> or building name).

=item attr_map

Mapping of RT attributes on to attributes in the external source.
Valid keys are attributes of an
L<RT::User|http://bestpractical.com/rt/docs/latest/RT/User.html>.
The values are attributes from your authentication source.
For example, an LDAP mapping might look like:

    'attr_map' => {
        'Name'         => 'sAMAccountName',
        'EmailAddress' => 'mail',
        'Organization' => 'physicalDeliveryOfficeName',
        'RealName'     => 'cn',
        ...
    },

=back

=back

=head2 Example

    # Use the below LDAP source for both authentication, as well as user
    # information
    Set( $ExternalAuthPriority, ["My_LDAP"] );
    Set( $ExternalInfoPriority, ["My_LDAP"] );

    # Users created from LDAP should be Privileged; this is a core RT
    # option.  Additionally, this is the 4.2 name for the option; for RT
    # 4.0, is it named $AutoCreate   See the core RT documentation at
    # http://docs.bestpractical.com/RT_Config#UserAutocreateDefaultsOnLogin
    # for for further details.
    Set( $UserAutocreateDefaultsOnLogin, { Privileged => 1 } );

    # Users should still be autocreated by RT as internal users if they
    # fail to exist in an external service; this is so requestors (who
    # are not in LDAP) can still be created when they email in.
    Set($AutoCreateNonExternalUsers, 1);

    # Minimal LDAP configuration; see RT::Authen::ExternalAuth::LDAP for
    # further details and examples
    Set($ExternalSettings, {
        'My_LDAP'       =>  {
            'type'             =>  'ldap',
            'server'           =>  'ldap.example.com',
            # By not passing 'user' and 'pass' we are using an anonymous
            # bind, which some servers to not allow
            'base'             =>  'ou=Staff,dc=example,dc=com',
            'filter'           =>  '(objectClass=inetOrgPerson)',
            # Users are allowed to log in via email address or account
            # name
            'attr_match_list'  => [
                'Name',
                'EmailAddress',
            ],
            # Import the following properties of the user from LDAP upon
            # login
            'attr_map' => {
                'Name'         => 'sAMAccountName',
                'EmailAddress' => 'mail',
                'RealName'     => 'cn',
                'WorkPhone'    => 'telephoneNumber',
                'Address1'     => 'streetAddress',
                'City'         => 'l',
                'State'        => 'st',
                'Zip'          => 'postalCode',
                'Country'      => 'co',
            },
        },
    } );

=head1 AUTHORS

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Originally by Mike Peachey (Jennic Ltd.) <zordrak@cpan.org>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Authen-ExternalAuth@rt.cpan.org|mailto:bug-RT-Authen-ExternalAuth@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Authen-ExternalAuth>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2014 by Best Practical Solutions, LLC
Copyright (c) 2008 by Jennic Ltd.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

use RT::Authen::ExternalAuth::LDAP;
use RT::Authen::ExternalAuth::DBI;

use strict;

$RT::Config::META{ExternalSettings} = {
    Obfuscate => sub {
        # Ensure passwords are obfuscated on the System Configuration page
        my ($config, $sources, $user) = @_;

        # $user is only passed in versions of RT with 3c7db050
        my $msg = 'Password not printed';
           $msg = $user->loc($msg) if $user and $user->Id;

        for my $source (values %$sources) {
            $source->{pass} = $msg;
        }
        return $sources;
    },
    PostLoadCheck => sub {
        my $self = shift;
        my $settings = shift || {};

        my $remove = sub {
            my ($service) = @_;
            delete $settings->{$service};

            $self->Set( 'ExternalAuthPriority',
                        [ grep { $_ ne $service } @{ $self->Get('ExternalAuthPriority') || [] } ] );

            $self->Set( 'ExternalInfoPriority',
                        [ grep { $_ ne $service } @{ $self->Get('ExternalInfoPriority') || [] } ] );
        };

        for my $service (keys %$settings) {
            my %conf = %{ $settings->{$service} };

            if ($conf{type} !~ /^(ldap|db|cookie)$/) {
                $RT::Logger->error(
                    "Service '$service' in ExternalInfoPriority is not ldap, db, or cookie; removing."
                );
                $remove->($service);
                next;
            }

            next unless $conf{type} eq 'db';

            # Ensure people don't misconfigure DBI auth to point to RT's
            # Users table; only check server/hostname/table, as
            # user/pass might be different (root, for instance)
            no warnings 'uninitialized';
            next unless lc $conf{server} eq lc RT->Config->Get('DatabaseHost') and
                        lc $conf{database} eq lc RT->Config->Get('DatabaseName') and
                        lc $conf{table} eq 'users';

            $RT::Logger->error(
                "RT::Authen::ExternalAuth should _not_ be configured with a database auth service ".
                "that points back to RT's internal Users table.  Removing the service '$service'! ".
                "Please remove it from your config file."
            );

            $remove->($service);
        }
        $self->Set( 'ExternalSettings', $settings );
    },
};

$RT::Config::META{ExternalAuthPriority} = {
    PostLoadCheck => sub {
        my $self = shift;
        my @values = @{ shift || [] };
        if (not @values) {
            $self->Set( 'ExternalAuthPriority', \@values );
            return;
        }

        my %settings = %{ $self->Get('ExternalSettings') };
        for my $key (grep {not $settings{$_}} @values) {
            $RT::Logger->error("Removing '$key' from ExternalAuthPriority, as it is not defined in ExternalSettings");
        }
        @values = grep {$settings{$_}} @values;
        $self->Set( 'ExternalAuthPriority', \@values );
    },
};

$RT::Config::META{ExternalInfoPriority} = {
    PostLoadCheck => sub {
        my $self = shift;
        my @values = @{ shift || [] };
        if (not @values) {
            $RT::Logger->debug("ExternalInfoPriority not defined. User information (including user enabled/disabled) cannot be externally-sourced");
            $self->Set( 'ExternalInfoPriority', \@values );
            return;
        }

        my %settings = %{ $self->Get('ExternalSettings') };
        for my $key (grep {not $settings{$_}} @values) {
            $RT::Logger->error("Removing '$key' from ExternalInfoPriority, as it is not defined in ExternalSettings");
        }
        @values = grep {$settings{$_}} @values;

        for my $key (grep {$settings{$_}{type} eq "cookie"} @values) {
            $RT::Logger->error("Removing '$key' from ExternalInfoPriority, as cookie authentication cannot be used as an information source");
        }
        @values = grep {$settings{$_}{type} ne "cookie"} @values;

        $self->Set( 'ExternalInfoPriority', \@values );
    },
};

sub DoAuth {
    my ($session,$given_user,$given_pass) = @_;

    # Get the prioritised list of external authentication services
    my @auth_services = @{ RT->Config->Get('ExternalAuthPriority') };
    my $settings = RT->Config->Get('ExternalSettings');

    return (0, "ExternalAuthPriority not defined, please check your configuration file.")
        unless @auth_services;

    # This may be used by single sign-on (SSO) authentication mechanisms for bypassing a password check.
    my $success = 0;

    # Should have checked if user is already logged in before calling this function,
    # but just in case, we'll check too.
    return (0, "User already logged in!") if ($session->{'CurrentUser'} && $session->{'CurrentUser'}->Id);

    # For each of those services..
    foreach my $service (@auth_services) {

        # Get the full configuration for that service as a hashref
        my $config = $settings->{$service};
        $RT::Logger->debug( "Attempting to use external auth service:",
                            $service);

        # $username will be the final username we decide to check
        # This will not necessarily be $given_user
        my $username = undef;

        #############################################################
        ####################### SSO Check ###########################
        #############################################################
        if ($config->{'type'} eq 'cookie') {
            # Currently, Cookie authentication is our only SSO method
            $username = RT::Authen::ExternalAuth::DBI::GetCookieAuth($config);
        }
        #############################################################

        # If $username is defined, we have a good SSO $username and can
        # safely bypass the password checking later on; primarily because
        # it's VERY unlikely we even have a password to check if an SSO succeeded.
        my $pass_bypass = 0;
        if(defined($username)) {
            $RT::Logger->debug("Pass not going to be checked, attempting SSO");
            $pass_bypass = 1;
        } else {

            # SSO failed and no $user was passed for a login attempt
            # We only don't return here because the next iteration could be an SSO attempt
            unless(defined($given_user)) {
                $RT::Logger->debug("SSO Failed and no user to test with. Nexting");
                next;
            }

            # We don't have an SSO login, so we will be using the credentials given
            # on RT's login page to do our authentication.
            $username = $given_user;

            # Don't continue unless the service works.
            # next unless RT::Authen::ExternalAuth::TestConnection($config);

            # Don't continue unless the $username exists in the external service

            $RT::Logger->debug("Calling UserExists with \$username ($username) and \$service ($service)");
            next unless RT::Authen::ExternalAuth::UserExists($username, $service);
        }

        ####################################################################
        ########## Load / Auto-Create ######################################
        ####################################################################
        # We are now sure that we're talking about a valid RT user.
        # If the user already exists, load up their info. If they don't
        # then we need to create the user in RT.

        # Does user already exist internally to RT?
        $session->{'CurrentUser'} = RT::CurrentUser->new();
        $session->{'CurrentUser'}->Load($username);

        # Unless we have loaded a valid user with a UserID create one.
        unless ($session->{'CurrentUser'}->Id) {
            my $UserObj = RT::User->new($RT::SystemUser);
            my $create = RT->Config->Get('UserAutocreateDefaultsOnLogin')
                || RT->Config->Get('AutoCreate');
            my ($val, $msg) =
                $UserObj->Create(%{ref($create) ? $create : {}},
                                 Name   => $username,
                                 Gecos  => $username,
                             );
            unless ($val) {
                $RT::Logger->error( "Couldn't create user $username: $msg" );
                next;
            }
            $RT::Logger->info(  "Autocreated external user",
                                $UserObj->Name,
                                "(",
                                $UserObj->Id,
                                ")");

            $RT::Logger->debug("Loading new user (",
                                                $username,
                                                ") into current session");
            $session->{'CurrentUser'}->Load($username);
        }

        ####################################################################
        ########## Authentication ##########################################
        ####################################################################
        # If we successfully used an SSO service, then authentication
        # succeeded. If we didn't then, success is determined by a password
        # test.
        $success = 0;
        if($pass_bypass) {
            $RT::Logger->debug("Password check bypassed due to SSO method being in use");
            $success = 1;
        } else {
            $RT::Logger->debug("Password validation required for service - Executing...");
            $success = RT::Authen::ExternalAuth::GetAuth($service,$username,$given_pass);
        }

        $RT::Logger->debug("Password Validation Check Result: ",$success);

        # If the password check succeeded then this is our authoritative service
        # and we proceed to user information update and login.
        last if $success;
    }

    # If we got here and don't have a user loaded we must have failed to
    # get a full, valid user from an authoritative external source.
    unless ($session->{'CurrentUser'} && $session->{'CurrentUser'}->Id) {
        $session->{'CurrentUser'} = RT::CurrentUser->new;
        return (0, "No User");
    }

    unless($success) {
        $session->{'CurrentUser'} = RT::CurrentUser->new;
        return (0, "Password Invalid");
    }

    # Otherwise we succeeded.
    $RT::Logger->debug("Authentication successful. Now updating user information and attempting login.");

    ####################################################################################################
    ############################### The following is auth-method agnostic ##############################
    ####################################################################################################

    # If we STILL have a completely valid RT user to play with...
    # and therefore password has been validated...
    if ($session->{'CurrentUser'} && $session->{'CurrentUser'}->Id) {

        # Even if we have JUST created the user in RT, we are going to
        # reload their information from an external source. This allows us
        # to be sure that the user the cookie gave us really does exist in
        # the database, but more importantly, UpdateFromExternal will check
        # whether the user is disabled or not which we have not been able to
        # do during auto-create

        # These are not currently used, but may be used in the future.
        my $info_updated = 0;
        my $info_updated_msg = "User info not updated";

        if ( @{ RT->Config->Get('ExternalInfoPriority') } ) {
            # Note that UpdateUserInfo does not care how we authenticated the user
            # It will look up user info from whatever is specified in $RT::ExternalInfoPriority
            ($info_updated,$info_updated_msg) = RT::Authen::ExternalAuth::UpdateUserInfo($session->{'CurrentUser'}->Name);
        }

        # Now that we definitely have up-to-date user information,
        # if the user is disabled, kick them out. Now!
        if ($session->{'CurrentUser'}->UserObj->Disabled) {
            $session->{'CurrentUser'} = RT::CurrentUser->new;
            return (0, "User account disabled, login denied");
        }
    }

    # If we **STILL** have a full user and the session hasn't already been deleted
    # This If/Else is logically unnecessary, but it doesn't hurt to leave it here
    # just in case. Especially to be a double-check to future modifications.
    if ($session->{'CurrentUser'} && $session->{'CurrentUser'}->Id) {

            $RT::Logger->info(  "Successful login for",
                                $session->{'CurrentUser'}->Name,
                                "from",
                                $ENV{'REMOTE_ADDR'});
            # Do not delete the session. User stays logged in and
            # autohandler will not check the password again

            my $cu = $session->{CurrentUser};
            RT::Interface::Web::InstantiateNewSession();
            $session->{CurrentUser} = $cu;
    } else {
            # Make SURE the session is purged to an empty user.
            $session->{'CurrentUser'} = RT::CurrentUser->new;
            return (0, "Failed to authenticate externally");
            # This will cause autohandler to request IsPassword
            # which will in turn call IsExternalPassword
    }

    return (1, "Successful login");
}

sub UpdateUserInfo {
    my $username        = shift;

    # Prepare for the worst...
    my $found           = 0;
    my $updated         = 0;
    my $msg             = "User NOT updated";

    my $user_disabled   = RT::Authen::ExternalAuth::UserDisabled($username);

    my $UserObj = RT::User->new(RT->SystemUser);
    $UserObj->Load($username);

    # If user is disabled, set the RT::Principal to disabled and return out of the function.
    # I think it's a waste of time and energy to update a user's information if they are disabled
    # and it could be a security risk if they've updated their external information with some
    # carefully concocted code to try to break RT - worst case scenario, but they have been
    # denied access after all, don't take any chances.

    # If someone gives me a good enough reason to do it,
    # then I'll update all the info for disabled users

    if ($user_disabled) {
        unless ( $UserObj->Disabled ) {
            # Make sure principal is disabled in RT
            my ($val, $message) = $UserObj->SetDisabled(1);
            # Log what has happened
            $RT::Logger->info("User marked as DISABLED (",
                                $username,
                                ") per External Service",
                                "($val, $message)\n");
            $msg = "User Disabled";
        }

        return ($updated, $msg);
    }

    # Make sure principal is not disabled in RT
    if ( $UserObj->Disabled ) {
        my ($val, $message) = $UserObj->SetDisabled(0);
        unless ( $val ) {
            $RT::Logger->error("Failed to enable user ($username) per External Service: ".($message||''));
            return ($updated, "Failed to enable");
        }

        $RT::Logger->info("User ($username) was disabled, marked as ENABLED ",
                        "per External Service",
                        "($val, $message)\n");
    }

    # Update their info from external service using the username as the lookup key
    # CanonicalizeUserInfo will work out for itself which service to use
    # Passing it a service instead could break other RT code
    my %args = (Name => $username);
    $UserObj->CanonicalizeUserInfo(\%args);

    # For each piece of information returned by CanonicalizeUserInfo,
    # run the Set method for that piece of info to change it for the user
    my @results = $UserObj->Update(
        ARGSRef         => \%args,
        AttributesRef   => [keys %args],
    );
    $RT::Logger->debug("UPDATED user $username: $_")
        for @results;

    # Confirm update success
    $updated = 1;
    $RT::Logger->debug( "UPDATED user (",
                        $username,
                        ") from External Service\n");
    $msg = 'User updated';

    return ($updated, $msg);
}

sub GetAuth {

    # Request a username/password check from the specified service
    # This is only valid for non-SSO services.

    my ($service,$username,$password) = @_;

    my $success = 0;

    # Get the full configuration for that service as a hashref
    my $config = RT->Config->Get('ExternalSettings')->{$service};

    # And then act accordingly depending on what type of service it is.
    # Right now, there is only code for DBI and LDAP non-SSO services
    if ($config->{'type'} eq 'db') {
        $success = RT::Authen::ExternalAuth::DBI::GetAuth($service,$username,$password);
        $RT::Logger->debug("DBI password validation result:",$success);
    } elsif ($config->{'type'} eq 'ldap') {
        $success = RT::Authen::ExternalAuth::LDAP::GetAuth($service,$username,$password);
        $RT::Logger->debug("LDAP password validation result:",$success);
    }

    return $success;
}

sub UserExists {

    # Request a username/password check from the specified service
    # This is only valid for non-SSO services.

    my ($username,$service) = @_;

    my $success = 0;

    # Get the full configuration for that service as a hashref
    my $config = RT->Config->Get('ExternalSettings')->{$service};

    # And then act accordingly depending on what type of service it is.
    # Right now, there is only code for DBI and LDAP non-SSO services
    if ($config->{'type'} eq 'db') {
        $success = RT::Authen::ExternalAuth::DBI::UserExists($username,$service);
    } elsif ($config->{'type'} eq 'ldap') {
        $success = RT::Authen::ExternalAuth::LDAP::UserExists($username,$service);
    }

    return $success;
}

sub UserDisabled {

    my $username = shift;
    my $user_disabled = 0;

    my @info_services = @{ RT->Config->Get('ExternalInfoPriority') };

    # For each named service in the list
    # Check to see if the user is found in the external service
    # If not found, jump to next service
    # If found, check to see if user is considered disabled by the service
    # Then update the user's info in RT and return
    foreach my $service (@info_services) {

        # Get the external config for this service as a hashref
        my $config = RT->Config->Get('ExternalSettings')->{$service};

        # If it's a DBI config:
        if ($config->{'type'} eq 'db') {

            unless(RT::Authen::ExternalAuth::DBI::UserExists($username,$service)) {
                $RT::Logger->debug("User (",
                                    $username,
                                    ") doesn't exist in service (",
                                    $service,
                                    ") - Cannot update information - Skipping...");
                next;
            }
            $user_disabled = RT::Authen::ExternalAuth::DBI::UserDisabled($username,$service);

        } elsif ($config->{'type'} eq 'ldap') {

            unless(RT::Authen::ExternalAuth::LDAP::UserExists($username,$service)) {
                $RT::Logger->debug("User (",
                                    $username,
                                    ") doesn't exist in service (",
                                    $service,
                                    ") - Cannot update information - Skipping...");
                next;
            }
            $user_disabled = RT::Authen::ExternalAuth::LDAP::UserDisabled($username,$service);

        }

    }
    return $user_disabled;
}

sub CanonicalizeUserInfo {

    # Careful, this $args hashref was given to RT::User::CanonicalizeUserInfo and
    # then transparently passed on to this function. The whole purpose is to update
    # the original hash as whatever passed it to RT::User is expecting to continue its
    # code with an update args hash.

    my $UserObj = shift;
    my $args    = shift;

    my $found   = 0;
    my %params  = (Name         => undef,
                  EmailAddress => undef,
                  RealName     => undef);

    $RT::Logger->debug( (caller(0))[3],
                        "called by",
                        caller,
                        "with:",
                        join(", ", map {sprintf("%s: %s", $_, ($args->{$_} ? $args->{$_} : ''))}
                            sort(keys(%$args))));

    # Get the list of defined external services
    my @info_services = @{ RT->Config->Get('ExternalInfoPriority') };
    # For each external service...
    foreach my $service (@info_services) {

        $RT::Logger->debug( "Attempting to get user info using this external service:",
                            $service);

        # Get the config for the service so that we know what attrs we can canonicalize
        my $config = RT->Config->Get('ExternalSettings')->{$service};

        # For each attr we've been told to canonicalize in the match list
        foreach my $rt_attr (@{$config->{'attr_match_list'}}) {
            # Jump to the next attr in $args if this one isn't in the attr_match_list
            $RT::Logger->debug( "Attempting to use this canonicalization key:",$rt_attr);
            unless(defined($args->{$rt_attr})) {
                $RT::Logger->debug("This attribute (",
                                    $rt_attr,
                                    ") is null or incorrectly defined in the attr_map for this service (",
                                    $service,
                                    ")");
                next;
            }

            # Else, use it as a canonicalization key and lookup the user info
            my $key = $config->{'attr_map'}->{$rt_attr};
            my $value = $args->{$rt_attr};

            # Check to see that the key being asked for is defined in the config's attr_map
            my $valid = 0;
            my ($attr_key, $attr_value);
            my $attr_map = $config->{'attr_map'};
            while (($attr_key, $attr_value) = each %$attr_map) {
                $valid = 1 if ($key eq $attr_value);
            }
            unless ($valid){
                $RT::Logger->debug( "This key (",
                                    $key,
                                    "is not a valid attribute key (",
                                    $service,
                                    ")");
                next;
            }

            # Use an if/elsif structure to do a lookup with any custom code needed
            # for any given type of external service, or die if no code exists for
            # the service requested.

            if($config->{'type'} eq 'ldap'){
                ($found, %params) = RT::Authen::ExternalAuth::LDAP::CanonicalizeUserInfo($service,$key,$value);
            } elsif ($config->{'type'} eq 'db') {
                ($found, %params) = RT::Authen::ExternalAuth::DBI::CanonicalizeUserInfo($service,$key,$value);
            }

            # Don't Check any more attributes
            last if $found;
        }
        # Don't Check any more services
        last if $found;
    }

    # If found, Canonicalize Email Address and
    # update the args hash that we were given the hashref for
    if ($found) {
        # It's important that we always have a canonical email address
        if ($params{'EmailAddress'}) {
            $params{'EmailAddress'} = $UserObj->CanonicalizeEmailAddress($params{'EmailAddress'});
        }
        %$args = (%$args, %params);
    }

    $RT::Logger->info(  (caller(0))[3],
                        "returning",
                        join(", ", map {sprintf("%s: %s", $_, ($args->{$_} ? $args->{$_} : ''))}
                            sort(keys(%$args))));

    ### HACK: The config var below is to overcome the (IMO) bug in
    ### RT::User::Create() which expects this function to always
    ### return true or rejects the user for creation. This should be
    ### a different config var (CreateUncanonicalizedUsers) and
    ### should be honored in RT::User::Create()
    return($found || RT->Config->Get('AutoCreateNonExternalUsers'));

}

{
    no warnings 'redefine';
    *RT::User::CanonicalizeUserInfo = sub {
        my $self = shift;
        my $args = shift;
        return ( CanonicalizeUserInfo( $self, $args ) );
    };
}

1;
