#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Future;
use HTTP::Response;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Tavily;

# Offline, fixture-driven parse test for the Tavily provider. Tavily's search()
# only touches the network through $http->do_request; the double below returns a
# captured Tavily /search response as an already-done Future, so the real parse
# path runs with no loop, no network and no live vars. We assert the resulting
# Result list precisely — count, url/title/snippet/rank, the published_at
# mapping, and the normalized dedup key — so a change to _normalize_url, the
# Result contract or Tavily's response mapping fails here too.

# Minimal Net::Async::HTTP stand-in: hands back one scripted response for the
# request. Only do_request is exercised (the provider is called directly, never
# added to a loop).
{
  package Test::WS::TavilyMockHTTP;
  use Future;
  use HTTP::Response;
  sub new {
    my ( $class, %args ) = @_;
    bless { %args }, $class;
  }
  sub do_request {
    my ( $self, %args ) = @_;
    my $res = HTTP::Response->new(
      $self->{code} // 200,
      $self->{msg}  // 'OK',
      [ 'Content-Type' => $self->{ct} // 'application/json' ],
      $self->{body} // '',
    );
    $res->request( $args{request} );
    return Future->done($res);
  }
}

my $QUERY = 'perl programming language';

# Instance used purely to reach the real _normalize_url dedup key.
my $ws = Net::Async::WebSearch->new;

# Assert the load-bearing normalized-Result fields plus the dedup key.
sub check_result {
  my ( $r, $exp ) = @_;
  is $r->url,     $exp->{url},     '  url';
  is $r->title,   $exp->{title},   '  title';
  is $r->snippet, $exp->{snippet}, '  snippet';
  is $r->rank,    $exp->{rank},    '  rank';
  is $ws->_normalize_url( $r->url ), $exp->{norm}, '  normalized dedup key';
}

# Realistic Tavily /search response. Deliberately mixes a trailing-slash URL, a
# fragment URL and another trailing-slash URL so normalization is covered; the
# first hit carries published_date/favicon, the second carries neither.
my $json = <<'JSON';
{
  "query": "perl programming language",
  "results": [
    {
      "title": "The Perl Programming Language - www.perl.org",
      "url": "https://www.perl.org/",
      "content": "Perl is a highly capable, feature-rich programming language.",
      "score": 0.98,
      "published_date": "2024-01-15",
      "favicon": "https://www.perl.org/favicon.ico"
    },
    {
      "title": "Perl - Wikipedia",
      "url": "https://en.wikipedia.org/wiki/Perl#History",
      "content": "Perl is a family of two high-level, general-purpose programming languages.",
      "score": 0.91
    },
    {
      "title": "Learn Perl",
      "url": "https://learn.perl.org/first_steps/",
      "content": "First steps in Perl programming.",
      "score": 0.72
    }
  ],
  "response_time": 1.23
}
JSON

my $tavily = Net::Async::WebSearch::Provider::Tavily->new( api_key => 'test-key' );
my $results = $tavily->search(
  Test::WS::TavilyMockHTTP->new( body => $json, ct => 'application/json' ),
  $QUERY, { limit => 10 },
)->get;

is scalar @$results, 3, 'three results parsed';
is $results->[0]->provider, 'tavily', 'provider name on result';

# published_date → published_at, only when the upstream supplies it.
is $results->[0]->published_at, '2024-01-15', 'published_date → published_at';
is $results->[1]->published_at, undef, 'no published_date → published_at undef';

# Tavily-specific extras: score always, favicon when present.
cmp_ok $results->[0]->extra->{score}, '==', 0.98, 'score kept in extra';
is $results->[0]->extra->{favicon}, 'https://www.perl.org/favicon.ico',
  'favicon kept in extra';
is $results->[1]->extra->{favicon}, undef, 'no favicon → absent from extra';

check_result( $results->[0], {
  url     => 'https://www.perl.org/',
  title   => 'The Perl Programming Language - www.perl.org',
  snippet => 'Perl is a highly capable, feature-rich programming language.',
  rank    => 1,
  norm    => 'https://www.perl.org',                  # trailing slash stripped
});
check_result( $results->[1], {
  url     => 'https://en.wikipedia.org/wiki/Perl#History',
  title   => 'Perl - Wikipedia',
  snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
  rank    => 2,
  norm    => 'https://en.wikipedia.org/wiki/perl',    # fragment stripped, lc'd
});
check_result( $results->[2], {
  url     => 'https://learn.perl.org/first_steps/',
  title   => 'Learn Perl',
  snippet => 'First steps in Perl programming.',
  rank    => 3,
  norm    => 'https://learn.perl.org/first_steps',    # trailing slash stripped
});

done_testing;
