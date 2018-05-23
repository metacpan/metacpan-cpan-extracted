package Plack::Auth::SSO::Shibboleth;

use strict;
use utf8;
use feature qw(:5.10);
use Data::Util qw(:check);
use Moo;
use Plack::Request;
use Plack::Session;
use JSON;

our $VERSION = "0.0135";

with "Plack::Auth::SSO";

#cf. https://github.com/toyokazu/omniauth-shibboleth/blob/master/lib/omniauth/strategies/shibboleth.rb

has request_type => (
    is => "ro",
    isa => sub {
        my $r = $_[0];
        is_string( $r ) or die( "request_type should be string" );
        $r eq "env" || $r eq "header" || die( "request_type must be either 'env' or 'header'" );
    },
    lazy => 1,
    default => sub { "env"; }
);
has shib_session_id_field => (
    is => "ro",
    isa => sub { is_string( $_[0] ) or die( "shib_session_id_field should be string" ); },
    lazy => 1,
    default => sub { "Shib-Session-ID"; }
);
has shib_application_id_field => (
    is => "ro",
    isa => sub { is_string( $_[0] ) or die( "shib_application_id_field should be string" ); },
    lazy => 1,
    default => sub { "Shib-Application-ID"; }
);
has uid_field => (
    is => "ro",
    isa => sub { is_string( $_[0] ) or die( "uid_field should be string" ); },
    lazy => 1,
    default => sub { "eppn"; }
);
has info_fields => (
    is => "ro",
    isa => sub { is_array_ref( $_[0] ) or die( "info_fields should be array ref" ); },
    lazy => 1,
    default => sub { []; }
);

#cf. https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeAccess
my @other_shib_fields = qw(
    Shib-Identity-Provider
    Shib-Authentication-Instant
    Shib-Authentication-Method
    Shib-AuthnContext-Class
    Shib-AuthnContext-Decl
    Shib-Handler
    Shib-Session-Index
    Shib-Cookie-Name
);

sub request_param {
    my ( $self, $env, $key ) = @_;

    if ( $self->request_type eq "env" ) {

        return $env->{$key};

    }

    $key = uc($key);
    $key =~ tr/-/_/;
    $env->{"HTTP_${key}"};

}

sub to_app {
    my $self = $_[0];
    sub {

        state $json = JSON->new()->utf8(1);

        my $env = $_[0];

        my $request = Plack::Request->new($env);
        my $session = Plack::Session->new($env);

        my $auth_sso = $self->get_auth_sso($session);

        #already got here before
        if (is_hash_ref($auth_sso)) {

            return [
                302, [Location => $self->uri_for($self->authorization_path)],
                []
            ];

        }

        #Shibboleth Session active?
        my $shib_session_id = $self->request_param( $env, $self->shib_session_id_field );
        my $shib_application_id = $self->request_param( $env, $self->shib_application_id_field );
        my $uid = $self->request_param( $env, $self->uid_field );

        unless ( is_string( $shib_session_id ) && is_string( $shib_application_id ) && is_string($uid) ) {

            return [
                401, [ "Content-Type" => "text/plain" ], [ "Unauthorized" ]
            ];

        }

        my $info = +{};
        for my $info_field ( @{ $self->info_fields() } ) {
            $info->{$info_field} = $self->request_param( $env, $info_field );
        }

        my $extra = +{
            "Shib-Session-ID" => $shib_session_id,
            "Shib-Application-ID" => $shib_application_id
        };
        for my $shib_field ( @other_shib_fields ) {
            $extra->{$shib_field} = $self->request_param( $env, $shib_field );
        }

        my $content = +{};
        for my $header ( keys %$env ) {
            next if index( $header, "psgi" ) == 0;
            $content->{$header} = $env->{$header};
        }

        $self->set_auth_sso(
            $session,
            {
                uid => $uid,
                info => $info,
                extra => $extra,
                package    => __PACKAGE__,
                package_id => $self->id,
                response   => {
                    content => $json->encode($content),
                    content_type => "application/json"
                }
            }
        );

        return [
            302,
            [Location => $self->uri_for($self->authorization_path)],
            []
        ];



    };
}

1;

=pod

=head1 NAME

Plack::Auth::SSO::Shibboleth - implementation of Plack::Auth::SSO for Shibboleth

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an implementation of L<Plack::Auth::SSO> to authenticate behind a Shibboleth Service Provider (SP)

It inherits all configuration options from its parent.

=head1 CONFIG

=over 4

=item error_path

This option is inherited by its parent class L<Plack::Auth::SSO>, but cannot be used unfortunately

because an SP will never allow an invalid request to be passed to the backend. This should be configured in

/etc/shibboleth/shibboleth2.xml ( cf. https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPErrors ).

=item request_type

* "env": Shibboleth SP sends attributes using environment variables (CGI and FCGI)

* "header": Shibboleth SP sends attributes using headers (proxy)

Default is "env"

=item shib_session_id_field

Field where Shibboleth SP stores the session id.

Default is "Shib-Session-ID"

=item shib_application_id_field

Field where Shibboleth SP stores the application id.

Default is "Shib-Application-ID"

=item uid_field

Field to be used as uid

Default is "eppn"

=item info_fields

Fields to be extracted from the environment/headers

=back

=head1 auth_sso output

    {

        package => "Plack::Auth::SSO::Shibboleth",

        package_id => "Plack::Auth::SSO::Shibboleth",

        #configured by "uid_field"
        uid => "<unique-identifier>",

        #configured by "info_fields". Empty otherwise
        info => {
            attr1 => "attr1",
            attr2 => "attr2"
        },

        #Shibboleth headers/environment variables
        extra => {
            "Shib-Session-Id" => "..",
            "Shib-Application-Id" => "..",
            "Shib-Identity-Provider" => "https://path.to/shibboleth./idp",
            "Shib-Authentication-Instant" => "",
            "Shib-Authentication-Method" => "POST",
            "Shib-AuthnContext-Class" => "..",
            "Shib-AuthnContext-Decl" => "..",
            "Shib-Handler" => "..",
            "Shib-Session-Index" => ".."
            "Shib-Cookie-Name" => ".."
        },

        #We cannot access the original SAML response, so we rely on the headers/environment
        response => {
            content_type => "application/json",
            content => "<headers/environment serialized as json>"
        }
    }

=head1 GLOBAL SETUP

This module does not do what it claims to do: authenticating the user by communicating with an external service.

The real authenticating module lives inside the Apache web server, and is called "mod_shib".

That module intercepts all requests to a specific path (e.g. "/auth/shibboleth"), authenticates the user, and, when done, sends the requests
to the backend application. As long as a Shibboleth session exists in mod_shib, the request passes through.

That backend application merely receives the end result of the authentication: a list of attributes.
The original SAML response from the Shibboleth Identity Provider is not sent.

There are two ways to transfer the attributes from mod_shib to the application:

* the application lives inside Apache (CGI, FCGI). The attributes are sent as environment variables. This is the default situation, and the most secure.

* the application is a separate server, and Apache merely a proxy server. The attributes are sent as headers.
  This is less secure.

cf. <https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPAttributeAccess>

This module merely convert these attributes.

=head1 SETUP BEHIND PROXY

=over 4

=item plack application

    use strict;
    use Data::Util qw(:check);
    use Plack::Auth::SSO::Shibboleth;
    use Plack::Builder;
    use Plack::Session;
    use JSON;

    my $uri_base = "https://example.org";

    builder {

        enable "Session",

        #mod_shib should intercept all requests to this path
        mount "/auth/shibboleth"  => Plack::Auth::SSO::Shibboleth->new(
            uri_base => $uri_base,
            authorization_path => "/authorize",
            uid_field => "uid",
            request_type => "header",
            info_fields => [qw(mail organizational-unit-name givenname sn unscoped-affiliation entitlement persistent-id)]
        )->to_app();

        mount "/authorize" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);

            #already logged in. What are you doing here?
            if ( is_hash_ref( $session->get("user") ) ) {

                return [
                    302,
                    [ Location => "${uri_base}/authorized" ],
                    []
                ];

            }

            my $auth_sso = $session->get("auth_sso");

            #not authenticated yet
            unless($auth_sso){

                return [
                    302,
                    [ "Location" => "${uri_base}/" ],
                    []
                ];

            }

            $session->set("user",{ uid => $auth_sso->{uid}, auth_sso => $auth_sso });

            [
                302,
                [ Location => "${uri_base}/authorized" ],
                []
            ];

        };
        mount "/authorized" => sub {
            state $json = JSON->new->utf8(1);

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $user = $session->get("user");

            #not logged in
            unless ( is_hash_ref( $user ) ) {

                return [
                    401,
                    [ "Content-Type" => "text/plain" ],
                    [ "Forbidden" ]
                ];

            }

            #logged in: show user his/her data
            [
                200,
                [ "Content-Type" => "application/json" ],
                [ $json->encode( $user ) ]
            ];

        };

    };

=item httpd.conf

    NameVirtualHost *:443
    <VirtualHost *:443 >

      ServerName example.org

      #shibd is a background service, so it needs to know the domain and port
      UseCanonicalName on
      UseCanonicalPhysicalPort on

      #configure SSL
      SSLEngine on
      SSLProtocol all -SSLv2 -SSLv3
      SSLHonorCipherOrder on
      SSLCipherSuite "ALL:!ADH:!EXP:!LOW:!RC2:!SEED:!RC4:+HIGH:+MEDIUM HIGH:!SSLv2:!ADH:!aNULL:!eNULL:!NULL !PSK !SRP !DSS"
      SSLCertificateFile /etc/httpd/ssl/server.pem
      SSLCertificateKeyFile /etc/httpd/ssl/server.key
      SSLCACertificateFile /etc/httpd/ssl/server.pem

      #do not proxy Shibboleth paths
      ProxyPass /shibboleth-sp !
      ProxyPass /Shibboleth.sso !

      #proxy all requests to background Plack application
      ProxyPass / http://127.0.0.1:5000/
      ProxyPassReverse / http://127.0.0.1:5000/

      #all request to /auth/shibboleth should be intercepted by mod_shib before
      #sending to background plack application
      <Location /auth/shibboleth>

        AuthName "shibboleth"
        AuthType shibboleth
        Require valid-user
        ShibRequestSetting requireSession true
        ShibRequestSetting redirectToSSL 443

        #necessary to send the attributes in the headers
        ShibUseHeaders On
      </Location>

      #Path to metadata.xml
      Alias /shibboleth-sp /var/www/html/shibboleth-sp

      #handler for Shibboleth Service Provider
      <Location /Shibboleth.sso>
        SetHandler shib-handler
        ErrorDocument 403 /public/403.html
      </Location>

      ProxyRequests Off
      <Proxy *>
        Order Deny,Allow
        Allow from all
      </Proxy>

    </VirtualHost>

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Plack::Auth::SSO>

=cut
