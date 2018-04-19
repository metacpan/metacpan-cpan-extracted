package Plack::Auth::SSO::Mock;

use strict;
use utf8;
use Moo;
use Data::Util qw(:check);
use Plack::Session;
use Plack::Request;

with "Plack::Auth::SSO";

sub to_app {

    my $self = shift;

    sub {

        my $env = shift;

        my $session = Plack::Session->new($env);
        my $request = Plack::Request->new($env);
        my $params = $request->parameters();

        my $auth_sso = $self->get_auth_sso($session);

        if( is_hash_ref($auth_sso) ){

            return $self->redirect_to_authorization();

        }

        my $code = $params->get( "code" );

        unless ( is_string( $code ) ) {

            return [
                302, [ Location => "https://mock.sso.com" ], []
            ];

        }

        if ( $code ne "authenticated" ) {

            $self->set_auth_sso_error( $session, +{
                package => __PACKAGE__,
                package_id => $self->id,
                type => "unauthorized",
                content => "unauthorized"
            } );
            return $self->redirect_to_error();

        }

        $self->set_auth_sso(
            $session,
            {
                package => __PACKAGE__,
                package_id => $self->id,
                response => {
                    content => "Long response from external SSO application",
                    content_type => "text/plain"
                },
                uid => "username",
                info => {
                    attr1 => "attr1",
                    attr2 => "attr2"
                },
                extra => {
                    field1 => "field1"
                }
            }
        );

        [ 302, [ Location => $self->uri_for($self->authorization_path) ], [] ];

    };
}

1;
