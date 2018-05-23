package Plack::Auth::SSO;

use strict;
use utf8;
use Data::Util qw(:check);
use Moo::Role;

our $VERSION = "0.0135";

has session_key => (
    is       => "ro",
    isa      => sub { is_string($_[0]) or die("session_key should be string"); },
    lazy     => 1,
    default  => sub { "auth_sso" },
    required => 1
);
has authorization_path => (
    is       => "ro",
    isa      => sub { is_string($_[0]) or die("authorization_path should be string"); },
    lazy     => 1,
    default  => sub { "/"; },
    required => 1
);
has error_path => (
    is => "lazy"
);
has id => (
    is => "ro",
    lazy => 1,
    builder => "_build_id"
);
has uri_base => (
    is       => "ro",
    isa      => sub { is_string($_[0]) or die("uri_base should be string"); },
    required => 1,
    default  => sub { "http://localhost:5000"; }
);

requires "to_app";

sub _build_error_path {

    $_[0]->authorization_path;

}

sub redirect_to_authorization {

    my $self = $_[0];

    [ 302, [ Location => $self->uri_for( $self->authorization_path ) ], [] ];

}

sub redirect_to_error {

    my $self = $_[0];

    [ 302, [ Location => $self->uri_for( $self->error_path ) ], [] ];
}

sub uri_for {
    my ($self, $path) = @_;
    $self->uri_base() . $path;
}

sub _build_id {
    ref($_[0]);
}

#check if $env->{psgix.session} is stored Plack::Session->session
sub _check_plack_session {
    defined($_[0]->session) or die("Plack::Auth::SSO requires a Plack::Session");
}

sub get_auth_sso {
    my ($self, $session) = @_;
    _check_plack_session($session);
    $session->get($self->session_key);
}

sub set_auth_sso {
    my ($self, $session, $value) = @_;
    _check_plack_session($session);
    $session->set($self->session_key, $value);
}

sub get_auth_sso_error {
    my ($self, $session) = @_;
    _check_plack_session($session);
    $session->get($self->session_key . "_error" );
}

sub set_auth_sso_error {
    my ($self, $session, $value) = @_;
    _check_plack_session($session);
    $session->set($self->session_key . "_error", $value);
}

1;

=pod

=head1 NAME

Plack::Auth::SSO - role for Single Sign On (SSO) authentication

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Plack-Auth-SSO.svg?branch=master)](https://travis-ci.org/LibreCat/Plack-Auth-SSO)
[![Coverage](https://coveralls.io/repos/LibreCat/Plack-Auth-SSO/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Plack-Auth-SSO)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO.png)](http://cpants.cpanauthors.org/dist/Plack-Auth-SSO)

=end markdown

=head1 IMPLEMENTATIONS

* SSO for Central Authentication System (CAS): L<Plack::Auth::SSO::CAS>

* SSO for ORCID: L<Plack::Auth::SSO::ORCID>

* SSO for Shibboleth: L<Plack::Auth::SSO::Shibboleth>

=head1 SYNOPSIS

    package MySSOAuth;

    use Moo;
    use Data::Util qw(:check);

    with "Plack::Auth::SSO";

    sub to_app {

        my $self = shift;

        sub {

            my $env = shift;
            my $request = Plack::Request->new($env);
            my $session = Plack::Session->new($env);

            #did this app already authenticate you?
            #implementation of Plack::Auth::SSO should write hash to session key,
            #configured by "session_key"
            my $auth_sso = $self->get_auth_sso($session);

            #already authenticated: what are you doing here?
            if( is_hash_ref($auth_sso) ){

                return [ 302, [ Location => $self->uri_for($self->authorization_path) ], [] ];

            }

            #not authenticated: do your internal work
            #..

            #authentication done in external application code, but here something went wrong..
            unless ( $ok ) {

                #error is set in auth_sso_error..
                $self->set_auth_sso_error(
                    $session,
                    {
                        package => __PACKAGE__,
                        package_id => $self->id,
                        type => "connection_failed",
                        content => ""
                    }
                );

                #user is redirected to error_path
                return [ 302, [ Location => $self->uri_for($self->error_path) ], [] ];

            }

            #everything ok: set auth_sso
            $self->set_auth_sso(
                $session,
                {
                    package => __PACKAGE__,
                    package_id => $self->id,
                    response => {
                        content => "Long response from external SSO application",
                        content_type => "text/xml"
                    },
                    uid => "<uid>",
                    info => {
                        attr1 => "attr1",
                        attr2 => "attr2"
                    },
                    extra => {
                        field1 => "field1"
                    }
                }
            );

            #redirect to other application for authorization:
            return [ 302, [ Location => $self->uri_for($self->authorization_path) ], [] ];

        };
    }

    1;


    #in your app.psgi

    builder {

        mount "/auth/myssoauth" => MySSOAuth->new(

            session_key => "auth_sso",
            authorization_path => "/auth/myssoauth/callback",
            uri_base => "http://localhost:5001",
            error_path => "/auth/error"

        )->to_app;

        mount "/auth/myssoauth/callback" => sub {

            my $env = shift;
            my $session = Plack::Session->new($env);
            my $auth_sso = $session->get("auth_sso");

            #not authenticated yet
            unless($auth_sso){

                return [ 403, ["Content-Type" => "text/html"], ["forbidden"] ];

            }

            #process auth_sso (white list, roles ..)

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
                $auth_sso_error->{content}
            ]];

        };

    };

=head1 DESCRIPTION

This is a Moo::Role for all Single Sign On Authentication packages. It requires
C<to_app> method, that returns a valid Plack application

An implementation is expected is to do all communication with the external
SSO application (e.g. CAS). When it succeeds, it should save the response
from the external service in the session, and redirect to the authorization
url (see below).

The authorization route must pick up the response from the session,
and log the user in.

This package requires you to use Plack Sessions.

=head1 CONFIG

=over 4

=item session_key

When authentication succeeds, the implementation saves the response
from the SSO application in this session key, together with extra information.

The response should look like this:

    {
        package => "<package-name>",
        package_id => "<package-id>",
        response => {
            content => "Long response from external SSO application like CAS",
            content_type => "<mime-type>"
        },
        uid => "<uid-in-external-app>",
        info => {
            attr1 => "attr1",
            attr2 => "attr2"
        },
        extra => {
            field1 => "field1"
        }
    }

This is usefull for several reasons:

    * the authorization application can distinguish between authenticated and not authenticated users

    * it can pick up the saved response from the session

    * it can lookup a user in an internal database, matching on the provided "uid" from the external service.

    * the key "package" tells which package authenticated the user; so the application can do an appropriate lookup based on this information.

    * the key "package_id" defaults to the package name, but is configurable. This is usefull when you have several external services of the same type,
      and your application wants to distinguish between them.

    * the original response is stored as text, along with the content type.

    * other attributes stored in the hash reference "info". It is up to the implementing package whether it should only used attributes as pushed during
      the authentication step (like in CAS), or do an extra lookup.

    * "extra" should be used to store request information.
        e.g. "ORCID" gives a "token".
        e.g. "Shibboleth" supplies the "Shib-Identity-Provider".

=item authorization_path

(internal) path of the authorization route. This path will be prepended by "uri_base" to
create the full url.

When authentication succeeds, this application should redirect you here

=item error_path

(internal) path of the error route. This path will be prepended by "uri_base" to
create the full url.

When authentication fails, this application should redirect you here

If not set, it has the same value as the authorizaton_path. In that case make sure that you also

check for auth_sso_error in your authorization route.

The implementor should expect this in the session key "auth_sso_error" ( "_error" is appended to the configured session_key ):

    {
        package => "Plack::Auth::SSO::TYPE",
        package_id => "Plack::Auth::SSO::TYPE",
        type => "my-error-type",
        content => "Something went terribly wrong!"
    }

Error types should be documented by the implementor.

=item uri_for( path )

method that prepends your path with "uri_base".

=item id

identifier of the authentication module. Defaults to the package name.
This is handy when using multiple SSO instances, and you need to known
exactly which package authenticated the user.

This is stored in "auth_sso" as "package_id".

=item uri_base

base url of the Plack application

=back

=head1 METHODS

=head2 to_app

returns a Plack application

This must be implemented by subclasses

=head2 get_auth_sso($plack_session)

get saved SSO response from your session

=head2 set_auth_sso($plack_session,$hash)

save SSO response to your session

$hash should be a hash ref, and look like this:

    {
        package => __PACKAGE__,
        package_id => __PACKAGE__ ,
        response => {
            content => "Long response from external SSO application like CAS",
            content_type => "<mime-type>",
        },
        uid => "<uid>",
        info => {},
        extra => {}
    }

=head2 get_auth_sso_error($plack_session)

get saved SSO error response from your session

=head2 set_auth_sso_error($plack_session,$hash)

save SSO error response to your session

$hash should be a hash ref, and look like this:

    {
        package => __PACKAGE__,
        package_id => __PACKAGE__ ,
        type => "my-type",
        content => "my-content"
    }

=head1 EXAMPLES

See examples/app1:

    #copy example config to required location
    $ cp examples/catmandu.yml.example examples/catmandu.yml

    #edit config
    $ vim examples/catmandu.yml

    #start plack application
    plackup examples/app1.pl

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Plack::Auth::SSO::CAS>,
L<Plack::Auth::SSO::ORCID>
L<Plack::Auth::SSO::Shibboleth>

=cut
