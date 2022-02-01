###########################################
package OAuth::Cmdline::Automatic;
###########################################
use strict;
use warnings;
use MIME::Base64;

use base qw( OAuth::Cmdline );

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Automatic.com-specific OAuth oddities

###########################################
sub site {
###########################################
    return "automatic";
}

###########################################
sub redirect_uri {
###########################################
    my( $self ) = @_;

    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::Automatic - Automatic.com-specific OAuth oddities

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::Automatic->new( );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides methods of C<OAuth::Cmdline> because 
Automatic.com's Web API deviates from standard OAuth.

Automatic.com deviates from the standard OAuth protocol in two significant
ways listed below.

=head2 No Automatic.com support for redirect URL

Since Automatic doesn't allow a C<redirect_uri> parameter in the initial
token dance move, make sure to set the field C<"OAuth Redirect URL">
in the new app registration form on 
I<https://developer.automatic.com/my-apps> to

    http://localhost:8082/callback

which is where C<eg/automatic-token-init> is waiting for the response
from the authentication server. Other OAuth consumers let you specify 
a redirect URL in the request, which is more convenient.

=head2 No Automatic.com support for a refresh token

Other OAuth consumers return a refresh_token alongside with the access_token,
so if the access_token expires, you can fetch a new one by simply providing
the saved refresh token. Automatic.com, however, upon successful
user authorization, only sends back an access_token without a refresh_token.
Since their access_token has an expiration time of one year, it's not
an immediate problem but could prove to be largely inconvenient for the
user when that time comes and they have to re-grant access for the app.

=head1 EXAMPLE

After registering the app (note the first item above), put the values
for client_id and client_secret in YAML format 
into C<.automatic.yml> in your home directory:

    # ~/.automatic.yml
    client_id: XXXXX
    client_secret: YYYY

Then run the

    eg/automatic-token-init

script included in this distribution and
point your browser to C<http://localhost:8082>. Then follow the
authentication flow until redirected back to localhost. By then,
the script will have updated the file C<~/.automatic.yml> to
contain the access token needed for further authenticated calls. 

After that, any script like the following can access your Automatic
data from the server:

    use OAuth::Cmdline::Automatic;
    use LWP::UserAgent;
    use JSON qw( from_json );

    my $oauth = OAuth::Cmdline::Automatic->new();
    my $ua = LWP::UserAgent->new();

    my $resp = $ua->get( "https://api.automatic.com/device/",
        $oauth->authorization_headers );

    if( $resp->is_error ) {
        die $resp->message;
    }

    my $data = from_json( $resp->decoded_content );

    for my $device ( @{ $data->{ results } } ) {
        printf "%s-v%d %s\n",
          $device->{ id },
          $device->{ version },
          $device->{ url };
    }

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
