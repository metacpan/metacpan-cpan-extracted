use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::Fitbit;
$Mojolicious::Plugin::Web::Auth::Site::Fitbit::VERSION = '0.000002';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has authorize_header => 'Bearer ';
has response_type    => 'code';
has user_info        => 1;
has user_info_url    => 'https://api.fitbit.com/1/user/-/profile.json';

sub moniker { 'fitbit' }

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::Fitbit - Fitbit OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.000002

=head1 SYNOPSIS

    use URI::FromHash qw( uri );
    my $key = 'foo';
    my $secret = 'seekrit';

    my $access_token_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'api.fitbit.com',
        path     => 'oauth2/token',
    );

    my $authorize_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'www.fitbit.com',
        path     => 'oauth2/authorize',
    );

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Fitbit',
        authorize_url    => $authorize_url,
        access_token_url => $access_token_url,
        key              => $key,
        scope =>
            'activity heartrate location nutrition profile sleep social weight',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module           => 'Fitbit',
        authorize_url    => $authorize_url,
        access_token_url => $access_token_url,
        key              => $key,
        scope =>
        'activity heartrate location nutrition profile sleep social weight',
        on_finished => sub {
        my ( $c, $access_token, $access_secret ) = @_;
        ...;
        };

    # default authentication endpoint: /auth/fitbit/authenticate
    # default callback endpoint: /auth/fitbit/callback

=head1 DESCRIPTION

This module adds L<Fitbit|https://dev.fitbit.com/docs/> support to
L<Mojolicious::Plugin::Web::Auth>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Fitbit OAuth Plugin for Mojolicious::Plugin::Web::Auth

