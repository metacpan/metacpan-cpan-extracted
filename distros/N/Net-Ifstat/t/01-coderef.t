#!perl

use strict;
use warnings;
use Net::Ifstat;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Net::Ifstat' );
}

my $if = Net::Ifstat->new();

my $stderr;
$if->stderr(sub { $stderr .= $_[0] });

my $stdout;
$if->stdout(sub { $stdout .= $_[0] });

$if->{options} = {'-v' => 1};

$if->exec();
is($? >> 8, 0, "Ifstat found");
