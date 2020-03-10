package Mojo::WebService::Twitter::Util;

use strict;
use warnings;
use Exporter 'import';
use Mojo::URL;
use Time::Piece ();

our $VERSION = '1.001';

our @EXPORT_OK = qw(parse_twitter_timestamp twitter_authorize_url);

our $API_BASE_URL = 'https://api.twitter.com/1.1/';
our $OAUTH_BASE_URL = 'https://api.twitter.com/oauth/';
our $OAUTH2_BASE_URL = 'https://api.twitter.com/oauth2/';

sub parse_twitter_timestamp { Time::Piece->strptime(shift, '%a %b %d %H:%M:%S %z %Y') }

sub twitter_authorize_url { _oauth_url('authorize')->query(oauth_token => shift) }

sub _api_url { Mojo::URL->new($API_BASE_URL)->path(shift) }
sub _oauth_url { Mojo::URL->new($OAUTH_BASE_URL)->path(shift) }
sub _oauth2_url { Mojo::URL->new($OAUTH2_BASE_URL)->path(shift) }

1;

=head1 NAME

Mojo::WebService::Twitter::Util - Utility functions for Twitter client

=head1 SYNOPSIS

 use Mojo::WebService::Twitter::Util 'parse_twitter_timestamp';

 my $epoch = parse_twitter_timestamp('Fri Oct 23 17:18:19 +0100 2015')->epoch;

=head1 DESCRIPTION

L<Mojo::WebService::Twitter::Util> contains utility functions used by
L<Mojo::WebService::Twitter> for interacting with the L<Twitter|https://twitter.com>
API. All functions are exportable on demand.

=head1 FUNCTIONS

=head2 parse_twitter_timestamp

 my $time = parse_twitter_timestamp($ts);

Takes a timestamp string in the format returned by Twitter and returns a
corresponding L<Time::Piece> object in UTC.

=head2 twitter_authorize_url

 my $url = twitter_authorize_url($token);

Takes an OAuth 1.0 request token and returns a L<Mojo::URL> for manual user
authorization.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::WebService::Twitter>
