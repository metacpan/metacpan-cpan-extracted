use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::Runkeeper;
$Mojolicious::Plugin::Web::Auth::Site::Runkeeper::VERSION = '0.000001';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has access_token_url => 'https://runkeeper.com/apps/token';
has authorize_url    => 'https://runkeeper.com/apps/authorize';
has response_type    => 'code';
has user_info        => 1;
has user_info_url    => 'https://api.runkeeper.com/user';

sub moniker { 'runkeeper' }

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::Runkeeper - Runkeeper OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Web::Auth',
        module      => 'Runkeeper',
        key         => 'Runkeeper consumer key',
        secret      => 'Runkeeper consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Runkeeper',
        key         => 'Runkeeper consumer key',
        secret      => 'Runkeeper consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $access_secret ) = @_;
            ...
        };


    # default authentication endpoint: /auth/runkeeper/authenticate
    # default callback endpoint: /auth/runkeeper/callback

=head1 DESCRIPTION

This module adds L<Runkeeper|https://runkeeper.com/developer/healthgraph/overview> support to
L<Mojolicious::Plugin::Web::Auth>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Runkeeper OAuth Plugin for Mojolicious::Plugin::Web::Auth

