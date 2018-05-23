package Plack::Auth::SSO::ORCID;

use strict;
use utf8;
use feature qw(:5.10);
use Data::Util qw(:check);
use Moo;
use Plack::Request;
use Plack::Session;
use URI;
use LWP::UserAgent;
use WWW::ORCID;
use JSON;
use Plack::Auth::SSO::ResponseParser::ORCID;

our $VERSION = "0.0135";

with "Plack::Auth::SSO";

has sandbox => (
    is => "ro",
    required => 0
);
has public => (
    is => "ro",
    required => 0,
    lazy => 1,
    default => sub { 1; }
);
has scope => (
    is => "lazy"
);
has client_id => (
    is => "ro",
    isa => sub { is_string($_[0]) or die("client_id should be string"); },
    required => 1
);
has client_secret => (
    is => "ro",
    isa => sub { is_string($_[0]) or die("client_secret should be string"); },
    required => 1
);

has orcid => (
    is => "lazy",
    init_arg => undef
);
has response_parser => (
    is => "ro",
    lazy => 1,
    default => sub {
        Plack::Auth::SSO::ResponseParser::ORCID->new();
    },
    init_arg => undef
);
has json => (
    is => "ro",
    lazy => 1,
    default => sub {
        JSON->new->utf8(1);
    },
    init_arg => undef
);

sub _build_orcid {

    my $self = $_[0];

    WWW::ORCID->new(
        client_id => $self->client_id(),
        client_secret => $self->client_secret(),
        sandbox => $self->sandbox(),
        public => $self->public(),
        transport => "LWP"
    );

}

sub _build_scope {
    my $self = $_[0];
    $self->public() ? "/authenticate" : "/read-limited";
}

sub redirect_to_login {

    my ( $self, $request ) = @_;

    my $request_uri = $request->request_uri();
    my $idx = index( $request_uri, "?" );
    if ( $idx >= 0 ) {

        $request_uri = substr( $request_uri, 0, $idx );

    }

    my $redirect_uri = URI->new( $self->uri_for($request_uri) );

    my $auth_uri = $self->orcid->authorize_url(
        show_login => "true",
        scope => $self->scope(),
        response_type => "code",
        redirect_uri => $redirect_uri->as_string()
    );

    [ 302, [ Location => $auth_uri ], [] ];

}

sub to_app {
    my $self = $_[0];

    sub {

        state $orcid = $self->orcid;
        state $json = $self->json;
        state $response_parser = $self->response_parser;

        my $env = $_[0];

        my $request = Plack::Request->new($env);
        my $session = Plack::Session->new($env);
        my $params  = $request->query_parameters();

        my $auth_sso = $self->get_auth_sso($session);

        #already got here before
        if ( is_hash_ref($auth_sso) ) {

            return $self->redirect_to_authorization();

        }

        my $code = $params->get("code");

        #callback phase
        if ( is_string($code) ) {

            my $error             = $params->get("error");
            my $error_description = $params->get("error_description");

            if ( is_string($error) ) {

                return $self->redirect_to_login( $request ) if $error eq "401";

                $self->set_auth_sso_error( $session, {
                    package    => __PACKAGE__,
                    package_id => $self->id,
                    type => $error,
                    content => $error_description
                });
                return $self->redirect_to_error();

            }

            #access_token returns either a hash (from ORCID), or undef
            my $res = $orcid->access_token(
                grant_type => "authorization_code",
                code => $code
            );

            unless ( $res ) {

                my( $code, $h, $body ) = @{ $orcid->last_error };
                my %headers = %$h;

                if ( index( $headers{"content-type"}, "json" ) >= 0 ) {

                    my $orcid_res = $json->decode( $body );

                    return $self->redirect_to_login( $request ) if $orcid_res->{error} eq "401";

                    $self->set_auth_sso_error( $session, {
                        package    => __PACKAGE__,
                        package_id => $self->id,
                        type => $orcid_res->{error},
                        content => $orcid_res->{error_description}
                    });

                }
                else {

                    $self->set_auth_sso_error( $session, {
                        package    => __PACKAGE__,
                        package_id => $self->id,
                        type => "unknown",
                        content => $body
                    });

                }

                return $self->redirect_to_error();

            }

            #request person data..
            my $res2 = $orcid->person( token => $res->{access_token}, orcid => $res->{orcid} );

            $self->set_auth_sso(
                $session,
                {
                    %{
                        $response_parser->parse( $res, $res2 )
                    },
                    package    => __PACKAGE__,
                    package_id => $self->id,
                    response   => {
                        content => $json->encode( $res ),
                        content_type => "application/json"
                    }
                }
            );

            return $self->redirect_to_authorization();

        }

        #request phase
        else {

            $self->redirect_to_login( $request );

        }
    };
}

1;

=pod

=head1 NAME

Plack::Auth::SSO::ORCID - implementation of Plack::Auth::SSO for ORCID

=head1 SYNOPSIS

    #in your app.psgi

    builder {

        #Register THIS URI in ORCID as a new redirect_uri
        mount "/auth/orcid" => Plack::Auth::SSO::ORCID->new(
            client_id => "APP-1",
            client_secret => "mypassword",
            sandbox => 1,
            uri_base => "http://localhost:5000",
            authorization_path => "/auth/orcid/callback",
            error_path => "/auth/error"
        )->to_app;

        #DO NOT register this uri as new redirect_uri in ORCID
        mount "/auth/orcid/callback" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso = $session->get("auth_sso");

            #not authenticated yet
            unless( $auth_sso ){

                return [ 403, ["Content-Type" => "text/html"], ["forbidden"] ];

            }

            #process auth_sso (white list, roles ..)

            #auth_sso is a hash reference:
            #{
            #    package => "Plack::Auth::SSO::ORCID",
            #    package_id => "Plack::Auth::SSO::ORCID",
            #    response => {
            #        content_type => "application/json",
            #        content => ""{\"orcid\":\"0000-0002-5268-9669\",\"token_type\":\"bearer\",\"name\":\"Nicolas Franck\",\"refresh_token\":\"222222222222\",\"access_token\":\"111111111111\",\"scope\":\"/authenticate\",\"expires_in\":631138518}
            #    },
            #    uid => "0000-0002-5268-9669",
            #    info => {
            #        name => "Nicolas Franck",
            #        first_name => "Nicolas",
            #        last_name => "Franck",
            #        email => "nicolas.franck@nowhere.com",
            #        location => "BE",
            #        description => "my biography",
            #        other_names => [ "njfranck" ],
            #        urls => [ { mysite => "https://mysite.com" } ],
            #        external_identifiers => []
            #    },
            #    extra => {}
            #}

            #you can reuse the "orcid" and "access_token" to get the user profile

            [ 200, ["Content-Type" => "text/html"], ["logged in!"] ];

        };

        mount "/auth/error" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso_error = $session->get("auth_sso_error");

            unless ( $auth_sso_error ) {

                return [ 302, [ Location => $self->uri_for( "/" ) ], [] ];

            }

            [ 200, [ "Content-Type" => "text/plain" ], [
                "Something went wrong. User could not be authenticated against CAS\n",
                "Please report this error:\n",
                $auth_sso_error->{content}
            ]];

        };

    };


=head1 DESCRIPTION

This is an implementation of L<Plack::Auth::SSO> to authenticate against a ORCID (OAuth) server.

It inherits all configuration options from its parent.

Remember that this module only performs these steps:

* redirect to ORCID authorize url

* exchange 1: exchange authorization code for access token ( orcid and name known )

  This delivers a hash containing orcid, name, access_token and a refresh_token.

* exchange 2: exchange access_token for person information

  This delivers a hash containing detailed information.

So we actually retrieved two hashes.

Those steps provide the following information:

* uid: derived from "orcid" from the first hash

* info.name: derived from "name" from the first hash

* other keys in "info" are extracted from the second hash

    * info.first_name: string

    * info.last_name: string

    * info.other_names: array of strings

    * info.email: first primary and verified email

    * info.description: string. Retrieved from "biography".

    * info.location: country code

    * info.url: array of objects

    * info.external_identifiers: array of objects

* extra: both hashes from the first and second call to ORCID are merged. For obvious reasons "orcid" is not present, and neither is "name" because it has a conflicting format between the two responses.

extra.access_token contains a code that conforms to the scope requested (see below).

If you want to request additional information from ORCID

=head1 CONFIG

Register the uri of this application in ORCID as a new redirect_uri.

DO NOT register the authorization_path in ORCID as the redirect_uri!

=over 4

=item client_id

client_id for your application (see developer credentials from ORCID)

=item client_secret

client_secret for your application (see developer credentials from ORCID)

=item sandbox

0|1. Defaults to 0. When set to 1, this api makes use of http://sandbox.orcid.org instead of http://orcid.org.

=item public

0|1. Defaults to 1. 0 means you're using the member API.

=item scope

Requested scope. When not set, the parameter "public" will decide the value:

* public 1 : scope is "/authenticate"

* public 0 : scope is "/read-limited"

Please consult the ORCID to make sure that the parameters "public" and "scope" do not clash.
(e.g. public is 1 and scope is "/read-limited")

=back

=head1 ERRORS

Known ORCID errors are stored in the session key auth_sso_error ( L<Plack::Auth::SSO> ).

"error" becomes "type"

"error_description" becomes "content"

Example:

    {
        package => "Plack::Auth::SSO::ORCID",
        package_id => "Plack::Auth::SSO::ORCID",
        type => "invalid_grant",
        content => "Reused authorization code: abcdefg"

    }

L<https://members.orcid.org/api/resources/error-codes>

when it receives an non json response from ORCID, the type is "unknown", and
content is set to the full return value.

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Plack::Auth::SSO>

=cut
