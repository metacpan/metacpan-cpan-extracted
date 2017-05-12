use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::LinkedIn;
$Mojolicious::Plugin::Web::Auth::Site::LinkedIn::VERSION = '0.03';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has access_token_url => 'https://www.linkedin.com/oauth/v2/accessToken';
has authorize_url    => 'https://www.linkedin.com/oauth/v2/authorization';
has response_type    => 'code';
has user_info        => 1;
has user_info_url    => 'https://api.linkedin.com/v1/people/~:(id,email-address,first-name,last-name,formatted-name,headline,summary,positions,picture-url,specialties,num-connections,api-standard-profile-request)?format=json';
has authorize_header => 'Bearer';

sub moniker {'linkedin'}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::LinkedIn - LinkedIn OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Web::Auth',
        module      => 'LinkedIn',
        key         => 'LinkedIn consumer key',
        secret      => 'LinkedIn consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $user_info ) = @_;
            ...
        },
        on_error => sub {
            my ( $c, $error ) = @_;
            ...
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'LinkedIn',
        key         => 'LinkedIn consumer key',
        secret      => 'LinkedIn consumer secret',
        on_finished => sub {
            my ( $c, $access_token, $user_info ) = @_;
            ...
        };


    # default authentication endpoint: /auth/linkedin/authenticate
    # default callback endpoint: /auth/linkedin/callback

=head1 DESCRIPTION

This module adds L<LinkedIn|https://developer.linkedin.com/docs/rest-api/> support to
L<Mojolicious::Plugin::Web::Auth>.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Vikas N Kumar.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: LinkedIn OAuth Plugin for Mojolicious::Plugin::Web::Auth

