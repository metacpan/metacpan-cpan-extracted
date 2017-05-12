#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Sphinx::Log::Parser;
use FindBin qw/$Bin/;

my $parser = Sphinx::Log::Parser->new("$Bin/0.9.9.log");
my @sls;
while ( my $sl = $parser->next ) {
    push @sls, $sl;
}

is scalar @sls, 3;

# [Thu Sep 30 22:50:02.944 2010] 0.012 sec [ext/0/rel 65 (0,700)] [topiccomment;topiccommentdelta;] @text (opt & out)
is_deeply $sls[0],
  {
    'performances_counters' => undef,
    'total_matches'         => '65',
    'match_mode'            => 'ext',
    'query'                 => '@text (opt & out)',
    'query_date'            => 'Thu Sep 30 22:50:02.944 2010',
    'query_comment'         => undef,
    'filter_count'          => '0',
    'multiquery_factor'     => undef,
    'index_name'            => 'topiccomment;topiccommentdelta;',
    'limit'                 => '700',
    'groupby_attr'          => undef,
    'query_time'            => '0.012',
    'sort_mode'             => 'rel',
    'offset'                => '0'
  };

# [Fri Oct  1 03:18:46.342 2010] 0.014 sec [ext/2/rel 55 (0,700)] [topic;topicdelta;] [ios=0 kb=0.0 ioms=0.0] @title lucky
is_deeply $sls[1],
  {
    'performances_counters' => 'ios=0 kb=0.0 ioms=0.0',
    'total_matches'         => '55',
    'match_mode'            => 'ext',
    'query'                 => '@title lucky',
    'query_date'            => 'Fri Oct  1 03:18:46.342 2010',
    'query_comment'         => undef,
    'filter_count'          => '2',
    'multiquery_factor'     => undef,
    'index_name'            => 'topic;topicdelta;',
    'limit'                 => '700',
    'groupby_attr'          => undef,
    'query_time'            => '0.014',
    'sort_mode'             => 'rel',
    'offset'                => '0'
  };

# [Fri Oct  1 03:24:19.900 2010] 0.018 sec [ext/2/rel 1700 (0,700)] [topic;topicdelta;] [ios=0 kb=0.0 ioms=0.0 cpums=5.5] @title girl
is_deeply $sls[2],
  {
    'performances_counters' => 'ios=0 kb=0.0 ioms=0.0 cpums=5.5',
    'total_matches'         => '1700',
    'match_mode'            => 'ext',
    'query'                 => '@title girl',
    'query_date'            => 'Fri Oct  1 03:24:19.900 2010',
    'query_comment'         => undef,
    'filter_count'          => '2',
    'multiquery_factor'     => undef,
    'index_name'            => 'topic;topicdelta;',
    'limit'                 => '700',
    'groupby_attr'          => undef,
    'query_time'            => '0.018',
    'sort_mode'             => 'rel',
    'offset'                => '0'
  };

1;
