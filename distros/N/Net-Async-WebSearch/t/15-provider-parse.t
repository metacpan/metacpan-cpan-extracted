#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Future;
use HTTP::Response;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::DuckDuckGo;
use Net::Async::WebSearch::Provider::SearxNG;
use Net::Async::WebSearch::Provider::Brave;
use Net::Async::WebSearch::Provider::Serper;
use Net::Async::WebSearch::Provider::Google;
use Net::Async::WebSearch::Provider::Yandex;
use Net::Async::WebSearch::Provider::Reddit;

# Offline, fixture-driven parse tests: one representative captured response per
# provider backend, fed through that provider's REAL parse path. Each provider's
# search() only touches the network via $http->do_request; the double below
# returns the fixture as an already-done Future, so the whole thing runs with no
# loop and no live vars. We assert the resulting Result list precisely — count,
# url/title/snippet/rank — plus the normalized dedup key, so a change to
# _normalize_url or the Result contract fails here too.

# Minimal Net::Async::HTTP stand-in: hands back one scripted response for any
# request. Only do_request is exercised (providers are called directly, never
# added to a loop).
{
  package Test::WS::ParseMockHTTP;
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

sub parse_via {
  my ( $provider, %mock ) = @_;
  # The double replays the same fixture for every request; a paging provider
  # (Google) would loop forever if asked for more than the fixture holds, so
  # `limit` is per-call (default 10 keeps the single-request providers as-is).
  my $limit = delete $mock{limit} // 10;
  return $provider->search(
    Test::WS::ParseMockHTTP->new(%mock), $QUERY, { limit => $limit },
  )->get;
}

# Assert the load-bearing normalized-Result fields plus the dedup key.
sub check_result {
  my ( $r, $exp ) = @_;
  is $r->url,     $exp->{url},     '  url';
  is $r->title,   $exp->{title},   '  title';
  is $r->snippet, $exp->{snippet}, '  snippet';
  is $r->rank,    $exp->{rank},    '  rank';
  is $ws->_normalize_url( $r->url ), $exp->{norm}, '  normalized dedup key';
}

#### DuckDuckGo — HTML scrape

subtest 'DuckDuckGo (HTML)' => sub {
  # DDG wraps the real target in //duckduckgo.com/l/?uddg=<escaped>&rut=...
  my $html = <<'HTML';
<!DOCTYPE html>
<html><head><title>results</title></head><body>
<div class="result results_links results_links_deep web-result">
  <div class="links_main links_deep result__body">
    <h2 class="result__title">
      <a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.perl.org%2F&amp;rut=deadbeef">The Perl Programming Language</a>
    </h2>
    <a class="result__snippet" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fwww.perl.org%2F">Perl is a highly capable, feature-rich programming language.</a>
  </div>
</div>
<div class="result results_links results_links_deep web-result">
  <div class="links_main links_deep result__body">
    <h2 class="result__title">
      <a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FPerl%23History&amp;rut=cafef00d">Perl - Wikipedia</a>
    </h2>
    <a class="result__snippet">Perl is a family of two high-level, general-purpose, interpreted programming languages.</a>
  </div>
</div>
</body></html>
HTML

  my $ddg = Net::Async::WebSearch::Provider::DuckDuckGo->new;
  my $results = parse_via( $ddg, body => $html, ct => 'text/html; charset=utf-8' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'duckduckgo', 'provider name on result';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,
    norm    => 'https://www.perl.org',            # trailing slash stripped
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose, interpreted programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl', # fragment stripped, lc'd
  });
};

#### SearxNG — JSON

subtest 'SearxNG (JSON)' => sub {
  my $json = <<'JSON';
{
  "query": "perl programming language",
  "number_of_results": 2,
  "results": [
    {
      "url": "https://www.perl.org/",
      "title": "The Perl Programming Language - www.perl.org",
      "content": "Perl is a highly capable, feature-rich programming language.",
      "engine": "duckduckgo",
      "category": "general",
      "publishedDate": null,
      "score": 1.0
    },
    {
      "url": "https://en.wikipedia.org/wiki/Perl#History",
      "title": "Perl - Wikipedia",
      "content": "Perl is a family of two high-level, general-purpose programming languages.",
      "engine": "wikipedia",
      "category": "general"
    }
  ]
}
JSON

  my $sx = Net::Async::WebSearch::Provider::SearxNG->new(
    endpoint => 'https://searx.example',
  );
  my $results = parse_via( $sx, body => $json, ct => 'application/json' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'searxng', 'provider name on result';
  is $results->[0]->extra->{engine}, 'duckduckgo', 'engine mapped into extra';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language - www.perl.org',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,
    norm    => 'https://www.perl.org',
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

#### Brave — JSON

subtest 'Brave (JSON)' => sub {
  my $json = <<'JSON';
{
  "web": {
    "results": [
      {
        "url": "https://www.perl.org/",
        "title": "The Perl Programming Language",
        "description": "Perl is a highly capable, feature-rich programming language.",
        "language": "en",
        "page_age": "2024-01-15T00:00:00",
        "age": "3 months ago",
        "profile": { "name": "Perl.org" },
        "subtype": "generic"
      },
      {
        "url": "https://en.wikipedia.org/wiki/Perl#History",
        "title": "Perl - Wikipedia",
        "description": "Perl is a family of two high-level, general-purpose programming languages.",
        "language": "en"
      }
    ]
  }
}
JSON

  my $brave = Net::Async::WebSearch::Provider::Brave->new( api_key => 'test-key' );
  my $results = parse_via( $brave, body => $json, ct => 'application/json' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'brave', 'provider name on result';
  is $results->[0]->published_at, '2024-01-15T00:00:00', 'page_age → published_at';
  is $results->[0]->language, 'en', 'language mapped';
  is $results->[0]->extra->{age}, '3 months ago', 'age kept in extra';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,
    norm    => 'https://www.perl.org',
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

#### Serper — JSON (Google proxy)

subtest 'Serper (JSON)' => sub {
  my $json = <<'JSON';
{
  "searchParameters": { "q": "perl programming language", "type": "search" },
  "organic": [
    {
      "title": "The Perl Programming Language - www.perl.org",
      "link": "https://www.perl.org/",
      "snippet": "Perl is a highly capable, feature-rich programming language.",
      "position": 1,
      "date": "Jan 15, 2024",
      "sitelinks": [ { "title": "Downloads", "link": "https://www.perl.org/get.html" } ]
    },
    {
      "title": "Perl - Wikipedia",
      "link": "https://en.wikipedia.org/wiki/Perl#History",
      "snippet": "Perl is a family of two high-level, general-purpose programming languages.",
      "position": 2
    }
  ]
}
JSON

  my $serper = Net::Async::WebSearch::Provider::Serper->new( api_key => 'test-key' );
  my $results = parse_via( $serper, body => $json, ct => 'application/json' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'serper', 'provider name on result';
  is $results->[0]->published_at, 'Jan 15, 2024', 'date → published_at';
  ok ref $results->[0]->extra->{sitelinks} eq 'ARRAY', 'sitelinks kept in extra';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language - www.perl.org',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,                                   # from "position"
    norm    => 'https://www.perl.org',
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
    rank    => 2,                                   # from "position"
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

#### Google — JSON (Programmable Search / CSE)

subtest 'Google (JSON)' => sub {
  my $json = <<'JSON';
{
  "kind": "customsearch#search",
  "items": [
    {
      "title": "The Perl Programming Language - www.perl.org",
      "link": "https://www.perl.org/",
      "snippet": "Perl is a highly capable, feature-rich programming language.",
      "displayLink": "www.perl.org",
      "pagemap": {
        "metatags": [ { "article:published_time": "2024-01-15T00:00:00Z" } ]
      }
    },
    {
      "title": "Perl - Wikipedia",
      "link": "https://en.wikipedia.org/wiki/Perl#History",
      "snippet": "Perl is a family of two high-level, general-purpose programming languages.",
      "displayLink": "en.wikipedia.org"
    }
  ]
}
JSON

  my $google = Net::Async::WebSearch::Provider::Google->new(
    api_key => 'test-key',
    cx      => 'test-cx',
  );
  # CSE serves <=10 hits/call and pages over `start`; limit=2 matches the two
  # fixture items so the real search() paging path makes exactly one call
  # against the replay double (multi-page paging is covered in t/45).
  my $results = parse_via(
    $google, body => $json, ct => 'application/json', limit => 2,
  );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'google', 'provider name on result';
  is $results->[0]->published_at, '2024-01-15T00:00:00Z',
    'metatags article:published_time → published_at';
  is $results->[0]->extra->{displayLink}, 'www.perl.org', 'displayLink in extra';

  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language - www.perl.org',
    snippet => 'Perl is a highly capable, feature-rich programming language.',
    rank    => 1,
    norm    => 'https://www.perl.org',
  });
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level, general-purpose programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

#### Yandex — XML

subtest 'Yandex (XML)' => sub {
  my $xml = <<'XML';
<?xml version="1.0" encoding="utf-8"?>
<yandexsearch version="1.0">
  <response date="20240115T000000">
    <results>
      <grouping attr="d" mode="deep">
        <group>
          <doc id="1">
            <url>https://www.perl.org/</url>
            <title>The Perl Programming Language</title>
            <passages>
              <passage>Perl is a highly capable, feature-rich programming language.</passage>
              <passage>Over 30 years of development.</passage>
            </passages>
          </doc>
        </group>
        <group>
          <doc id="2">
            <url>https://en.wikipedia.org/wiki/Perl#History</url>
            <title>Perl - Wikipedia</title>
            <headline>Perl is a family of two high-level programming languages.</headline>
          </doc>
        </group>
      </grouping>
    </results>
  </response>
</yandexsearch>
XML

  my $yandex = Net::Async::WebSearch::Provider::Yandex->new(
    api_key  => 'test-key',
    folderid => 'test-folder',
  );
  my $results = parse_via( $yandex, body => $xml, ct => 'application/xml' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'yandex', 'provider name on result';

  # Multiple passages are joined with ' … ' (matches the literal in Yandex.pm).
  check_result( $results->[0], {
    url     => 'https://www.perl.org/',
    title   => 'The Perl Programming Language',
    snippet => 'Perl is a highly capable, feature-rich programming language.'
             . ' … '
             . 'Over 30 years of development.',
    rank    => 1,
    norm    => 'https://www.perl.org',
  });
  # Falls back to the headline when there are no passages.
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => 'Perl is a family of two high-level programming languages.',
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

#### Reddit — JSON (keyless public endpoint)

subtest 'Reddit (JSON)' => sub {
  my $json = <<'JSON';
{
  "kind": "Listing",
  "data": {
    "children": [
      {
        "kind": "t3",
        "data": {
          "title": "Learning Perl in 2024",
          "url": "https://www.reddit.com/r/perl/comments/abc/learning_perl/",
          "permalink": "/r/perl/comments/abc/learning_perl/",
          "selftext": "I have been learning Perl and it is great for text processing.",
          "subreddit": "perl",
          "author": "alice",
          "score": 42,
          "num_comments": 7,
          "over_18": false,
          "domain": "self.perl",
          "created_utc": 1700000000
        }
      },
      {
        "kind": "t3",
        "data": {
          "title": "Perl - Wikipedia",
          "url": "https://en.wikipedia.org/wiki/Perl#History",
          "permalink": "/r/perl/comments/def/perl_wikipedia/",
          "selftext": "",
          "subreddit": "perl",
          "author": "bob",
          "score": 15,
          "num_comments": 3,
          "over_18": false,
          "domain": "en.wikipedia.org",
          "created_utc": 1700000100
        }
      }
    ]
  }
}
JSON

  my $reddit = Net::Async::WebSearch::Provider::Reddit->new;
  my $results = parse_via( $reddit, body => $json, ct => 'application/json' );

  is scalar @$results, 2, 'two results parsed';
  is $results->[0]->provider, 'reddit', 'provider name on result';
  is $results->[0]->published_at, '2023-11-14T22:13:20Z',
    'created_utc → ISO 8601 published_at';
  is $results->[0]->extra->{subreddit}, 'perl', 'subreddit in extra';
  is $results->[0]->extra->{permalink},
    'https://www.reddit.com/r/perl/comments/abc/learning_perl/',
    'absolute permalink built in extra';
  is $results->[0]->nsfw, 0, 'over_18 false → nsfw 0';

  # Self/text post: url is the (external-shaped) link, snippet from selftext.
  check_result( $results->[0], {
    url     => 'https://www.reddit.com/r/perl/comments/abc/learning_perl/',
    title   => 'Learning Perl in 2024',
    snippet => 'I have been learning Perl and it is great for text processing.',
    rank    => 1,
    norm    => 'https://www.reddit.com/r/perl/comments/abc/learning_perl',
  });
  # Link post with empty selftext → snippet undef.
  check_result( $results->[1], {
    url     => 'https://en.wikipedia.org/wiki/Perl#History',
    title   => 'Perl - Wikipedia',
    snippet => undef,
    rank    => 2,
    norm    => 'https://en.wikipedia.org/wiki/perl',
  });
};

done_testing;
