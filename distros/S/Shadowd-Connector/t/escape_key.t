#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::Simple tests => 5;
use Shadowd::Connector;

my $shadowd = Shadowd::Connector->new();

ok($shadowd->escape_key('foo') eq 'foo');
ok($shadowd->escape_key('foo|bar') eq 'foo\\|bar');
ok($shadowd->escape_key('foo\\|bar') eq 'foo\\\\\\|bar');
ok($shadowd->escape_key('foo||bar') eq 'foo\\|\\|bar');
ok($shadowd->escape_key('foo\\\\bar') eq 'foo\\\\\\\\bar');
