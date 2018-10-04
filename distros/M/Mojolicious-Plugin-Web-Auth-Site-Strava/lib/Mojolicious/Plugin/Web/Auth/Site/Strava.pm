use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::Strava;
our $VERSION = '0.000001';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has access_token_url => 'https://www.strava.com/oauth/token';
has authorize_url    => 'https://www.strava.com/oauth/authorize';
has response_type    => 'code';
has scope            => 'public';
has user_info        => 1;
has user_info_url    => 'https://www.strava.com/api/v3/athlete';

sub moniker { 'strava' }

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::Strava - Strava OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

    my $client_id     = '9999';
    my $client_secret = 'seekrit';

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Strava',
        key              => $client_id,
        secret           => $client_secret,
        scope       => 'view_private,write',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Strava',
        key         => $client_id,
        secret      => $client_secret,
        scope       => 'view_private,write',
        on_finished => sub {
        my ( $c, $access_token, $access_secret ) = @_;
        ...;
        };

=head1 DESCRIPTION

This module adds L<Strava|https://developers.strava.com/docs/authentication/>
support to L<Mojolicious::Plugin::Web::Auth>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Strava OAuth Plugin for Mojolicious::Plugin::Web::Auth

