#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider;
use Net::Async::WebSearch::Result;

{
  package Test::WS::FakeSearxNG;
  use parent 'Net::Async::WebSearch::Provider';
  use Future;
  use Net::Async::WebSearch::Result;
  sub default_name { 'searxng' }
  sub search {
    my ( $self, $http, $query, $opts ) = @_;
    my $limit = $opts->{limit} // 10;
    my $tag   = $self->{endpoint_tag} || $self->name;
    my @rows;
    for my $i ( 1 .. 3 ) {
      push @rows, Net::Async::WebSearch::Result->new(
        url      => "https://$tag.example/$i",
        title    => "$tag result $i",
        snippet  => "snip $i",
        provider => $self->name,
        rank     => $i,
      );
    }
    @rows = splice @rows, 0, $limit if @rows > $limit;
    return Future->done(\@rows);
  }
}

{
  package Test::WS::FakeSerper;
  use parent 'Net::Async::WebSearch::Provider';
  use Future;
  use Net::Async::WebSearch::Result;
  sub default_name { 'serper' }
  sub search {
    my ( $self, $http, $query, $opts ) = @_;
    return Future->done([
      Net::Async::WebSearch::Result->new(
        url => 'https://serper.example/'.$self->name, title => 'x',
        provider => $self->name, rank => 1,
      ),
    ]);
  }
}

my $loop = IO::Async::Loop->new;

my $searx_eu = Test::WS::FakeSearxNG->new(
  name         => 'searx-eu',
  endpoint_tag => 'eu',
  tags         => ['private', 'eu'],
);
my $searx_us = Test::WS::FakeSearxNG->new(
  name         => 'searx-us',
  endpoint_tag => 'us',
  tags         => ['private', 'us'],
);
my $searx_pub = Test::WS::FakeSearxNG->new(
  endpoint_tag => 'pub',
  tags         => ['public'],
);  # default name 'searxng'
my $serper_a = Test::WS::FakeSerper->new(
  name => 'serper-a',
  tags => ['paid'],
);
my $serper_b = Test::WS::FakeSerper->new(
  tags => ['paid'],
);  # default name 'serper'
my $serper_c = Test::WS::FakeSerper->new(
  tags => ['paid'],
);  # would collide → auto-renamed

my $ws = Net::Async::WebSearch->new;
$loop->add($ws);
$ws->add_provider($_) for ( $searx_eu, $searx_us, $searx_pub, $serper_a, $serper_b, $serper_c );

subtest 'add_provider auto-renames collisions' => sub {
  my @names = map { $_->name } $ws->providers;
  is scalar(grep { $_ eq 'serper' } @names),    1, 'one bare "serper"';
  is scalar(grep { $_ eq 'serper#2' } @names),  1, 'second gets #2';
  is scalar(grep { $_ eq 'searxng' } @names),   1, 'one bare "searxng"';
  is scalar(grep { $_ eq 'searx-eu' } @names),  1, 'explicit names untouched';
};

subtest 'class-leaf selector hits every instance' => sub {
  my @s = $ws->providers_matching('searxng');
  is scalar @s, 3, 'all three SearxNG instances match class leaf';
  my @p = $ws->providers_matching('serper');
  is scalar @p, 3, 'all three Serper instances match class leaf';
};

subtest 'tag selector drops groups' => sub {
  my $out = $ws->search( query => 'q', exclude => ['paid'] )->get;
  my %seen = map { $_->provider => 1 } @{ $out->{results} };
  ok !grep({ /^serper/ } keys %seen), 'no serper instance after excluding paid';
  is scalar(grep { /^(searx|searxng)/ } keys %seen), 3, 'all three searxng instances fired';
};

subtest 'tag selector selects subgroup' => sub {
  my $out = $ws->search( query => 'q', only => ['private'] )->get;
  my %seen = map { $_->provider => 1 } @{ $out->{results} };
  ok $seen{'searx-eu'} && $seen{'searx-us'}, 'private searxngs fired';
  ok !$seen{'searxng'}, 'public searx skipped';
  ok !grep({ /^serper/ } keys %seen), 'no serpers';
};

subtest 'specific name still works alongside stacked instances' => sub {
  my $out = $ws->search( query => 'q', only => ['searx-eu'] )->get;
  my %seen = map { $_->provider => 1 } @{ $out->{results} };
  is_deeply [sort keys %seen], ['searx-eu'], 'only searx-eu';
};

subtest 'provider_opts: tag key applies to group, name wins on overlap' => sub {
  my $seen = {};
  no warnings 'redefine';
  my $orig = \&Test::WS::FakeSerper::search;
  local *Test::WS::FakeSerper::search = sub {
    my ( $self, $http, $query, $opts ) = @_;
    $seen->{ $self->name } = { %$opts };
    return $orig->(@_);
  };
  $ws->search(
    query         => 'q',
    only          => ['paid'],
    provider_opts => {
      paid       => { limit => 5, region => 'de' },
      'serper-a' => { region => 'us' },
    },
  )->get;
  is $seen->{'serper-a'}{limit},  5,   'tag-level limit reached serper-a';
  is $seen->{'serper-a'}{region}, 'us','name-level region overrode tag-level';
  is $seen->{'serper'}{region},   'de','bare serper kept tag-level region';
};

done_testing;
