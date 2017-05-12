###########################################
package OAuth::Cmdline::Spotify;
###########################################
use strict;
use warnings;
use MIME::Base64;

use base qw( OAuth::Cmdline );

###########################################
sub site {
###########################################
    return "spotify";
}

###########################################
sub token_refresh_authorization_header {
###########################################
    my( $self ) = @_;

    my $cache = $self->cache_read();

    my $auth_header = 
        "Basic " . 
        encode_base64( 
            "$cache->{ client_id }:$cache->{ client_secret }", 
            "" # no line break!!
        );
    return ( "Authorization" => $auth_header );
}

1;

__END__

=head1 NAME

OAuth::Cmdline::Spotify - Spotify-specific OAuth oddities

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::Spotify->new( );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides methods of C<OAuth::Cmdline> to comply with
Spotify's Web API.

=head1 LEGALESE

Copyright 2014 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2014, Mike Schilli <cpan@perlmeister.com>
