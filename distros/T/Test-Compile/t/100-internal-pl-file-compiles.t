#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();
$internal->verbose(0);

# Given (success.pl)
# When
my $yes = $internal->pl_file_compiles('t/scripts/subdir/success.pl');
# Then
is($yes,1,"success.pl should compile");

# Given (taint.pl - script has -t in shebang)
# When
my $taint = $internal->pl_file_compiles('t/scripts/taint.pl');
# Then
is($taint,1,"taint.pl should compile - with -T enabled");

# Given (taint2.pl - script has -T in shebang)
# When
my $taint2 = $internal->pl_file_compiles('t/scripts/CVS/taint2.pl');
# Then
is($taint2,1,"taint2.pl should compile - with -t enabled");

# Given (failure.pl doesn't compile)
# When
my $failure = $internal->pl_file_compiles('t/scripts/failure.pl');
# Then
is($failure,0,"failure.pl should not compile");

# Given (no_file_here.pl doesn't exist)
# When
my $not_found = $internal->pl_file_compiles('t/scripts/no_file_here.pl');
# Then
is($not_found,0,"no_file_here.pl should not compile");


done_testing();
