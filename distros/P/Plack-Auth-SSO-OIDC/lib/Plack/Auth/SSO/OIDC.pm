package Plack::Auth::SSO::OIDC;

use strict;
use warnings;
use feature qw(:5.10);
use Data::Util qw(:check);
use Data::UUID;
use Moo;
use Plack::Request;
use Plack::Session;
use URI;
use LWP::UserAgent;
use JSON;
use Crypt::JWT;
use MIME::Base64;
use Digest::SHA;
use Try::Tiny;

our $VERSION = "0.01";

with "Plack::Auth::SSO";

has scope => (
    is => "lazy",
    isa => sub {
        is_string($_[0]) or die("scope should be string");
        index($_[0], "openid") >= 0 or die("default scope openid not included");
    },
    default => sub { "openid profile email" },
    required => 1
);

has client_id => (
    is  => "ro",
    isa => sub { is_string($_[0]) or die("client_id should be string"); },
    required => 1
);

has client_secret => (
    is  => "ro",
    isa => sub { is_string($_[0]) or die("client_secret should be string"); },
    required => 1
);

has openid_uri => (
    is  => "ro",
    isa => sub { is_string($_[0]) or die("openid_uri should be string"); },
    required => 1
);

has uid_key => (
    is => "ro",
    isa => sub { is_string($_[0]) or die("uid_key should be string"); },
    required => 1
);

# internal (non overwritable) moo attributes
has json => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        JSON->new->utf8(1);
    },
    init_arg => undef
);

has ua => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        LWP::UserAgent->new();
    },
    init_arg => undef
);

has openid_configuration => (
    is => "lazy",
    init_arg => undef
);

has jwks => (
    is => "lazy",
    init_arg => undef
);

sub get_json {

    my ($self, $url) = @_;

    my $res = $self->ua->get($url);

    if ( $res->code ne "200" ) {

        $self->log->errorf("url $url returned invalid status code %s", $res->code);
        return undef, "INVALID_HTTP_STATUS";

    }

    if ( index($res->content_type, "json") < 0 ) {

        $self->log->errorf("url $url returned invalid content type %s", $res->content_type);
        return undef, "INVALID_HTTP_CONTENT_TYPE";

    }

    my $data;
    my $data_error;
    try {
        $data = $self->json->decode($res->content);
    } catch {
        $data_error = $_;
    };

    if ( defined($data_error) ) {

        $self->log->error("could not decode json returned from $url");
        return undef, "INVALID_HTTP_CONTENT";

    }

    $data;

}

sub _build_openid_configuration {

    my $self = $_[0];

    my $url = $self->openid_uri;
    my ($data, @errors) = $self->get_json($url);
    die("unable to retrieve openid configuration from $url: ".join(", ",@errors))
        unless defined($data);
    $data;

}

# https://auth0.com/blog/navigating-rs256-and-jwks/
sub _build_jwks {

    my $self = $_[0];

    my $jwks_uri = $self->openid_configuration->{jwks_uri};

    die("attribute jwks_uri not found in openid_configuration")
        unless is_string($jwks_uri);

    my ($data, @errors) = $self->get_json($jwks_uri);

    die("unable to retrieve jwks from ".$self->openid_configuration->{jwks_uri}.":".join(", ", @errors))
        if scalar(@errors);

    $data;

}

sub redirect_uri {

    my ($self, $request) = @_;
    my $redirect_uri = $self->uri_base().$request->request_uri();
    my $idx = index( $redirect_uri, "?" );
    if ( $idx >= 0 ) {

        $redirect_uri = substr( $redirect_uri, 0, $idx );

    }
    $redirect_uri;

}

sub make_random_string {

    MIME::Base64::encode_base64url(
        Data::UUID->new->create() .
        Data::UUID->new->create() .
        Data::UUID->new->create()
    );

}

sub generate_authorization_uri {

    my ($self, %args) = @_;

    my $request = $args{request};
    my $session = $args{session};

    my $openid_conf = $self->openid_configuration;
    my $authorization_endpoint = $openid_conf->{authorization_endpoint};

    # cf. https://developers.onelogin.com/openid-connect/guides/auth-flow-pkce
    # Note: minimum of 43 characters!
    my $code_verifier  = $self->make_random_string();
    my $code_challenge = MIME::Base64::encode_base64url(Digest::SHA::sha256($code_verifier),"");
    my $state          = $self->make_random_string();

    my $uri = URI->new($authorization_endpoint);
    $uri->query_form(
        code_challenge          => $code_challenge,
        code_challenge_method   => "S256",
        state                   => $state,
        scope                   => $self->scope(),
        client_id               => $self->client_id,
        response_type           => "code",
        redirect_uri            => $self->redirect_uri($request)
    );
    $self->set_csrf_token($session, $state);
    $session->set("auth_sso_oidc_code_verifier", $code_verifier);

    $uri->as_string;

}

around cleanup => sub {

    my ($orig, $self, $session) = @_;
    $self->$orig($session);
    $session->remove("auth_sso_oidc_code_verifier");

};

# extract_claims_from_id_token(id_token) : claims_as_hash
sub extract_claims_from_id_token {

    my ($self, $id_token) = @_;

    my ($jose_header, $payload, $s) = split(/\./o, $id_token);

    # '{ "alg": "RS256", "kid": "my-key-id" }'
    $jose_header = $self->json->decode(MIME::Base64::decode($jose_header));

    #{ "keys": [{ "kid": "my-key-id", "alg": "RS256", "use": "sig" .. }] }
    my $jwks  = $self->jwks();
    my ($key) = grep { $_->{kid} eq $jose_header->{kid} }
                @{ $jwks->{keys} };

    my $claims;
    my $claims_error;
    try {
        $claims = Crypt::JWT::decode_jwt(token => $id_token, key => $key);
    } catch {
        $claims_error = $_;
    };

    $self->log->errorf("error occurred while decoding JWS: %s", $claims_error)
        if defined $claims_error;

    $claims;

}

sub exchange_code_for_tokens {

    my ($self, %args) = @_;

    my $request = $args{request};
    my $session = $args{session};
    my $code    = $args{code};

    my $openid_conf = $self->openid_configuration;
    my $token_endpoint = $openid_conf->{token_endpoint};
    my $token_endpoint_auth_methods_supported = $openid_conf->{token_endpoint_auth_methods_supported} // [];
    $token_endpoint_auth_methods_supported =
        is_array_ref($token_endpoint_auth_methods_supported) ?
        $token_endpoint_auth_methods_supported :
        [$token_endpoint_auth_methods_supported];

    my $auth_sso_oidc_code_verifier = $session->get("auth_sso_oidc_code_verifier");

    my $params = {
        grant_type      => "authorization_code",
        client_id       => $self->client_id,
        code            => $code,
        code_verifier   => $auth_sso_oidc_code_verifier,
        redirect_uri    => $self->redirect_uri($request),
    };

    my $headers = {
        "Content-Type" => "application/x-www-form-urlencoded"
    };
    my $client_id = $self->client_id;
    my $client_secret = $self->client_secret;

    if ( grep { $_ eq "client_secret_basic" } @$token_endpoint_auth_methods_supported ) {

        $self->log->info("using client_secret_basic");
        $headers->{"Authorization"} = "Basic " . MIME::Base64::encode_base64url("$client_id:$client_secret");

    }
    elsif ( grep { $_ eq "client_secret_post" } @$token_endpoint_auth_methods_supported ) {

        $self->log->info("using client_secret_post");
        $params->{client_secret} = $client_secret;

    }
    else {

        die("token_endpoint $token_endpoint does not support client_secret_basic or client_secret_post");

    }

    my $res = $self->ua->post(
        $token_endpoint,
        $params,
        %$headers
    );

    die("$token_endpoint returned invalid content type ".$res->content_type)
        unless $res->content_type =~ /json/o;

    $self->json->decode($res->content);
}

sub to_app {

    my $self = $_[0];

    sub {

        my $env = $_[0];
        my $log = $self->log();

        my $request = Plack::Request->new($env);
        my $session = Plack::Session->new($env);
        my $query_params  = $request->query_parameters();

        if( $self->log->is_debug() ){

            $self->log->debugf( "incoming query parameters: %s", [$query_params->flatten] );
            $self->log->debugf( "session: %s", $session->dump() );
            $self->log->debugf( "session_key for auth_sso: %s" . $self->session_key() );

        }

        if ( $request->method ne "GET" ) {

            $self->log->errorf("invalid http method %s", $request->method);
            return [400, [ "Content-Type" => "text/plain" ], ["invalid http method"]];

        }

        my $auth_sso = $self->get_auth_sso($session);

        #already got here before
        if ( is_hash_ref($auth_sso) ) {

            $log->debug( "auth_sso already present" );

            return $self->redirect_to_authorization();

        }

        my $state = $query_params->get("state");
        my $stored_state = $self->get_csrf_token($session);

        # redirect to authorization url
        if ( !(is_string($stored_state) && is_string($state)) ) {

            $self->cleanup($session);

            my $authorization_uri = $self->generate_authorization_uri(
                request => $request,
                session => $session
            );

            return [302, [Location => $authorization_uri], []];

        }

        # check csrf
        if ( $stored_state ne $state ) {

            $self->cleanup();
            $self->set_auth_sso_error( $session,{
                package    => __PACKAGE__,
                package_id => $self->id,
                type => "CSRF_DETECTED",
                content => "CSRF_DETECTED"
            });
            return $self->redirect_to_error();

        }

        # validate authorization returned from idp
        my $error = $query_params->get("error");
        my $error_description = $query_params->get("error_description");

        if ( is_string($error) ) {

            $self->cleanup();
            $self->set_auth_sso_error($session, {
                package    => __PACKAGE__,
                package_id => $self->id,
                type => $error,
                content => $error_description
            });
            return $self->redirect_to_error();

        }

        my $code = $query_params->get("code");

        unless ( is_string($code) ) {

            $self->cleanup();
            $self->set_auth_sso_error($session, {
                package    => __PACKAGE__,
                package_id => $self->id,
                type => "AUTH_SSO_OIDC_AUTHORIZATION_NO_CODE",
                content => "oidc authorization endpoint did not return query parameter code"
            });
            return $self->redirect_to_error();

        }

        my $tokens = $self->exchange_code_for_tokens(
            request => $request,
            session => $session,
            code    => $code
        );

        $self->log->debugf("tokens: %s", $tokens)
            if $self->log->is_debug();

        my $claims = $self->extract_claims_from_id_token($tokens->{id_token});

        $self->log->debugf("claims: %s", $claims)
            if $self->log->is_debug();

        $self->cleanup($session);

        $self->set_auth_sso(
            $session,
            {
                extra => {},
                info  => $claims,
                uid   => $claims->{ $self->uid_key() },
                package    => __PACKAGE__,
                package_id => $self->id,
                response   => {
                    content => $self->json->encode($tokens),
                    content_type => "application/json"
                }
            }
        );

        $self->log->debugf("auth_sso: %s", $self->get_auth_sso($session))
            if $self->log->is_debug();

        return $self->redirect_to_authorization();

    };

}

1;

=pod

=head1 NAME

Plack::Auth::SSO::OIDC - implementation of OpenID Connect for Plack::Auth::SSO

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Plack-Auth-SSO-OIDC.svg?branch=main)](https://travis-ci.org/LibreCat/Plack-Auth-SSO-OIDC)
[![Coverage](https://coveralls.io/repos/LibreCat/Plack-Auth-SSO-OIDC/badge.png?branch=main)](https://coveralls.io/r/LibreCat/Plack-Auth-SSO-OIDC)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO-OIDC.png)](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO-OIDC)

=end markdown

=head1 DESCRIPTION

This is an implementation of L<Plack::Auth::SSO> to authenticate against a openid connect server.

It inherits all configuration options from its parent.

=head1 SYNOPSIS

    # in your app.psi (Plack)

    use strict;
    use warnings;
    use Plack::Builder;
    use JSON;
    use Plack::Auth::SSO::OIDC;
    use Plack::Session::Store::File;

    my $uri_base = "http://localhost:5000";

    builder {

        # session middleware needed to store "auth_sso" and/or "auth_sso_error"
        # in memory session store for testing purposes
        enable "Session";

        # for authentication, redirect your users to this path
        mount "/auth/oidc" => Plack::Auth::SSO::OIDC->new(

            # plack application needs to know about the base url of this application
            uri_base => $uri_base,

            # after successfull authentication, user is redirected to this path (uri_base is used!)
            authorization_path => "/auth/callback",

            # when authentication fails at the identity provider
            # user is redirected to this path with session key "auth_sso_error" (hash)
            error_path => "/auth/error",

            # openid connect discovery url
            openid_uri => "https://example.oidc.org/auth/oidc/.well-known/openid-configuration",
            client_id => "my-client-id",
            client_secret => "myclient-secret",
            uid_key => "email"

        )->to_app();

        # example psgi app that is called after successfull authentication at /auth/oidc (see above)
        # it expects session key "auth_sso" to be present
        # here you typically create a user session based on the uid in "auth_sso"
        mount "/auth/callback" => sub {

            my $env     = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso= $session->get("auth_sso");
            my $user    = MyUsers->get( $auth_sso->{uid} );
            $session->set("user_id", $user->{id});
            [ 200, [ "Content-Type" => "text/plain" ], [
                "logged in! ", $user->{name}
            ]];

        };

        # example psgi app that is called after unsuccessfull authentication at /auth/oidc (see above)
        # it expects session key "auth_sso_error" to be present
        mount "/auth/error" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso_error = $session->get("auth_sso_error");

            [ 200, [ "Content-Type" => "text/plain" ], [
                "something happened during single sign on authentication: ",
                $auth_sso_error->{content}
            ]];

        };
    };

=head1 CONSTRUCTOR ARGUMENTS

=over 4

=item C<< uri_base >>

See L<Plack::Auth::SSO/uri_base>

=item C<< id >>

See L<Plack::Auth::SSO/id>

=item C<< session_key >>

See L<Plack::Auth::SSO/session_key>

=item C<< authorization_path >>

See L<Plack::Auth::SSO/authorization_path>

=item C<< error_path >>

See L<Plack::Auth::SSO/error_path>

=item C<< openid_uri >>

base url of the OIDC discovery url.

typically an url that ends on C<< /.well-known/openid-configuration >>

=item C<< client_id >>

client-id as given by the OIDC service

=item C<< client_secret >>

client-secret as given by the OIDC service

=item C<< scope >>

Scope requested from the OIDC service.

Space separated string containing all scopes

Default: C<< "openid profile email" >>

Please include scope C<< "openid" >>

cf. L<https://openid.net/specs/openid-connect-basic-1_0.html#Scopes>

=item C<< uid_key >>

Attribute from claims to be used as uid

Note that all claims are also stored in C<< $session->get("auth_sso")->{info} >>

=back

=head1 HOW IT WORKS

=over 4

=item the openid configuration is retrieved from C<< {openid_uri} >>

=over 6

=item key C<< authorization_endpoint >> must be present in openid configuration

=item key C<< token_endpoint >> must be present in openid configuration

=item key C<< jwks_uri >> must be present in openid configuration

=item the user is redirected to the authorization endpoint with extra query parameters

=back

=item after authentication at the authorization endpoint, the user is redirected back to this url with query parameters C<< code >> and C<< state >>. When something happened at the authorization endpoint, query parameters C<< error >> and C<< error_description >> are returned, and no C<< code >>.

=item C<< code >> is exchanged for a json string, using the token endpoint. This json string is a record that contains attributes like C<< id_token >> and C<< access_token >>. See L<https://openid.net/specs/openid-connect-core-1_0.html#TokenResponse> for more information.

=item key C<< id_token >> in the token json string contains three parts:

=over 6

=item jwt jose header. Can be decoded with base64 into a json string

=item jwt payload. Can be decoded with base64 into a json string

=item jwt signature

=back

=item the jwt payload from the C<< id_token >> is decoded into a json string and then to a perl hash. All this data is stored C<< $session->{auth_sso}->{info} >>. One of these attributes will be the uid that will be stored at C<< $session->{auth_sso}->{uid} >>. This is determined by configuration key C<< uid_key >> (see above). e.g. "email"

=back

=head1 LOGGING

All subclasses of L<Plack::Auth::SSO> use L<Log::Any>
to log messages to the category that equals the current
package name.

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Plack::Auth::SSO>

=cut
