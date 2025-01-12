#!perl

use v5.16;
use warnings;
use Parse::Syslog::Line;
use Time::HiRes qw(gettimeofday tv_interval);
psl_enable_sdata();

use FindBin;
use lib "$FindBin::Bin/../t/lib";
use test::Data;

# Disable warnings
$ENV{PARSE_SYSLOG_LINE_QUIET} = 1;

my @msgs = map { $_->{string} } values %{ get_test_data() };

my $count = 20_000;
my $start = [gettimeofday];
my $total = $count * @msgs;
for( 1..$count ) {
    parse_syslog_line($_) for @msgs
}
my $elapsed = tv_interval( $start, [gettimeofday] );

printf "Took $elapsed seconds to parse $total messages. (%0.2f mps)\n", $total / $elapsed;
