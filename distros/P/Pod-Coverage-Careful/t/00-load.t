#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";

my @modules = qw(
    Pod::Coverage::Careful
);

plan tests => scalar(@modules);

my @failed;
for my $module (@modules) {
    require_ok($module) || push @failed, $module;
}

if (@failed) {
    BAIL_OUT(sprintf("Cannot run test suite without module%s %s.\n",
                     @failed != 1 && "s", join(", " => @failed)));
}

done_testing();

__END__

