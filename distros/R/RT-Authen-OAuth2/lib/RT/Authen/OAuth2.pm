use strict;
use warnings;
package RT::Authen::OAuth2;

our $VERSION = '0.12';

use Net::OAuth2::Profile::WebServer;

use RT::Authen::OAuth2::Unimplemented;
use RT::Authen::OAuth2::Google;

use URI::Escape;

RT->AddStyleSheets('rt-authen-oauth2.css');

=head1 NAME

RT-Authen-OAuth2 - External authentication for OAuth 2 sources, like Google, Twitter, GitHub, etc.

=head1 DESCRIPTION

External authentication for OAuth2 sources.

=head1 RT VERSION

Works with RT 4.4 and 5

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

=item Add / Edit OAuth2 configs found in OAuth2_Config.pm

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

This software is Copyright (c) 2016-2024 by Best Practical Solutions LLC

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
    my $idp_conf = RT->Config->Get('OAuthIDPs')->{$idp};

    $idp_conf->{state} = $args->{next} || '';
    $idp_conf->{client_id} = RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_id};
    $idp_conf->{client_secret} = RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_secret};

    die("OAuth2 client_id and client_secret must both be configured")
        unless $idp_conf->{client_id} and $idp_conf->{client_secret};

    my $auth = Net::OAuth2::Profile::WebServer->new(
        %$idp_conf,
        redirect_uri => RT->Config->Get('OAuthRedirect'),
    );

    my $ip = RT::Interface::Web::RequestENV('REMOTE_ADDR') || 'UNKNOWN';
    RT::Logger->info("OAuth 2 redirect from RequestAuthorization() from $ip");
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

    RT::Logger->info("OAuth2 user already logged in, aborting; new request from $ip") if $session->{CurrentUser} and $session->{CurrentUser}->Id;
    return (0, $generic_error) if $session->{CurrentUser} and $session->{CurrentUser}->Id;

    # Retrieve the Authorization Server configs
    my $idp = RT->Config->Get('OAuthIDP');
    my $idp_conf = RT->Config->Get('OAuthIDPs')->{$idp};

    # Set up the Net::OAuth2 object to handle the requests
    my $auth = Net::OAuth2::Profile::WebServer->new(
        # TODO future feature: secrets should exist per-IDP to support multiple options at once
        %$idp_conf,
        client_id => RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_id},
        client_secret => RT->Config->Get('OAuthIDPSecrets')->{$idp}->{client_secret},
        redirect_uri => RT->Config->Get('OAuthRedirect'),
    );

    # Call the Authorization Server and get an access token
    my $access_token = $auth->get_access_token($args->{code});

    # Retrieve the user's profile metadata from the protected resource
    my $response = $access_token->get($idp_conf->{protected_resource_url} || $idp_conf->{protected_resource_path});

    # Get the correct handler for the user's metadata, based on which IDP is in use
    my $idp_handler = $idp_conf->{MetadataHandler};
    my $metadata = $idp_handler->Metadata($response->decoded_content);
    my $loadcol = $idp_conf->{LoadColumn} || 'EmailAddress';
    my $name = $metadata->{ $idp_conf->{MetadataMap}->{$loadcol} };

    # email is used to identify the user; bail out if we don't have one
    RT::Logger->info("OAuth2 server return content didn't include $loadcol, aborting. Request from $ip") unless $name;
    return (0, $generic_error) unless $name;

    if ( $idp_conf->{MetadataMap}->{VerifiedEmail} && !$metadata->{ $idp_conf->{MetadataMap}->{VerifiedEmail} } ) {
      RT::Logger->info( "Email $name not verified." );
      return ( 0, RT->SystemUser->loc( "Email [_1] not verified.", $name ) );
    }

    my $user = RT::User->new( RT->SystemUser );
    $user->LoadByCol($loadcol, $name);

    # TODO future feature: add an option to auto-vivify only if email matches regex
    # TODO e.g., allow all people from mycompany.com to access RT automatically

    RT::Logger->info("OAuth2 user $name attempted login but no matching user found in RT. Request from $ip") unless $user->id;
    if (RT->Config->Get('OAuthCreateNewUser') and not $user->id) {
      my $additional = RT->Config->Get('OAuthNewUserOptions') || { Privileged => 1 };
      my $newuser = RT::User->new( $RT::SystemUser );
      RT::Logger->info("Attempting to create account for $name");
      my ( $id, $msg ) = $newuser->Create(
        %$additional,
        Name => $name,
        map { $_ => $metadata->{ $idp_conf->{MetadataMap}->{$_} } }
          grep { $metadata->{ $idp_conf->{MetadataMap}->{$_} } }
          qw(RealName NickName Organization Lang EmailAddress),
      );
      unless ($id) {
        RT::Logger->info("Error $msg creating account for $name");
        return (0, $generic_error);
      }
      $user = $newuser;
    }
    return(0, $generic_error) unless $user->id;

    RT::Logger->info("OAuth2 user $name is disabled in RT; aborting OAuth2 login. Request from $ip") if $user->PrincipalObj->Disabled;
    return(0, $generic_error) if $user->PrincipalObj->Disabled;

    # Populate any empty fields in the RT user profile from the OAuth server metadata
    # May be able to expand the number of fields mapped here, if other servers return
    # appropriate data
    my @fields = qw(RealName NickName Organization Lang);
    $user->Update(
        AttributesRef => [@fields],
        ARGSRef => {
            map { $_ => $user->$_() || $metadata->{$idp_conf->{MetadataMap}->{$_}} || '' } @fields
        },
    );

    # Set up our session and return to the handler template element for the redirect
    RT::Logger->info("Successful OAuth2 login for $name from $ip");
    RT::Interface::Web::InstantiateNewSession();
    $session->{CurrentUser} = RT::CurrentUser->new($user);
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
    return RT->Config->Get('OAuthIDPs')->{$idp}->{LoginPageButton};
}

=head2 C<LogOutURL()>

=over 4

Returns the appropriate logout URL active OAuth 2 server.

=back

=cut

sub LogoutURL {
    my $next = shift;
    my $idp = RT->Config->Get('OAuthIDP');
    my $idp_config = RT->Config->Get('OAuthIDPs')->{$idp};

    unless (exists $idp_config->{logout_path}) {
      return $next;
    }

    my $url = $idp_config->{site} . $idp_config->{logout_path};
    $next = uri_escape($next);
    $url =~ s/__NEXT__/$next/;
    return $url;
}

1;
