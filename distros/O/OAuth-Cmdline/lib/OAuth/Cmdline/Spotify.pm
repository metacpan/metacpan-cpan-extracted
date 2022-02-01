###########################################
package OAuth::Cmdline::Spotify;
###########################################
use strict;
use warnings;
use MIME::Base64;

use base qw( OAuth::Cmdline );

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Spotify-specific OAuth oddities

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

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::Spotify - Spotify-specific OAuth oddities

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::Spotify->new( );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides methods of C<OAuth::Cmdline> to comply with
Spotify's Web API.

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
