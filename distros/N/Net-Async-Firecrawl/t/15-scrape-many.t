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
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json );
  use Future;
  sub _init {
    my ( $self, $args ) = @_;
    $self->{url_script} = delete $args->{url_script} || {};
    $self->SUPER::_init($args);
  }
  sub do_request {
    my ( $self, $req ) = @_;
    my ($url) = $req->content =~ /"url"\s*:\s*"([^"]+)"/;
    my $step = $self->{url_script}{$url}
      or return Future->fail("no script for $url");
    my $body = ref $step->{body} ? encode_json($step->{body}) : ($step->{body} // '');
    return Future->done(
      HTTP::Response->new( $step->{code} // 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $body ),
    );
  }
}

my $loop = IO::Async::Loop->new;
my $fc = Test::Firecrawl::ByUrl->new(
  base_url => 'http://x',
  url_script => {
    'https://a' => { body => {
      success => JSON::MaybeXS::true(),
      data => { markdown => 'A', metadata => { sourceURL => 'https://a', statusCode => 200 } },
    } },
    'https://b' => { body => {
      success => JSON::MaybeXS::true(),
      data => { metadata => { sourceURL => 'https://b', statusCode => 503, error => 'timeout' } },
    } },
    'https://c' => { code => 400, body => { error => 'bad url' } },
  },
);
$loop->add($fc);

my $res = $fc->scrape_many([qw( https://a https://b https://c )])->get;
is $res->{stats}{ok},     1;
is $res->{stats}{failed}, 2;
is $res->{ok}[0]{url}, 'https://a';
is $res->{ok}[0]{data}{markdown}, 'A';

my @failed_urls = sort map { $_->{url} } @{ $res->{failed} };
is_deeply \@failed_urls, [qw( https://b https://c )];
for my $f (@{ $res->{failed} }) {
  isa_ok $f->{error}, 'WWW::Firecrawl::Error';
}

done_testing;
