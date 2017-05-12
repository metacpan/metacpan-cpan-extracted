use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth::Site::Reddit;
$Mojolicious::Plugin::Web::Auth::Site::Reddit::VERSION = '0.000004';
use Mojo::Base qw/Mojolicious::Plugin::Web::Auth::OAuth2/;

has access_token_url => 'https://www.reddit.com/api/v1/access_token';
has authorize_header => 'bearer ';
has authorize_url    => 'https://www.reddit.com/api/v1/authorize';
has response_type    => 'code';
has user_info        => 1;
has user_info_url    => 'https://oauth.reddit.com/api/v1/me';

sub moniker { 'reddit' }

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Web::Auth::Site::Reddit - Reddit OAuth Plugin for Mojolicious::Plugin::Web::Auth

=head1 VERSION

version 0.000004

=head1 SYNOPSIS

    use URI::FromHash qw( uri );
    my $key = 'foo';
    my $secret = 'seekrit';

    my $access_token_url = uri(
        scheme   => 'https',
        username => $key,
        password => $secret,
        host     => 'www.reddit.com',
        path     => '/api/v1/access_token',
    );

    my $scope = 'identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits,privatemessages,read,report,save,submit,subscribe,vote,wikiedit,wikiread';

    # Mojolicious
    $self->plugin(
        'Web::Auth',
        module           => 'Reddit',
        access_token_url => $access_token_url,
        authorize_url =>
            'https://www.reddit.com/api/v1/authorize?duration=permanent',
        key         => 'Reddit consumer key',
        secret      => 'Reddit consumer secret',
        scope       => $scope,
        on_finished => sub {
            my ( $c, $access_token, $access_secret, $extra ) = @_;
            ...;
        },
    );

    # Mojolicious::Lite
    plugin 'Web::Auth',
        module      => 'Reddit',
        access_token_url => $access_token_url,
        authorize_url =>
            'https://www.reddit.com/api/v1/authorize?duration=permanent',
        key         => 'Reddit consumer key',
        secret      => 'Reddit consumer secret',
        scope       => $scope,
        on_finished => sub {
            my ( $c, $access_token, $access_secret, $extra ) = @_;
            ...
        };

    # default authentication endpoint: /auth/reddit/authenticate
    # default callback endpoint: /auth/reddit/callback

=head1 DESCRIPTION

This module adds L<Reddit|https://www.reddit.com/dev/api/> support to
L<Mojolicious::Plugin::Web::Auth>.

The default C<authorize_url> allows only for temporary tokens.  If you require
a refresh token, set your own C<authorize_url> as in the example in the
SYNOPSIS.  Your C<refresh_token> will be included in the C<$extra> arg as seen
above.  For example, C<$extra> may look like the following:

    {
        expires_in    => 3600,
        refresh_token => 'seekrit_token',
        scope =>
            'edit flair history identity modconfig modflair modlog modposts modwiki mysubreddits privatemessages read report save submit subscribe vote wikiedit wikiread',
        token_type => 'bearer',
    },

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Reddit OAuth Plugin for Mojolicious::Plugin::Web::Auth

