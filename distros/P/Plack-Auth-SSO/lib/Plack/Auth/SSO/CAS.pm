package Plack::Auth::SSO::CAS;

use strict;
use utf8;
use feature qw(:5.10);
use Data::Util qw(:check);
use Authen::CAS::Client;
use Moo;
use Plack::Request;
use Plack::Session;
use Plack::Auth::SSO::ResponseParser::CAS;
use XML::LibXML::XPathContext;
use XML::LibXML;

our $VERSION = "0.0133";

with "Plack::Auth::SSO";

has cas_url => (
    is => "ro",
    isa => sub { is_string($_[0]) or die("cas_url should be string"); },
    required => 1
);

sub parse_failure {

    my ( $self, $obj ) = @_;

    my $xpath;

    if ( is_instance( $obj, "XML::LibXML" ) ) {

        $xpath = XML::LibXML::XPathContext->new( $obj );

    }
    else {

        $xpath = XML::LibXML::XPathContext->new(
            XML::LibXML->load_xml( string => $obj )
        );

    }

    $xpath->registerNs( "cas", "http://www.yale.edu/tp/cas" );

    my @nodes = $xpath->find( "/cas:serviceResponse/cas:authenticationFailure" )->get_nodelist();

    if ( @nodes ) {

        return +{
            type => $nodes[0]->findvalue( '@code' ),
            content => $nodes[0]->textContent(),
            package => __PACKAGE__,
            package_id => $self->id()
        };

    }
    else {

        return undef;

    }
}

sub to_app {
    my $self = $_[0];
    sub {

        state $response_parser = Plack::Auth::SSO::ResponseParser::CAS->new();
        state $cas = Authen::CAS::Client->new($self->cas_url());

        my $env = $_[0];

        my $request = Plack::Request->new($env);
        my $session = Plack::Session->new($env);
        my $params  = $request->query_parameters();

        my $auth_sso = $self->get_auth_sso($session);

        #already got here before
        if (is_hash_ref($auth_sso)) {

            return $self->redirect_to_authorization();

        }

        #ticket?
        my $ticket = $params->get("ticket");
        my $request_uri = $request->request_uri();
        my $idx = index( $request_uri, "?" );
        if ( $idx >= 0 ) {

            $request_uri = substr( $request_uri, 0, $idx );

        }
        my $service = $self->uri_for($request_uri);

        if (is_string($ticket)) {

            my $r = $cas->service_validate($service, $ticket);

            if ($r->is_success) {

                my $doc = $r->doc();

                $self->set_auth_sso(
                    $session,
                    {
                        %{
                            $response_parser->parse( $doc )
                        },
                        package    => __PACKAGE__,
                        package_id => $self->id,
                        response   => {
                            content => $doc->toString(),
                            content_type => "text/xml"
                        }
                    }
                );

                return $self->redirect_to_authorization();

            }
            #e.g. "Can't connect to localhost:8443 (certificate verify failed)"
            elsif( $r->is_error() ) {

                $self->set_auth_sso_error( $session, {
                    package    => __PACKAGE__,
                    package_id => $self->id,
                    type => "unknown",
                    content => $r->doc
                });
                return $self->redirect_to_error();

            }
            #$r->is_failure() -> authenticationFailure: return to authentication url
            else {

                my $failure = $self->parse_failure( $r->doc );

                if ( $failure->{type} ne "INVALID_TICKET" ) {


                    $self->set_auth_sso_error( $session, $failure );
                    return $self->redirect_to_error();

                }

            }

        }

        #no ticket or ticket validation failed
        my $login_url = $cas->login_url($service)->as_string;

        [302, [Location => $login_url], []];

    };
}

1;

=pod

=head1 NAME

Plack::Auth::SSO::CAS - implementation of Plack::Auth::SSO for CAS

=head1 SYNOPSIS

    #in your app.psgi

    builder {

        mount "/auth/cas" => Plack::Auth::SSO::CAS->new(

            session_key => "auth_sso",
            uri_base => "http://localhost:5000",
            authorization_path => "/auth/cas/callback",
            error_path => "/auth/error"

        )->to_app;

        mount "/auth/cas/callback" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso = $session->get("auth_sso");

            #not authenticated yet
            unless($auth_sso){

                return [403,["Content-Type" => "text/html"],["forbidden"]];

            }

            #process auth_sso (white list, roles ..)

            [200,["Content-Type" => "text/html"],["logged in!"]];

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

This is an implementation of L<Plack::Auth::SSO> to authenticate against a CAS server.

It inherits all configuration options from its parent.

=head1 CONFIG

=over 4

=item cas_url

base url of the CAS service

=back

=head1 ERRORS

Cf. L<https://apereo.github.io/cas/4.2.x/protocol/CAS-Protocol-Specification.html#253-error-codes>

When a ticket arrives, it is checked against the CAS Server. This can lead to the following situations:

* an error occurs. This means that the CAS server is down, or returned an unexpected response. The error type is "unknown":

    {
        package => "Plack::Auth::SSO::CAS",
        package_id => "Plack::Auth::SSO::CAS",
        type => "unknown",
        content => "server could not complete request"
    }


* the ticket is rejected by the CAS server. When the authentication code is "TICKET_INVALID" the user is redirected back
to the CAS server. In other cases the type equals the authentication code, and content equals the error description.

    {
        package => "Plack::Auth::SSO::CAS",
        package_id => "Plack::Auth::SSO::CAS",
        type => "INVALID_SERVICE",
        content => "invalid service"
    }


=head1 TODO

* add an option to ignore validation of the SSL certificate of the CAS Service? For now you should set the environment like this:

    export SSL_VERIFY_NONE=1
    export PERL_LWP_SSL_VERIFY_HOSTNAME=0

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Plack::Auth::SSO>

=cut
