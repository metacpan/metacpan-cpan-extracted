#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Future;
use HTTP::Response;
use URI;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Mojeek;

# Offline, fixture-driven parse test for the Mojeek provider. Mojeek's search()
# only touches the network through $http->do_request; the double below returns a
# captured Mojeek /search response as an already-done Future, so the real parse
# path runs with no loop, no network and no live vars. We assert the resulting
# Result list precisely — count, url/title/snippet(from `desc`)/rank, and the
# normalized dedup key — plus the two request quirks that define this provider:
# `fmt=json` (without it Mojeek answers XML) and the key sent as the `api_key`
# *query parameter* rather than a header. The response fixture is the other
# Mojeek peculiarity: the hit list is nested under `response.results`, not a
# top-level `results`.

# Minimal Net::Async::HTTP stand-in: hands back one scripted response for the
# request and records the request it was handed. Only do_request is exercised
# (the provider is called directly, never added to a loop).
{
  package Test::WS::MojeekMockHTTP;
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
  is $r->snippet, $exp->{snippet}, '  snippet (from desc)';
  is $r->rank,    $exp->{rank},    '  rank';
  is $ws->_normalize_url( $r->url ), $exp->{norm}, '  normalized dedup key';
}

# Realistic Mojeek /search response. The hit list is nested under the `response`
# container (Mojeek's defining quirk) alongside `head` and `status`. The URLs
# deliberately mix a trailing-slash and a #fragment case so normalization is
# covered; the snippet lives in `desc`, not `description`/`snippet`.
my $json = <<'JSON';
{
  "response": {
    "status": "OK",
    "head": {
      "query": "perl programming language",
      "results": 2,
      "return": 2,
      "start": 1
    },
    "results": [
      {
        "url": "https://www.perl.org/",
        "title": "The Perl Programming Language",
        "desc": "Perl is a highly capable, feature-rich programming language."
      },
      {
        "url": "https://en.wikipedia.org/wiki/Perl#History",
        "title": "Perl - Wikipedia",
        "desc": "Perl is a family of two high-level, general-purpose programming languages."
      }
    ]
  }
}
JSON

subtest 'api_key is mandatory — no public key, unlike Marginalia' => sub {
  eval { Net::Async::WebSearch::Provider::Mojeek->new };
  like $@, qr/requires 'api_key'/, 'construction croaks without an api_key';

  my $m = Net::Async::WebSearch::Provider::Mojeek->new( api_key => 'test-key' );
  is $m->api_key, 'test-key', 'api_key stored';
  is $m->name,    'mojeek',   'default provider name';
};

subtest 'parse fixture through the real search() path' => sub {
  my $m = Net::Async::WebSearch::Provider::Mojeek->new( api_key => 'test-key' );
  my $results = $m->search(
    Test::WS::MojeekMockHTTP->new( body => $json, ct => 'application/json' ),
    $QUERY, { limit => 10 },
  )->get;

  is scalar @$results, 2, 'two results parsed from response.results';
  is $results->[0]->provider, 'mojeek', 'provider name on result';
  is $results->[0]->extra->{status}, 'OK',
    'container-level status carried into extra';

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

subtest 'outgoing request carries fmt=json and the key as a query param' => sub {
  my $m    = Net::Async::WebSearch::Provider::Mojeek->new( api_key => 'secret-key' );
  my $mock = Test::WS::MojeekMockHTTP->new( body => $json );
  $m->search( $mock, $QUERY, { limit => 7 } )->get;

  my %q = URI->new( $mock->last_req->uri.'' )->query_form;
  is $q{q},       $QUERY,        'q param carries the search string';
  is $q{t},       7,             't param sized to the limit';
  is $q{fmt},     'json',        'fmt=json is mandatory (else Mojeek returns XML)';
  is $q{api_key}, 'secret-key',  'key travels as the api_key query param, not a header';
  ok !defined $mock->last_req->header('X-API-Key'),  'no key header';
  ok !defined $mock->last_req->header('API-Key'),    'no key header (alt spelling)';
};

subtest 'language/region/safesearch map to lb/rb/safe only when set' => sub {
  my $m = Net::Async::WebSearch::Provider::Mojeek->new( api_key => 'k' );

  my $set = Test::WS::MojeekMockHTTP->new( body => $json );
  $m->search( $set, $QUERY,
    { language => 'de', region => 'de', safesearch => 1 } )->get;
  my %q_set = URI->new( $set->last_req->uri.'' )->query_form;
  is $q_set{lb},   'de', 'language maps to lb';
  is $q_set{rb},   'de', 'region maps to rb';
  is $q_set{safe}, 1,    'safesearch maps to safe';

  my $bare = Test::WS::MojeekMockHTTP->new( body => $json );
  $m->search( $bare, $QUERY, {} )->get;
  my %q_bare = URI->new( $bare->last_req->uri.'' )->query_form;
  ok !exists $q_bare{lb},   'no lb param when language unset';
  ok !exists $q_bare{rb},   'no rb param when region unset';
  ok !exists $q_bare{safe}, 'no safe param when safesearch unset';
};

subtest 'non-2xx response fails the future with the provider name tag' => sub {
  my $m    = Net::Async::WebSearch::Provider::Mojeek->new( api_key => 'k' );
  my $mock = Test::WS::MojeekMockHTTP->new( code => 403, msg => 'Forbidden', body => '{}' );
  my $f    = $m->search( $mock, $QUERY, {} );
  ok $f->is_ready, 'future settled (mock responds synchronously)';
  my $err = $f->failure;
  like $err, qr/mojeek: HTTP 403/, 'HTTP status surfaced from the failing call';
};

done_testing;
