package Net::Backtweet;
BEGIN {
  $Net::Backtweet::VERSION = '0.03';
}

# ABSTRACT: client for the backtweet API

use Moose;
use Net::HTTP::API;
extends 'Net::Backtype';

net_api_declare backtweet => (
    base_url    => 'http://api.backtype.com',
    format      => 'json',
    format_mode => 'append',
);

net_api_method tweets_by_url => (
    description =>
      'Retrieve tweets that link to a given URL, whether the links are shortened or unshortened.',
    path     => '/tweets/search/links',
    method   => 'GET',
    params   => [qw/q key itemsperpage start end/],
    required => [qw/q key/],
    expected => [qw/200/],
);

net_api_method stats_by_url => (
    description =>
      'Retrieve the number of tweets that link to a particular URL.',
    path     => '/tweetcount',
    method   => 'GET',
    params   => [qw/q batch key/],
    required => [qw/q key/],
    expected => [qw/200/],
);

net_api_method good_tweets_by_url => (
    description =>
      'Retrieve filtered tweets that link to a given URL with both shortened and unshortened links. This returns a subset of Tweets by URL.',
    path     => '/goodtweets',
    method   => 'GET',
    params   => [qw/q key/],
    required => [qw/q key/],
    expected => [qw/200/],
);

# back compatibility
sub backtweet_search {
    (shift)->tweets_by_url(@_);
}

1;


__END__
=pod

=head1 NAME

Net::Backtweet - client for the backtweet API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Net::Backtweet;
  my $client = Net::Backtweet->new();
  my $res = $client->tweets_by_url(q => 'lumberjaph', key => 's3kr3t');

=head1 DESCRIPTION

Net::Backtype is a client for the backtweet API.

=head2 METHODS

=over 4

=item B<tweets_by_url>

Retrieve the number of tweets that link to a particular URL.

    my $tweets = $client->tweets_by_url(q => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<q> query (required)

=item B<key> API key (required)

=item B<itemsperpage> number of items per page (optional)

=item B<start> date start (optional)

=item B<end> date end (optional)

=back

See L<http://www.backtype.com/developers/tweets-by-url>.

=item B<stats_by_url>

Retrieve the number of tweets that link to a particular URL.

    my $stats = $client->stats_by_url(q => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<q> query (required)

=item B<key> API key (required)

=back

See L<http://www.backtype.com/developers/tweet-count>.

=item B<good_tweets_by_url>

Retrieve filtered tweets that link to a given URL with both shortened and unshortened links. This returns a subset of Tweets by URL.

    my $good = $client->good_tweets_by_url(q => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<q> query (required)

=item B<key> API key (required)

=back

See L<http://www.backtype.com/developers/good-tweets>.

=back

See L<http://backtweets.com/api> for more information about the backtweets API.

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

