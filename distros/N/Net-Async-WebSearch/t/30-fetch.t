#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future;
use HTTP::Response;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider;
use Net::Async::WebSearch::Result;

# Minimal Net::Async::HTTP stand-in: scripts responses per-URL.
{
  package Test::WS::MockHTTP;
  use Future;
  use HTTP::Response;
  sub new {
    my ( $class, %args ) = @_;
    bless { script => $args{script} || {}, log => [], default => $args{default} }, $class;
  }
  sub log { $_[0]->{log} }
  sub configure {}
  sub configure_unknown {}
  sub add_child {}
  sub remove_child {}
  sub _add_to_loop {}
  sub _remove_from_loop {}
  sub parent { }
  sub loop { }
  sub notifier_name { 'mock-http' }
  sub do_request {
    my ( $self, %args ) = @_;
    my $req = $args{request};
    my $url = $req->uri.'';
    push @{ $self->{log} }, { url => $url, headers => { map { $_ => $req->header($_) } $req->header_field_names } };
    my $step = $self->{script}{$url} // $self->{default};
    return Future->fail("no scripted response for $url") unless $step;
    return Future->fail($step->{fail}) if $step->{fail};
    my $res = HTTP::Response->new(
      $step->{code} // 200,
      $step->{msg}  // 'OK',
      [ 'Content-Type' => $step->{ct} // 'text/html; charset=utf-8' ],
      $step->{body} // '',
    );
    $res->request($req);
    return Future->done($res);
  }
}

# Scripted in-process provider, as in t/10-aggregation.t.
{
  package Test::WS::Prov;
  use parent 'Net::Async::WebSearch::Provider';
  use Future;
  use Net::Async::WebSearch::Result;
  sub search {
    my ( $self, $http, $query, $opts ) = @_;
    my $rows = $self->{rows} || [];
    my $rank = 0;
    my @out = map {
      $rank++;
      Net::Async::WebSearch::Result->new(
        url      => $_->{url},
        title    => $_->{title},
        snippet  => $_->{snippet},
        provider => $self->name,
        rank     => $rank,
      );
    } @$rows;
    return Future->done(\@out);
  }
}

sub make_ws {
  my ( $script, %args ) = @_;
  my $loop = IO::Async::Loop->new;
  my $mock = Test::WS::MockHTTP->new( script => $script );
  my $p = Test::WS::Prov->new(
    name => 'fake',
    rows => [
      { url => 'https://example.com/a', title => 'A', snippet => 'snip-a' },
      { url => 'https://example.com/b', title => 'B', snippet => 'snip-b' },
      { url => 'https://example.com/c', title => 'C', snippet => 'snip-c' },
    ],
  );
  my $ws = Net::Async::WebSearch->new(
    providers => [$p],
    http      => $mock,
    %args,
  );
  $loop->add($ws);
  return ( $ws, $mock, $loop );
}

subtest 'collect mode: fetch top N attaches ok body' => sub {
  my %script = (
    'https://example.com/a' => { body => '<html>A-body</html>' },
    'https://example.com/b' => { body => '<html>B-body</html>' },
    'https://example.com/c' => { body => '<html>C-body</html>' },
  );
  my ( $ws, $mock ) = make_ws(\%script);
  my $out = $ws->search( query => 'q', limit => 10, fetch => 2 )->get;

  my @r = @{ $out->{results} };
  is scalar @r, 3, 'three results';
  ok $r[0]->fetched, 'top-1 fetched';
  ok $r[1]->fetched, 'top-2 fetched';
  ok !$r[2]->fetched, 'top-3 not fetched (fetch=2)';

  is $r[0]->fetched->{ok}, 1, 'ok flag set';
  is $r[0]->fetched->{status}, 200, 'status recorded';
  like $r[0]->fetched->{body}, qr/A-body/, 'body captured';
  is $r[0]->fetched->{content_type}, 'text/html; charset=utf-8', 'content-type';
  is $r[0]->fetched->{charset}, 'utf-8', 'charset parsed';
  is $out->{stats}{fetched}, 2, 'stats.fetched counted';
};

subtest 'fetch records http failures on the Result' => sub {
  my %script = (
    'https://example.com/a' => { code => 500, msg => 'Server Error', body => 'boom' },
    'https://example.com/b' => { body => 'B' },
    'https://example.com/c' => { body => 'C' },
  );
  my ( $ws ) = make_ws(\%script);
  my $out = $ws->search( query => 'q', fetch => 3 )->get;
  my @r = @{ $out->{results} };
  is $r[0]->fetched->{ok}, 0, '500 → not ok';
  is $r[0]->fetched->{status}, 500, 'status captured';
  like $r[0]->fetched->{error}, qr/500/, 'error string set';
  is $r[1]->fetched->{ok}, 1, 'second still ok';
};

subtest 'fetch records transport errors (do_request fail) on the Result' => sub {
  my %script = (
    'https://example.com/a' => { fail => 'connection refused' },
    'https://example.com/b' => { body => 'B' },
    'https://example.com/c' => { body => 'C' },
  );
  my ( $ws ) = make_ws(\%script);
  my $out = $ws->search( query => 'q', fetch => 2 )->get;
  my $a = $out->{results}[0];
  is $a->fetched->{ok}, 0, 'transport fail → not ok';
  is $a->fetched->{status}, undef, 'no status on transport fail';
  like $a->fetched->{error}, qr/connection refused/, 'error preserved';
};

subtest 'fetch_max_bytes truncates body' => sub {
  my $big = 'x' x 10_000;
  my %script = (
    'https://example.com/a' => { body => $big },
    'https://example.com/b' => { body => 'B' },
    'https://example.com/c' => { body => 'C' },
  );
  my ( $ws ) = make_ws(\%script);
  my $out = $ws->search( query => 'q', fetch => 1, fetch_max_bytes => 100 )->get;
  is length($out->{results}[0]->fetched->{body}), 100, 'body truncated to cap';
};

subtest 'fetch_user_agent propagates' => sub {
  my %script = map { ( "https://example.com/$_" => { body => $_ } ) } qw( a b c );
  my ( $ws, $mock ) = make_ws(\%script);
  $ws->search( query => 'q', fetch => 1, fetch_user_agent => 'custom-agent/9.9' )->get;
  my ($fetch_log) = grep { $_->{url} eq 'https://example.com/a' } @{ $mock->log };
  is $fetch_log->{headers}{'User-Agent'}, 'custom-agent/9.9', 'UA used for fetch';
};

subtest 'stream mode fires on_fetch and populates fetched' => sub {
  my %script = map { ( "https://example.com/$_" => { body => $_ } ) } qw( a b c );
  my ( $ws ) = make_ws(\%script);
  my @got;
  my @fetched;
  $ws->search(
    mode      => 'stream',
    query     => 'q',
    fetch     => 2,
    on_result => sub { push @got, $_[0]->url },
    on_fetch  => sub { push @fetched, $_[0]->url },
  )->get;
  is scalar @got, 3, 'all 3 streamed';
  is scalar @fetched, 2, 'exactly 2 on_fetch calls';
  is_deeply [sort @fetched],
            ['https://example.com/a','https://example.com/b'],
            'first 2 unique URLs fetched';
};

subtest 'race mode + fetch works on winner results' => sub {
  my %script = map { ( "https://example.com/$_" => { body => $_ } ) } qw( a b c );
  my ( $ws ) = make_ws(\%script);
  my $out = $ws->search( mode => 'race', query => 'q', fetch => 1 )->get;
  is $out->{provider}, 'fake', 'race returned winner';
  ok $out->{results}[0]->fetched, 'winner top-1 fetched';
  is $out->{results}[0]->fetched->{ok}, 1, 'ok';
};

subtest 'no fetch arg → no fetched attribute' => sub {
  my ( $ws ) = make_ws({});
  my $out = $ws->search( query => 'q' )->get;
  ok !$out->{results}[0]->fetched, 'no fetch by default';
  ok !exists $out->{stats}{fetched}, 'no fetched stat';
};

done_testing;
