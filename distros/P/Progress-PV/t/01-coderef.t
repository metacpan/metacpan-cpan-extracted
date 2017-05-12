#!perl

use strict;
use warnings;
use Progress::PV;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Progress::PV' );
}

my $pv = Progress::PV->new();

my $stderr;
$pv->stderr(sub { $stderr .= $_[0] });

my $stdout;
$pv->stdout(sub { $stdout .= $_[0] });

$pv->{options} = {'-V' => 1};
$pv->pr();
is($? >> 8, 0, "pv found");
