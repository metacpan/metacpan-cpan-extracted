#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json decode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Firecrawl;

# Subclass that dispatches requests against a scripted response table instead
# of going over the network.
{
  package Test::Firecrawl::Scripted;
  use parent 'Net::Async::Firecrawl';
  use JSON::MaybeXS qw( encode_json );
  use HTTP::Response;
  use Future;

  sub _init {
    my ( $self, $args ) = @_;
    $self->{script} = delete $args->{script} || [];
    $self->{log}    = [];
    $self->SUPER::_init($args);
  }

  sub do_request {
    my ( $self, $req ) = @_;
    push @{ $self->{log} }, { method => $req->method, uri => $req->uri.'' };
    my $step = shift @{ $self->{script} }
      or return Future->fail("script exhausted for ".$req->method.' '.$req->uri);
    my $body = ref $step->{body} ? encode_json($step->{body}) : ($step->{body} // '');
    my $res = HTTP::Response->new(
      $step->{code} // 200, $step->{message} // 'OK',
      [ 'Content-Type' => 'application/json' ], $body,
    );
    return Future->done($res);
  }

  sub log { $_[0]->{log} }
}

my $loop = IO::Async::Loop->new;

sub mk_client {
  my ( @script ) = @_;
  my $fc = Test::Firecrawl::Scripted->new(
    base_url      => 'http://localhost:9999',
    poll_interval => 0,
    script        => [ @script ],
  );
  $loop->add($fc);
  return $fc;
}

subtest 'scrape returns data' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), data => { markdown => '# page' } } },
  );
  my $data = $fc->scrape( url => 'https://example.com' )->get;
  is $data->{markdown}, '# page';
  is $fc->log->[0]{method}, 'POST';
  like $fc->log->[0]{uri}, qr{/v2/scrape$};
};

subtest 'map returns links arrayref' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), links => [ { url => 'a' }, { url => 'b' } ] } },
  );
  my $links = $fc->map( url => 'https://example.com' )->get;
  is scalar @$links, 2;
};

subtest 'crawl_and_collect: start + poll twice + paginate' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), id => 'job1', url => 'http://localhost:9999/v2/crawl/job1' } },
    { body => { status => 'scraping', total => 3, completed => 1, data => [] } },
    { body => { status => 'completed', total => 3, completed => 3,
                data => [ { markdown => 'p1' } ],
                next => 'http://localhost:9999/v2/crawl/job1?skip=1' } },
    { body => { status => 'completed', data => [ { markdown => 'p2' }, { markdown => 'p3' } ] } },
  );
  my $res = $fc->crawl_and_collect( url => 'https://example.com' )->get;
  is $res->{status}, 'completed';
  is scalar @{ $res->{raw_data} }, 3, 'all pages in raw_data';
  is scalar @{ $res->{data} },      3, 'all ok in data (no metadata = ok)';
  is scalar @{ $res->{failed} },    0;
  is $res->{stats}{ok},     3;
  is $res->{stats}{failed}, 0;
  is $res->{stats}{total},  3;
  is $res->{raw_data}[0]{markdown}, 'p1';
  is $res->{raw_data}[2]{markdown}, 'p3';

  my @uris = map { $_->{uri} } @{ $fc->log };
  like $uris[0], qr{/v2/crawl$},       'start crawl';
  like $uris[1], qr{/v2/crawl/job1$},  'first poll';
  like $uris[2], qr{/v2/crawl/job1$},  'second poll';
  like $uris[3], qr{skip=1},           'pagination URL followed';
};

subtest 'batch_scrape_and_wait' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), id => 'b1', url => 'x' } },
    { body => { status => 'completed', data => [ { markdown => 'a' }, { markdown => 'b' } ] } },
  );
  my $res = $fc->batch_scrape_and_wait( urls => ['https://a','https://b'] )->get;
  is $res->{status}, 'completed';
  is scalar @{ $res->{data} },    2, 'both ok';
  is scalar @{ $res->{failed} },  0;
  is $res->{stats}{ok},     2;
  is $res->{stats}{failed}, 0;
  is $res->{stats}{total},  2;
};

subtest 'extract_and_wait: processing → completed' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), id => 'e1' } },
    { body => { status => 'processing' } },
    { body => { status => 'completed', data => { title => 'X' } } },
  );
  my $res = $fc->extract_and_wait( urls => ['https://a/*'] )->get;
  is $res->{status}, 'completed';
  is $res->{data}{title}, 'X';
};

subtest 'scrape_many with partial-success shape' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), data => { markdown => 'A' } } },
    { body => { success => JSON::MaybeXS::true(), data => { markdown => 'B' } } },
    { body => { success => JSON::MaybeXS::true(), data => { markdown => 'C' } } },
  );
  my $res = $fc->scrape_many(['https://a','https://b','https://c'])->get;
  is $res->{stats}{ok},     3;
  is $res->{stats}{failed}, 0;
  is scalar @{ $res->{ok} }, 3;
};

subtest 'error propagation' => sub {
  my $fc = mk_client(
    { code => 400, message => 'Bad Request', body => { error => 'bad url' } },
  );
  my $f = $fc->scrape( url => 'https://example.com' );
  my $err = eval { $f->get; 0 } ? 0 : $@;
  like $err, qr/HTTP 400.*bad url/;
};

subtest 'job status=failed throws type=job' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), id => 'job-bad' } },
    { body => { status => 'failed', data => [] } },
  );
  my $f = $fc->crawl_and_collect( url => 'https://example.com' );
  my @failure = $f->failure;
  ok $failure[0], 'future failed';
  isa_ok $failure[0], 'WWW::Firecrawl::Error';
  ok $failure[0]->is_job, 'type=job';
  like "$failure[0]", qr/failed/i;
};

subtest 'job status=cancelled throws type=job' => sub {
  my $fc = mk_client(
    { body => { success => JSON::MaybeXS::true(), id => 'job-cancel' } },
    { body => { status => 'cancelled', data => [] } },
  );
  my @failure = $fc->extract_and_wait( urls => ['https://a/*'] )->failure;
  ok $failure[0];
  isa_ok $failure[0], 'WWW::Firecrawl::Error';
  ok $failure[0]->is_job;
};

done_testing;
