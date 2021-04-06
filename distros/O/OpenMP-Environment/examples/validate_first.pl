#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use OpenMP::Environment ();

my $env = OpenMP::Environment->new;

# will "die" if any supported OpenMP Environmental Variable is set
# incorrectly; note: an environment in which NO variables are set is considered
# valid

# barrier, will make script die if current %ENV is not properly set
$env->assert_omp_environment;

print qq{The OpenMP Environment is valid\n};
