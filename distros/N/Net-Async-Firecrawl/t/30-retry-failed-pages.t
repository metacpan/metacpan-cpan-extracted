#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Firecrawl;

{
  package Test::Firecrawl::ByUrl;
  use parent 'Net::Async::Firecrawl';
  use HTTP::Response; use JSON::MaybeXS qw( encode_json ); use Future;
  sub _init {
    my ( $self, $args ) = @_;
    $self->{log} = [];
    $self->SUPER::_init($args);
  }
  sub do_request {
    my ( $self, $req ) = @_;
    my ($url) = $req->content =~ /"url"\s*:\s*"([^"]+)"/;
    push @{ $self->{log} }, $url;
    my $body = encode_json({
      success => JSON::MaybeXS::true(),
      data => { markdown => "MD for $url",
                metadata => { sourceURL => $url, statusCode => 200 } },
    });
    return Future->done(
      HTTP::Response->new( 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $body ),
    );
  }
  sub log { $_[0]->{log} }
}

my $loop = IO::Async::Loop->new;
my $fc = Test::Firecrawl::ByUrl->new( base_url => 'http://x' );
$loop->add($fc);

my $crawl_result = {
  status => 'completed',
  data => [ { metadata => { sourceURL => 'https://a', statusCode => 200 } } ],
  failed => [
    { url => 'https://b', statusCode => 503, error => 'timeout', page => {} },
    { url => 'https://c', statusCode => 502, error => 'gateway', page => {} },
  ],
};

my $retry = $fc->retry_failed_pages( $crawl_result, formats => ['markdown'] )->get;
is $retry->{stats}{ok}, 2;
is $retry->{stats}{failed}, 0;
is_deeply [ sort @{ $fc->log } ], [ 'https://b', 'https://c' ];

done_testing;
