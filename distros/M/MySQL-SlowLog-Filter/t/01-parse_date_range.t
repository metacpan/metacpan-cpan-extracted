#!perl -T

use Test::More tests => 21;
use Time::Local;
use MySQL::SlowLog::Filter qw/parse_date_range parse_time/;

my $repo  = timelocal(0, 0, 0, 13, 10, 106);
my $repo2 = timelocal(0, 0, 0, 1, 11, 108);
my $epoch = parse_time('13.11.2006');
is $epoch, $repo;
$epoch = parse_time('13-11-2006');
is $epoch, $repo;
$epoch = parse_time('13/11/2006');
is $epoch, $repo;

my ( $start, $end ) = parse_date_range();
is $start, 0;
is $end, 9999999999;

( $start, $end ) = parse_date_range('<13-11-2006');
is $start, 0;
is $end, $repo;

( $start, $end ) = parse_date_range('>13/11/2006');
is $start, $repo;
is $end, 9999999999;

( $start, $end ) = parse_date_range('13/11/2006');
is $start, $repo;
is $end, 9999999999;

( $start, $end ) = parse_date_range('-13.11.2006');
is $start, 0;
is $end, $repo;

( $start, $end ) = parse_date_range('13.11.2006-1.12.2008');
is $start, $repo;
is $end, $repo2;

( $start, $end ) = parse_date_range('13.11.2006-01.12.2008');
is $start, $repo;
is $end, $repo2;

( $start, $end ) = parse_date_range('13/11/2006-01-12-2008');
is $start, $repo;
is $end, $repo2;

( $start, $end ) = parse_date_range('13/11/2006-');
is $start, $repo;
is $end, 9999999999;

1;