#!/usr/bin/env perl
#
# Statistics::Discrete
#
# Chiara Orsini, CAIDA, UC San Diego
# chiara@caida.org
#
# Copyright (C) 2014 The Regents of the University of California.
#
# Statistics::Discrete is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Statistics::Discrete is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Statistics::Discrete.  If not, see <http://www.gnu.org/licenses/>.
#

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Statistics-Discrete.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.00";

use FindBin;                     # locate this script
use lib "$FindBin::RealBin/../lib";  # use the parent directory

BEGIN { use_ok('Statistics::Discrete') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
#all_pod_files_ok();

#  ok($got eq $expected, $test_name);

my $s = Statistics::Discrete->new();
ok(defined($s), "Statistics::Discrete new()");

$s->add_data((2,5,7,2,1,7,3,3,7,333));
ok($s->count() == 10, "Statistics::Discrete->count()");
ok($s->mean() == 37, "Statistics::Discrete->mean()");
ok($s->minimum() == 1, "Statistics::Discrete->minimum()");
ok($s->maximum() == 333, "Statistics::Discrete->maximum()");
ok($s->median() == 4, "Statistics::Discrete->median()");
ok(sprintf("%.1f",$s->variance()) eq "9739.8", "Statistics::Discrete->variance()");
my $number_of_tests_run = 8;
done_testing( $number_of_tests_run );

