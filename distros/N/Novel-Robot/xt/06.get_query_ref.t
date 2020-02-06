#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot::Parser;
use Test::More ;
use Data::Dumper;

## {{{ ljj
my $pr = Novel::Robot::Parser->new(site=>'jjwxc');

my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';

my $query_ref = $pr->get_query_ref('顾漫', query_type=> '作者');
my $cnt = grep { $_->{url} eq $index_url } @$query_ref;
is($cnt, 1, 'query_writer');

## }}}

done_testing;
