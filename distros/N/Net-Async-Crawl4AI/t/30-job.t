#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

# Scripted dispatch keyed by call order; logs method + uri so we can assert the
# submit -> poll -> poll sequence.
{
  package Test::C4::Job;
  use parent 'Net::Async::Crawl4AI';
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json );
  use Future;
  sub _init {
    my ( $self, $args ) = @_;
    $self->{script} = delete $args->{script} || [];
    $self->{log}    = [];
    $self->SUPER::_init($args);
  }
  sub do_request {
    my ( $self, $req, $backend ) = @_;
    push @{ $self->{log} }, { method => $req->method, uri => $req->uri . '' };
    my $step = shift @{ $self->{script} } or return Future->fail("script exhausted");
    my $body = ref $step->{body} ? encode_json( $step->{body} ) : ( $step->{body} // '' );
    return Future->done(
      HTTP::Response->new( $step->{code} // 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $body ) );
  }
  sub log { $_[0]->{log} }
}

my $loop = IO::Async::Loop->new;

subtest 'crawl_job_and_wait: submit + poll twice to COMPLETED' => sub {
  my $c = Test::C4::Job->new(
    base_url      => 'http://localhost:9999',
    poll_interval => 0,
    delay_sub     => sub { Future->done },
    script        => [
      { body => { task_id => 'job1' } },
      { body => { status  => 'PROCESSING' } },
      { body => { status  => 'COMPLETED',
                  results => [ { markdown => ( 'done ' x 200 ), status_code => 200 } ] } },
    ],
  );
  $loop->add($c);

  my $res = $c->crawl_job_and_wait('https://example.com')->get;
  is $res->{status}, 'COMPLETED', 'job completed';
  is scalar @{ $res->{pages} }, 1, 'one page collected';
  like $res->{pages}[0]{markdown}, qr/done/, 'page markdown present';

  my @log = @{ $c->log };
  is scalar @log, 3, 'submit + two polls';
  is $log[0]{method}, 'POST', 'submit is POST';
  like $log[0]{uri}, qr{/crawl/job$},      'submit hits /crawl/job';
  like $log[1]{uri}, qr{/crawl/job/job1$}, 'first poll';
  like $log[2]{uri}, qr{/crawl/job/job1$}, 'second poll';
};

subtest 'crawl_job_and_wait: FAILED job fails Future type=job' => sub {
  my $c = Test::C4::Job->new(
    base_url      => 'http://localhost:9999',
    poll_interval => 0,
    delay_sub     => sub { Future->done },
    script        => [
      { body => { task_id => 'jobX' } },
      { body => { status => 'FAILED', error => 'boom' } },
    ],
  );
  $loop->add($c);

  my @failure = $c->crawl_job_and_wait('https://example.com')->failure;
  ok $failure[0], 'future failed';
  isa_ok $failure[0], 'WWW::Crawl4AI::Error';
  ok $failure[0]->is_job, 'type=job';
  like "$failure[0]", qr/boom/, 'error detail surfaced';
};

done_testing;
