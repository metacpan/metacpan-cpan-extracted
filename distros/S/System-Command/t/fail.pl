#!perl
use strict;
use warnings;

my ($status, $delay) = @ARGV;

sleep $delay;
exit $status;

