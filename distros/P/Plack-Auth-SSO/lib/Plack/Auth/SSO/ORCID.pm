package Plack::Auth::SSO::ORCID;

use strict;
use utf8;
use Data::Util qw(:check);
use Moo;
use Plack::Request;
use Plack::Session;
use URI;
use LWP::UserAgent;
use WWW::ORCID;
use JSON;
use Plack::Auth::SSO::ResponseParser::ORCID;

our $VERSION = "0.0132";

with "Plack::Auth::SSO";

has sandbox => (
    is => "ro",
    required => 0
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
    is => "ro",
    lazy => 1,
    builder => "_build_orcid",
    init_arg => undef
);
has json => (
    is      => "ro",
    lazy    => 1,
    default => sub { JSON->new()->utf8(1); },
    init_arg => undef
);
has response_parser => (
    is => "ro",
    lazy => 1,
    builder => "_build_response_parser",
    init_arg => undef
);

sub _build_orcid {

    my $self = $_[0];

    WWW::ORCID->new(
        client_id => $self->client_id(),
        client_secret => $self->client_secret(),
        sandbox => $self->sandbox(),
        public => 1,
        transport => "LWP"
    );

}
sub _build_response_parser {
    Plack::Auth::SSO::ResponseParser::ORCID->new();
}

sub to_app {
    my $self = $_[0];

    sub {

        my $env = $_[0];

        my $request = Plack::Request->new($env);
        my $session = Plack::Session->new($env);
        my $params  = $request->query_parameters();

        my $auth_sso = $self->get_auth_sso($session);

        #already got here before
        if ( is_hash_ref($auth_sso) ) {

            return [
                302, [ Location => $self->uri_for($self->authorization_path) ],
                []
            ];

        }

        my $callback = $params->get("_callback");

        #callback phase
        if ( is_string($callback) ) {

            my $error             = $params->get("error");
            my $error_description = $params->get("error_description");

            if ( is_string($error) ) {

                return [
                    500, [ "Content-Type" => "text/html" ],
                    [ $error_description ]
                ];

            }

            #access_token returns either a hash (from ORCID), or undef
            my $res = $self->orcid()->access_token(
                grant_type => "authorization_code",
                code => $params->get("code")
            );

            #error is always a PSGI Response
            unless ( $res ) {

                return $self->orcid()->last_error();

            }

            $self->set_auth_sso(
                $session,
                {
                    %{
                        $self->response_parser()->parse( $res )
                    },
                    package    => __PACKAGE__,
                    package_id => $self->id,
                    response   => {
                        content => $self->json()->encode( $res ),
                        content_type => "application/json"
                    }
                }
            );

            return [
                302, [ Location => $self->uri_for($self->authorization_path) ],
                []
            ];
        }

        #request phase
        else {

            my $request_uri = $request->request_uri();
            my $idx = index( $request_uri, "?" );
            if ( $idx >= 0 ) {

                $request_uri = substr( $request_uri, 0, $idx );

            }

            my $redirect_uri = URI->new( $self->uri_for($request_uri) );
            $redirect_uri->query_form({ _callback => "true" });

            my $auth_uri = $self->orcid()->authorize_url(
                show_login => "true",
                scope => "/authenticate",
                response_type => "code",
                redirect_uri => $redirect_uri->as_string()
            );

            [ 302, [ Location => $auth_uri ], [] ];

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
            authorization_path => "/auth/orcid/callback"
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
            #        name => "Nicolas Franck"
            #    },
            #    extra => {}
            #}

            #you can reuse the "orcid" and "access_token" to get the user profile

            [ 200, ["Content-Type" => "text/html"], ["logged in!"] ];

        };

    };


=head1 DESCRIPTION

This is an implementation of L<Plack::Auth::SSO> to authenticate against a ORCID (OAuth) server.

It inherits all configuration options from its parent.

=head1 CONFIG

Register the uri of this application in ORCID as a new redirect_uri.

DO NOT register the authorization_path in ORCID as the redirect_uri!

=over 4

=item client_id

client_id for your application (see developer credentials from ORCID)

=item client_secret

client_secret for your application (see developer credentials from ORCID)

=item sandbox

0|1. Defaults to "0". When set to "1", this api makes use of http://sandbox.orcid.org instead of http://orcid.org.

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Plack::Auth::SSO>

=cut
