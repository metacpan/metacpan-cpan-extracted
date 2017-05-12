#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();
$internal->verbose(0);

my $yes = $internal->pm_file_compiles('t/scripts/Module.pm');
ok($yes, "Module.pm should compile");

my $no = $internal->pm_file_compiles('t/scripts/CVS/Ignore.pm');
ok(!$no, "Ignore.pm should not compile");

my $notfound = $internal->pm_file_compiles('t/scripts/NotFound.pm');
ok(!$notfound, "NotFound.pm should not compile");

note "Does not call import"; {
    my $result = $internal->pm_file_compiles('t/scripts/LethalImport.pm');
    ok $result, "Does not call import() routines";
}

done_testing();
