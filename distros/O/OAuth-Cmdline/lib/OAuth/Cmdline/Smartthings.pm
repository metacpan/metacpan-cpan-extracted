###########################################
package OAuth::Cmdline::Smartthings;
###########################################
use strict;
use warnings;
use MIME::Base64;
use Moo;

extends "OAuth::Cmdline";

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Smartthings-specific OAuth oddities

sub BUILD {
    my( $self ) = @_;

    if( !defined $self->base_uri ) {
          # default to US
        $self->base_uri( "https://graph-na02-useast1.api.smartthings.com" );
    }

    $self->login_uri( $self->base_uri . "/oauth/authorize" );
    $self->token_uri( $self->base_uri . "/oauth/token" );

    $self->client_init_conf_check( $self->base_uri );
}

###########################################
sub site {
###########################################
    return "smartthings";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::Smartthings - Smartthings-specific OAuth oddities

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::Smartthings->new( );
    my $json = 
        $oauth->http_get( $oauth->base_uri . "/api/smartapps/endpoints" );

=head1 DESCRIPTION

This class provides the necessary glue to interact with Smartthings
Web API. A short tutorial on how to use the API can be found here:

    http://docs.smartthings.com/en/latest/smartapp-web-services-developers-guide/tutorial-part1.html

=head1 REGISTRATION

To register with Smartthings, go to

    https://graph-na02-useast1.api.smartthings.com (US)
    https://graph-eu01-euwest1.api.smartthings.com (UK)

with your browser and create a new app, enable the "OAuth" section, then
cut-and-paste the client ID and client secret into 
your C<~/.smartthings.yml> file:

    client_id: xxx
    client_secret: yyy

Also use

    http://localhost:8082/callback

as a "redirect URI" (not optionial as the label would suggest) and then
run C<eg/smartthings-token-init> (in this distribution) and point your 
browser to 

    http://localhost:8082

Then click the login link and follow the flow.

=head1 Web Client Use

After registration and initialization (see above), the local 
C<~/.smartthings.yml> file should contain an access token. With
this in place, all that is required to obtain the endpoint of
the specific Smartthings app installation and fetch the status of
all switches to which the user has granted access to is the following code:

    use OAuth::Cmdline::Smartthings;
    use JSON qw( from_json );

    my $oauth = OAuth::Cmdline::Smartthings->new;

    my $json = $oauth->http_get( 
        $oauth->base_uri . "/api/smartapps/endpoints" );

    if( !defined $json ) {
        die "Can't get endpoints";
    }

    my $uri = from_json( $json )->[ 0 ]->{ uri } . "/switches";
    my $data = $oauth->http_get( $uri );
    print "$data\n";

will print something like

    [{"name":"Outlet","value":"on"}]

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
