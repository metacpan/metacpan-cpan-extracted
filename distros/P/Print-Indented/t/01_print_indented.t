use strict;
use warnings;
use Test::More;
use IPC::Run qw(run);

subtest 'enable by -M' => sub {
    run [
        $^X, map("-I$_", @INC), '-MPrint::Indented', 't/data/a.pl'
    ], \my $in, \my $out, \my $err;

    is $out, <<OUT, 'stdout';
foo
    bar
OUT

    is $err, <<ERR, 'stderr';
    abc at t/data/a.pl line 10.
ERR
};

subtest 'indent outputs only from files imported' => sub {
    run [
        $^X, map("-I$_", @INC), 't/data/b.pl'
    ], \my $in, \my $out, \my $err;

    is $out, <<OUT, 'stdout';
    ---
    xxx
    ---
    yyy
foo
bar
OUT

    is $err, <<ERR, 'stderr'
abc at t/data/a.pl line 10.
ERR
};

subtest 'indent all by -M' => sub {
    run [
        $^X, map("-I$_", @INC), '-MPrint::Indented', 't/data/b.pl'
    ], \my $in, \my $out, \my $err;

    is $out, <<OUT, 'stdout';
    ---
    xxx
    ---
    yyy
foo
    bar
OUT

    is $err, <<ERR, 'stderr'
    abc at t/data/a.pl line 10.
ERR
};

done_testing;
