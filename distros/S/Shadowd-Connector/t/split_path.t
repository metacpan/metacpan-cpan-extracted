#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::Simple tests => 6;
use Shadowd::Connector;

my $shadowd = Shadowd::Connector->new();

my @test1 = $shadowd->split_path('foo');
ok(($#test1 == 0) && ($test1[0] eq 'foo'));

my @test2 = $shadowd->split_path('foo|bar');
ok(($#test2 == 1) && ($test2[0] eq 'foo') && ($test2[1] eq 'bar'));

my @test3 = $shadowd->split_path('foo\\|bar');
ok(($#test3 == 0) && ($test3[0] eq 'foo\\|bar'));

my @test4 = $shadowd->split_path('foo\\\\|bar');
ok(($#test4 == 1) && ($test4[0] eq 'foo\\\\') && ($test4[1] eq 'bar'));

my @test5 = $shadowd->split_path('foo\\\\\\|bar');
ok(($#test5 == 0) && ($test5[0] eq 'foo\\\\\\|bar'));

my @test6 = $shadowd->split_path('foo\\');
ok(($#test6 == 0) && ($test6[0] eq 'foo\\'));
