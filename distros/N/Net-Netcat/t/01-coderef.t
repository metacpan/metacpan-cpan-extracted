#!perl

use strict;
use warnings;
use Net::Netcat;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Net::Netcat' );
}

my $nc = Net::Netcat->new();

my $stderr;
$nc->stderr(sub { $stderr .= $_[0] });

my $stdout;
$nc->stdout(sub { $stdout .= $_[0] });

$nc->{options} = {'-v' => 1};

$nc->exec();
is($? >> 8, 1, "Netcat found");
