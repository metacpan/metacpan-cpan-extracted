#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::Simple tests => 4;
use Shadowd::Connector;

my $shadowd = Shadowd::Connector->new();

ok($shadowd->unescape_key('foo') eq 'foo');
ok($shadowd->unescape_key('foo\\|bar') eq 'foo|bar');
ok($shadowd->unescape_key('foo\\\\bar') eq 'foo\\bar');
ok($shadowd->unescape_key('foo\\\\\\|bar') eq 'foo\\|bar');
