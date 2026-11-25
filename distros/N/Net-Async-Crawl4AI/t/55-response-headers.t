#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::Crawl4AI;
use WWW::Crawl4AI::Result ();

# Mocks the HTTP layer and records requests — same pattern as t/50-actions.t
{
  package Test::C4::ResponseHeaders;
  use parent 'Net::Async::Crawl4AI';
  use Future;
  use WWW::Crawl4AI::Result ();

  sub _init {
    my ( $self, $args ) = @_;
    $self->{response} = delete $args->{response};
    $self->{response_pages} = delete $args->{response_pages};
    $self->SUPER::_init($args);
  }

  # Override crawl_once to return a single normalized page without the network.
  # The response_pages structure must match what _normalize_page produces.
  sub crawl_once {
    my ( $self, $request, $backend ) = @_;
    $self->{last_req} = $request;
    return Future->done( $self->{response_pages} // [] );
  }

  sub last_req { $_[0]->{last_req} }
}

delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};
my $loop = IO::Async::Loop->new;

sub mk {
  my ( $normalized_page ) = @_;
  # $normalized_page is what _normalize_page produces (has response_headers key)
  my $c = Test::C4::ResponseHeaders->new(
    base_url        => 'http://localhost:9999',
    response_pages  => [$normalized_page],
  );
  $loop->add($c);
  return $c;
}

subtest 'crawl result exposes response_headers from async path' => sub {
  # Sufficient markdown text to pass WWW::Crawl4AI::Detect::is_good (requires
  # meaningful content, not just a heading). This ensures the strategy chain
  # succeeds so from_attempt is invoked and response_headers are preserved.
  my $heavy_markdown = "# Example\n\n" . ( "Lorem ipsum dolor sit amet. " x 50 );

  my $c = mk( {
    success      => JSON::MaybeXS::true(),
    url          => 'https://example.com',
    markdown     => $heavy_markdown,
    status_code  => 200,
    response_headers => {
      Link          => q(<https://example.com/api/catalog>; rel="api-catalog"),
      'Content-Type' => q(text/html; charset=utf-8),
    },
    links        => { internal => [], external => [] },
    metadata     => { sourceURL => 'https://example.com' },
  } );

  my $result = $c->crawl( 'https://example.com' )->get;

  # response_headers present on result
  ok exists $result->response_headers->{link},
    'response_headers->{link} exists (key lowercased from HTTP casing)';
  ok exists $result->response_headers->{'content-type'},
    'response_headers->{content-type} exists';

  # values preserved, header casing normalized (lowercased keys)
  is $result->response_headers->{link},
    q(<https://example.com/api/catalog>; rel="api-catalog"),
    'link value preserved through async path';
  is $result->response_headers->{'content-type'},
    q(text/html; charset=utf-8),
    'content-type value preserved through async path';

  # explicitly check no camelCase keys leaked through
  ok !exists $result->response_headers->{Link},
    'camelCase Link key not present (lowercasing enforced)';
};

subtest 'crawl result response_headers default to empty hash when absent' => sub {
  my $c = mk( {
    success      => JSON::MaybeXS::true(),
    url          => 'https://example.com',
    markdown     => '# Example',
    status_code  => 200,
    links        => { internal => [], external => [] },
    metadata     => { sourceURL => 'https://example.com' },
    # no response_headers key at all
  } );

  my $result = $c->crawl( 'https://example.com' )->get;

  is ref $result->response_headers, 'HASH',
    'response_headers is a hashref when absent from payload';
  is scalar keys %{ $result->response_headers }, 0,
    'response_headers empty when no headers in page';
};

done_testing;