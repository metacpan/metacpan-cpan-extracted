use Test;
use strict;

## These are tests that I want to run, but I don't really care if
## others run them.  So, unless they have IPC::Run3, don't bother.
my $has_ipc_run3;
BEGIN { $has_ipc_run3 = eval "use IPC::Run3; 1"; }

my $test_machine="t/bin-stml-test-machine.stml";
my @cmd = ( $^X, map( "-I$_", @INC ), "bin/stml" );

sub r {
    my $in = pop;
    my @c = ( @cmd, "--template=-", $test_machine, @_, "-" );
    run3( \@c, \$in, \my $out );
    return $out;
}

my @tests = (

## A basic machine templatification
sub { ok r( <<END_TEMPLATE ), "s0" },
[% FOR s = machine.states %][% s.id %][% END -%]
END_TEMPLATE

## modes
sub { ok r( <<END_TEMPLATE ), "s0s1" },
[% META modes = "C" %][% FOR s = machine.states %][% s.id %][% END -%]
END_TEMPLATE

## --define
sub { ok r( "--define", "A=B", <<END_TEMPLATE ), "B" },
[% A -%]
END_TEMPLATE

## ENV.foo
sub { local $ENV{A} = "B"; ok r( <<END_TEMPLATE ), "B" },
[% ENV.A -%]
END_TEMPLATE

## Machine concatenation
sub { ok r( "t/bin-stml-test-machine2.stml", <<END_TEMPLATE ), "s02s0" },
[% FOR s = machine.states %][% s.id %][% END -%]
END_TEMPLATE

## no $interp by default
sub { ok r( '$id' ), '$id' },
sub { ok r( "--interpolate-vars", '$machine.id' ), "m0" },


);

plan tests => 0+@tests;

$has_ipc_run3 ? $_->() : skip "Need IPC::Run3 to test", 1, 1 for @tests;
