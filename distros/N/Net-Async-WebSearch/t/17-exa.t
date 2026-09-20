#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Future;
use HTTP::Response;
use JSON::MaybeXS qw( decode_json );

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Exa;

# Offline, fixture-driven parse test for the Exa neural search provider, in the
# same shape as t/15-provider-parse.t: a captured Exa response is fed through
# the REAL search() path via a do_request double that returns the fixture as an
# already-done Future — no loop, no network, no live vars. We assert the Result
# list precisely (count, url/title/snippet-from-`text`/rank), the
# publishedDate → published_at mapping, the extras, and the _normalize_url dedup
# key (fixture carries a trailing-slash and a #fragment URL). We also capture
# the outgoing request body to prove Exa's defining behaviour: search() asks for
# contents.text, without which hits carry no snippet.

# Net::Async::HTTP stand-in: records the request it was handed, then replays one
# scripted response. Only do_request is exercised (provider called directly).
{
  package Test::WS::ExaMockHTTP;
  use Future;
  use HTTP::Response;
  sub new {
    my ( $class, %args ) = @_;
    bless { %args, seen => undef }, $class;
  }
  sub seen { $_[0]->{seen} }
  sub do_request {
    my ( $self, %args ) = @_;
    $self->{seen} = $args{request};
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

# Realistic Exa /search response with contents.text requested. First hit has a
# trailing-slash URL, second carries a #fragment — both stress _normalize_url.
my $JSON = <<'JSON';
{
  "requestId": "abc123",
  "resolvedSearchType": "neural",
  "results": [
    {
      "id": "https://www.perl.org/",
      "url": "https://www.perl.org/",
      "title": "The Perl Programming Language",
      "publishedDate": "2024-01-15T00:00:00.000Z",
      "author": "Perl.org",
      "score": 0.198,
      "text": "Perl is a highly capable, feature-rich programming language."
    },
    {
      "id": "https://en.wikipedia.org/wiki/Perl",
      "url": "https://en.wikipedia.org/wiki/Perl#History",
      "title": "Perl - Wikipedia",
      "score": 0.171,
      "text": "Perl is a family of two high-level, general-purpose programming languages."
    }
  ]
}
JSON

my $mock = Test::WS::ExaMockHTTP->new( body => $JSON, ct => 'application/json' );
my $exa  = Net::Async::WebSearch::Provider::Exa->new( api_key => 'dummy-key' );

my $results = $exa->search( $mock, $QUERY, { limit => 10 } )->get;

is scalar @$results, 2, 'two results parsed';
is $results->[0]->provider, 'exa', 'provider name on result';

# The defining Exa behaviour: the request body must ask for contents.text, or
# hits come back with no snippet. Assert the header and the decoded body.
subtest 'request asks for contents.text over POST-JSON' => sub {
  my $req = $mock->seen;
  ok $req, 'a request was dispatched';
  is $req->method, 'POST', 'POST method';
  is $req->uri.'', 'https://api.exa.ai/search', 'default endpoint';
  is $req->header('x-api-key'), 'dummy-key', 'api key sent as x-api-key header';
  like $req->header('Content-Type'), qr{application/json}, 'JSON content-type';
  my $body = eval { decode_json( $req->content ) };
  ok !$@, 'request body is valid JSON' or diag $@;
  is $body->{query}, $QUERY, 'query in body';
  is $body->{numResults}, 10, 'numResults sized to limit';
  ok exists $body->{contents}{text}, 'contents.text requested';
  ok $body->{contents}{text}, 'contents.text is truthy (JSON true)';
};

# Snippet MUST come from `text`, published_at from `publishedDate`.
is $results->[0]->published_at, '2024-01-15T00:00:00.000Z',
  'publishedDate → published_at';
is $results->[0]->extra->{author}, 'Perl.org', 'author kept in extra';
is $results->[0]->extra->{id}, 'https://www.perl.org/', 'id kept in extra';
cmp_ok $results->[0]->extra->{score}, '==', 0.198, 'Exa relevance score in extra';
is $results->[0]->score, undef,
  'Exa relevance score does NOT leak into the RRF score attribute';

sub check_result {
  my ( $r, $exp ) = @_;
  is $r->url,     $exp->{url},     '  url';
  is $r->title,   $exp->{title},   '  title';
  is $r->snippet, $exp->{snippet}, '  snippet (from text)';
  is $r->rank,    $exp->{rank},    '  rank';
  is $ws->_normalize_url( $r->url ), $exp->{norm}, '  normalized dedup key';
}

check_result( $results->[0], {
  url     => 'https://www.perl.org/',
  title   => 'The Perl Programming Language',
  snippet => 'Perl is a highly capable, feature-rich programming language.',
  rank    => 1,
  norm    => 'https://www.perl.org',              # trailing slash stripped
});
check_result( $results->[1], {
  url     => 'https://en.wikipedia.org/wiki/Perl#History',
  title   => 'Perl - Wikipedia',
  snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
  rank    => 2,
  norm    => 'https://en.wikipedia.org/wiki/perl', # fragment stripped, lc'd
});

done_testing;
