#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider;
use Net::Async::WebSearch::Result;

# Scripted in-process provider — no HTTP.
{
  package Test::WS::Prov;
  use parent 'Net::Async::WebSearch::Provider';
  use Future;
  use Net::Async::WebSearch::Result;

  sub _init {
    my ( $self ) = @_;
    $self->{results_for} ||= {};
    $self->{fail}        ||= 0;
  }

  sub search {
    my ( $self, $http, $query, $opts ) = @_;
    return Future->fail( $self->name.": synthetic failure", 'websearch', $self->name )
      if $self->{fail};
    my $rows = $self->{results_for}{$query} || $self->{rows} || [];
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

my $loop = IO::Async::Loop->new;

my $p_a = Test::WS::Prov->new( name => 'alpha', rows => [
  { url => 'https://example.com/a', title => 'A', snippet => 'snip-a' },
  { url => 'https://example.com/b', title => 'B', snippet => 'snip-b' },
  { url => 'https://example.com/c', title => 'C', snippet => 'snip-c' },
]);
my $p_b = Test::WS::Prov->new( name => 'beta', rows => [
  { url => 'https://example.com/b', title => 'B-beta', snippet => 'snip-b-beta' },
  { url => 'https://example.com/d', title => 'D', snippet => 'snip-d' },
  { url => 'https://example.com/a/', title => 'A-dup', snippet => 'snip-a-dup' },
]);
my $p_fail = Test::WS::Prov->new( name => 'boom', fail => 1 );

my $ws = Net::Async::WebSearch->new(
  providers => [ $p_a, $p_b, $p_fail ],
);
$loop->add($ws);

subtest 'collect mode: dedup + RRF + errors' => sub {
  my $out = $ws->search( query => 'perl', limit => 10 )->get;

  is scalar @{ $out->{errors} }, 1, 'one provider failed';
  is $out->{errors}[0]{provider}, 'boom', 'failure attributed correctly';

  my @urls = map { $_->url } @{ $out->{results} };
  is scalar(grep { $_ eq 'https://example.com/a' || $_ eq 'https://example.com/a/' } @urls), 1,
    'trailing slash deduped';
  is scalar @urls, 4, 'four unique urls (a,b,c,d)';

  my ($a) = grep { $_->url =~ m{/a/?$} } @{ $out->{results} };
  my ($b) = grep { $_->url =~ m{/b$} }   @{ $out->{results} };
  ok $a && $b, 'found a and b';
  ok $a->score > 0, 'score set on a';
  ok defined $a->extra->{providers}, 'provider map recorded';
  ok exists $a->extra->{providers}{alpha} && exists $a->extra->{providers}{beta},
    'a seen by both providers';

  is $out->{stats}{providers},       3, '3 providers';
  is $out->{stats}{providers_error}, 1, '1 error';
};

subtest 'only / exclude lists' => sub {
  my $only_alpha = $ws->search( query => 'perl', only => ['alpha'] )->get;
  is scalar @{ $only_alpha->{results} }, 3, 'only=alpha → 3 results';
  is scalar @{ $only_alpha->{errors} },  0, 'no error from excluded boom';

  my $no_boom = $ws->search( query => 'perl', exclude => ['boom'] )->get;
  is scalar @{ $no_boom->{errors} }, 0, 'boom excluded → no error';
};

subtest 'enabled flag wins over allow-list' => sub {
  $p_a->enabled(0);
  my $out = $ws->search( query => 'perl', only => ['alpha','beta'] )->get;
  my %names = map { $_->provider => 1 } @{ $out->{results} };
  ok !$names{alpha}, 'disabled provider skipped even if in only';
  ok $names{beta},   'other allowed provider still queried';
  $p_a->enabled(1);
};

subtest 'stream mode fires on_result per unique url' => sub {
  my @seen;
  my $done = $ws->search_stream(
    query     => 'perl',
    exclude   => ['boom'],
    on_result => sub { push @seen, $_[0]->url },
  )->get;
  is scalar @seen, 4, 'four unique urls streamed';
  is scalar @{ $done->{errors} }, 0, 'no errors';
};

subtest 'race mode resolves with first success' => sub {
  my $out = $ws->search( query => 'perl', mode => 'race', exclude => ['boom'] )->get;
  ok $out->{provider}, 'race has a winning provider';
  ok scalar @{ $out->{results} }, 'race returned some results';
};

subtest 'limit caps the merged list' => sub {
  my $out = $ws->search( query => 'perl', limit => 2, exclude => ['boom'] )->get;
  is scalar @{ $out->{results} }, 2, 'limit honored';
};

done_testing;
