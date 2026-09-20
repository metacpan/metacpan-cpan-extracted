#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Future;
use HTTP::Response;
use URI;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Marginalia;

# Offline, fixture-driven parse test for the Marginalia provider. Marginalia's
# search() only touches the network through $http->do_request; the double below
# returns a captured Marginalia /search response as an already-done Future, so
# the real parse path runs with no loop, no network and no live vars. We assert
# the resulting Result list precisely — count, url/title/snippet/rank, and the
# normalized dedup key — plus the request the provider builds (the default
# public key, the query/count params, and the safesearch→nsfw mapping) so a
# change to _normalize_url, the Result contract or the request path fails here.

# Minimal Net::Async::HTTP stand-in: hands back one scripted response for the
# request and records the request it was handed. Only do_request is exercised
# (the provider is called directly, never added to a loop).
{
  package Test::WS::MarginaliaMockHTTP;
  use Future;
  use HTTP::Response;
  sub new {
    my ( $class, %args ) = @_;
    bless { %args }, $class;
  }
  sub last_req { $_[0]->{last_req} }
  sub do_request {
    my ( $self, %args ) = @_;
    $self->{last_req} = $args{request};
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

# Realistic Marginalia /search response. Deliberately mixes a trailing-slash URL
# and a fragment URL so normalization is covered; the top-level `license` field
# is the corpus licence carried into each result's extra.
my $json = <<'JSON';
{
  "license": "https://creativecommons.org/licenses/by-nc-sa/4.0/",
  "query": "perl programming language",
  "results": [
    {
      "url": "https://www.perl.org/",
      "title": "The Perl Programming Language",
      "description": "Perl is a highly capable, feature-rich programming language."
    },
    {
      "url": "https://en.wikipedia.org/wiki/Perl#History",
      "title": "Perl - Wikipedia",
      "description": "Perl is a family of two high-level, general-purpose programming languages."
    }
  ]
}
JSON

subtest 'public key default — no api_key needed to construct or call' => sub {
  my $m = Net::Async::WebSearch::Provider::Marginalia->new;
  is $m->api_key, 'public', "api_key defaults to 'public'";
  is $m->name,    'marginalia', 'default provider name';

  # The default public key must let the call proceed — no croak, no missing key.
  my $mock = Test::WS::MarginaliaMockHTTP->new( body => $json );
  my $results = $m->search( $mock, $QUERY, { limit => 10 } )->get;
  is scalar @$results, 2, 'call succeeds on the default key';

  my %q = URI->new( $mock->last_req->uri.'' )->query_form;
  is $q{query}, $QUERY, 'query param carries the search string';
  is $q{count}, 10,     'count param sized to the limit';
  is $mock->last_req->header('API-Key'), 'public',
    'default public key sent as the API-Key header';
};

subtest 'parse fixture through the real search() path' => sub {
  my $m = Net::Async::WebSearch::Provider::Marginalia->new( api_key => 'test-key' );
  my $results = $m->search(
    Test::WS::MarginaliaMockHTTP->new( body => $json, ct => 'application/json' ),
    $QUERY, { limit => 10 },
  )->get;

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'marginalia', 'provider name on result';
  is $results->[0]->extra->{license},
    'https://creativecommons.org/licenses/by-nc-sa/4.0/',
    'top-level license carried into extra';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,
    norm    => 'https://www.perl.org',                # trailing slash stripped
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',  # fragment stripped, lc'd
  });
};

subtest 'safesearch maps to the nsfw request filter' => sub {
  my $m = Net::Async::WebSearch::Provider::Marginalia->new;

  my $on = Test::WS::MarginaliaMockHTTP->new( body => $json );
  $m->search( $on, $QUERY, { safesearch => 1 } )->get;
  my %q_on = URI->new( $on->last_req->uri.'' )->query_form;
  is $q_on{nsfw}, 0, 'safesearch on suppresses nsfw (nsfw=0)';

  my $off = Test::WS::MarginaliaMockHTTP->new( body => $json );
  $m->search( $off, $QUERY, { safesearch => 0 } )->get;
  my %q_off = URI->new( $off->last_req->uri.'' )->query_form;
  is $q_off{nsfw}, 1, 'safesearch off allows nsfw (nsfw=1)';

  my $none = Test::WS::MarginaliaMockHTTP->new( body => $json );
  $m->search( $none, $QUERY, {} )->get;
  my %q_none = URI->new( $none->last_req->uri.'' )->query_form;
  ok !exists $q_none{nsfw}, 'no nsfw param when safesearch is unset';
};

done_testing;
