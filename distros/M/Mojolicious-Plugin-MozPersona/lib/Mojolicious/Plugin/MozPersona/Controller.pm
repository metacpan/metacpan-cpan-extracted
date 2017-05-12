use strict;
use warnings;

package Mojolicious::Plugin::MozPersona::Controller;
$Mojolicious::Plugin::MozPersona::Controller::VERSION = '0.05';
# ABSTRACT: Default implementation for server side functions for "Persona" authentication.

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(decode_json);

use Mozilla::CA qw();
use Data::Dumper;


sub signin {
    my $self = shift;

    $ENV{'MOJO_CA_FILE'} = Mozilla::CA::SSL_ca_file();

    my $persona_response = '';
    my $result = '';

    eval {
        $persona_response = $self->ua->post(
           $self->stash('_persona_service')
           => form => {
                assertion => $self->param('assertion'),
                audience  => $self->stash('_persona_audience'), 
           }
        )->res;

        $result = decode_json $persona_response->body;
    };

    if ($@) {
        $self->app->log->error("Error verifying assertion with IdP: $@");
        $self->render( json => { signin => Mojo::JSON->false } );
    }
    elsif ( ! ( $result->{'status'} eq "okay" or $result->{'status'} eq "failure" ) ) {
        require Data::Dumper;
        $self->app->log->error("Invalid response from IdP: " . Data::Dumper::Dumper($result));
    }
    else {
        if ( $self->app->log->is_debug ) {
            require Data::Dumper;
            $self->app->log->debug("Successfully verified user assertion with IdP: " . Data::Dumper::Dumper($result));
        }
        $self->session->{_persona} = $result;
        $self->render( json => { signin => Mojo::JSON->true, result => $result } );
    }
}


sub signout {
    my $self = shift;
    delete $self->session->{_persona};
    $self->render( json => { signout => Mojo::JSON->true } );
}


sub js {
    my $self = shift;
    my %c = %{ $self->stash('_persona_conf') };

    foreach my $k ( keys %c ) {
        $self->stash( $k => $c{$k} );
    }

    # set empty value for optional config
    foreach my $w ( qw( siteLogo privacyPolicy termsOfService returnTo oncancel ) ) {
        $self->stash( $w => '' ) unless $c{$w};
    }

    $self->res->headers->content_type('text/javascript');

    my ( $tName, $tFormat, $tHandler ) = split( /\./, $c{'localJsTpl'} );
    $tName    = 'persona_local_js' unless defined($tName)    and $tName;
    $tFormat  = 'txt'              unless defined($tFormat)  and $tFormat;
    $tHandler = 'ep'               unless defined($tHandler) and $tHandler;

    $self->render( $tName, format => $tFormat, handler => $tHandler );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::MozPersona::Controller - Default implementation for server side functions for "Persona" authentication.

=head1 VERSION

version 0.05

=head1 DESCRIPTION

When registering the "MozPersona" plugin you may specify a configuration
param C<namespace> which must contain the name of a module that inherits
from L<Mojolicious::Controller>.

This module must provide (directly or via inheritance) implementations
of three methods: C<signin>, C<signout> and C<js>.

=head1 NAME

Mojolicious::Plugin::MozPersona::Controller - Default implementation for server side functions for "Persona" authentication.

B<BEWARE: THIS IS AN ALPHA RELEASE!> - It is quite possible that there will
be incompatible changes before the API and the functionality of this 
plugin are declared stable. Use at your own risk.
On the other hand that also means that now is the right time to tell me
what should be changed to make this module more usable and useful!

=head1 METHODS

=head2 signin

This method gets called via an XMLHttpRequest after a user signed in with
the identity provider - i.e. after the IdP created and stored an association
between the user and the given audience (the Mojolicious app).

It receives a controller object which has access to the authentication 
assertion of the IdP as request param C<assertion>. 
It also has access to the configuration values "audience" (as 
C<_persona_audience>) and "service" (as C<_persona_service>) via the stash.

It is responsible for sending a request containing the assertion and the
audience to the service, thereby verifying the assertion token and 
retrieves a JSON response which tells if the assertion was verified,
until when it is valid and what email address was associated with the user.

It should update the Mojolicious session accordingly. The default
implementation in this module does so by saving the IdP response in the
C<_persona> key in the session). 

Please note that the session is updated with the IdP response no matter if
the authentication and verification actually succeeded! Simply checking
for the existence of C<session->{_persona}> is B<NOT> sufficient - you need
to check the value of the C<status> element in the response of the Persona IdP.
Setting the "_persona" data anyway allows the app to provide a failure 
message for subsequent requests by the user.

This method should return a status info to the browser: The default implementation
in this module returns C<"success":false> if there was an error while
processing the request and C<"success":true> otherwise.

C<"success":true>, however, does B<NOT> indicate that the user was successfully
authenticated! Again, you have to refer to the message returned by the IdP which is also
included in the response and contains either C<"status":"okay"> or C<"status":"failure">.

E.g. if the user successfully signed in and the verification succeeded the JSON
message returned is:

  {
    "success": true,
    "result": {
      "status"  : "okay",
      "email"   : "somebody@example.org",
      "audience": "http:\/\/127.0.0.1:3000\/",
      "issuer"  : "login.persona.org",
      "expires" : 1358864866835
    }
  }

Otherwise if the message exchange was successful but IdP could not verify the
authentication of the user the JSON message looks like this:

  {
    "success": true,
    "result": {
      "status": "failure",
      "reason": "...server hiccup..."
    }
  }

And if the whole process failed the JSON message simply is

  {
    "success": false
  }

For further info please refer to L<https://developer.mozilla.org/en-US/docs/Persona>, 
L<https://developer.mozilla.org/en-US/docs/Persona/Quick_Setup> and 
L<https://developer.mozilla.org/en-US/docs/Persona/Remote_Verification_API>.

=head2 signout

This method gets called via an XMLHttpRequest after a user successfully
signed out with the identity provider.

It receives a controller object which has access to the Mojolicious session.

It should remove the authentication information from the sessions. The
default implementation in this module does so by simply deleting the key
"_persona" from the session hash.

It should return a status info to the browser. Since all that this default
implementation of the method does is delete the Persona info from the 
session it always returns C<{"signout":true}>.

=head2 js

This method gets called from the browser to provide a JavaScript document
that registers C<click> handlers for the login and logout button. The
JavaScript code also registers the appropriate callback functions with
the C<watch> method of the browsers C<navigator.id> API.
See also L<https://developer.mozilla.org/en-US/docs/DOM/navigator.id>.

The method retrieves the complete config of the Mojolicious::Plugin::MozPersona
module as a hash in the stash slot C<_persona_conf>.

Using this info it renders the template specified as C<localJsTpl> in
the configuration.

=head1 SEE ALSO

L<Mojolicious::Plugin::MozPersona>,
L<https://developer.mozilla.org/en-US/docs/Persona>,
L<Mojolicious>.

=head1 AUTHORS

=over 4

=item *

Heiko Jansen <hjansen@cpan.org>

=item *

Moritz Lenz <moritz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
