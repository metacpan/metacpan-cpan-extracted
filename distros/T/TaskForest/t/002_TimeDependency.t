# -*- perl -*-

# make sure TimeDependency works
use Test::More tests => 13;
use strict;
use warnings;

BEGIN {
    use_ok( 'TaskForest::TimeDependency',     "Can use TimeDependency" );
}

my $td = TaskForest::TimeDependency->new(
    start => '01:00',
    tz => 'UTC',
    );


isa_ok ($td, 'TaskForest::TimeDependency',         'TaskForest::TimeDependency object created properly');

is ($td->{start},     '01:00',      '   start is ok');
is ($td->{tz},        'UTC',        '   tz is ok');
is ($td->{rc},        '',           '   rc is ok');
is ($td->{status},    'Waiting',    '   status is waiting');

my $now = time;
$td->{ep} = $now + 3600;
$td->check();

is($td->{status},    'Waiting',     '   still waiting');

$td->{ep} = time;
$td->check();
is($td->{status},    'Success',     '   success');

$td->{ep} += 10;
$td->check();
is($td->{status},    'Success',     '   still success');

$td->{ep} -= 10;
$td->check();
is($td->{status},    'Success',     '   still success');

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $dt = DateTime->new(year      => $year + 1900,
                       month     => $mon + 1,
                       day       => $mday,
                       hour      => 1,
                       minute    => 0,
                       time_zone => "UTC");
my $td2 = TaskForest::TimeDependency->new($dt);
isa_ok ($td2, 'TaskForest::TimeDependency',         'TaskForest::TimeDependency object created properly with copy constructor');
is ($td2->{start},     '01:00',      '   start is ok');
is($td2->{status},    'Waiting',     '   still waiting');
