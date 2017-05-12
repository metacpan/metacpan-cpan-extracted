use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::Spotify;
$Mojolicious::Plugin::Web::Auth::Site::Spotify::VERSION = '0.000001';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has access_token_url => 'https://accounts.spotify.com/api/token';
has authorize_url    => 'https://accounts.spotify.com/authorize';
has response_type    => 'code';
has user_info        => 1;
has user_info_url    => 'https://api.spotify.com/v1/me';

sub moniker {'spotify'}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::Spotify - Spotify OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Web::Auth',
        module      => 'Spotify',
        key         => 'Spotify consumer key',
        secret      => 'Spotify consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Spotify',
        key         => 'Spotify consumer key',
        secret      => 'Spotify consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...
        };


    # default authentication endpoint: /auth/spotify/authenticate
    # default callback endpoint: /auth/spotify/callback

=head1 DESCRIPTION

This module adds L<Spotify|https://developer.spotify.com/web-api/> support to
L<Mojolicious::Plugin::Web::Auth>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Spotify OAuth Plugin for Mojolicious::Plugin::Web::Auth

