#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();
$internal->verbose(0);

my $yes = $internal->pl_file_compiles('t/scripts/subdir/success.pl');
is($yes,1,"success.pl should compile");

my $taint = $internal->pl_file_compiles('t/scripts/taint.pl');
is($taint,1,"taint.pl should compile - with -T enabled");

SKIP : {
    skip("-t was introduced in perl 5.8.0 ($])", 1) unless $] gt '5.008';

    my $taint2 = $internal->pl_file_compiles('t/scripts/CVS/taint2.pl');
    is($taint2,1,"taint2.pl should compile - with -t enabled");
}

my $no = $internal->pl_file_compiles('t/scripts/failure.pl');
is($no,0,"failure.pl should not compile");

my $not_found = $internal->pl_file_compiles('t/scripts/no_file_here.pl');
is($not_found,0,"no_file_here.pl should not compile");


done_testing();
