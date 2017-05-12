#!perl

use Test::More tests => 38;

use Test::Command;

use FindBin;

## determine whether we can run perl or not

system qq($^X -e 1) and BAIL_OUT('error calling perl via system');

my $test_perl = Test::Command->new( cmd => qq($^X -le "print qq(foo\nbar); print STDERR qq(bar\nfoo)") );

ok(defined $test_perl, 'defined $test_perl');

is(ref $test_perl, 'Test::Command', 'ref $test_perl');

$test_perl->run;

is( $test_perl->exit_value, 0, "exit_value" );

$test_perl->exit_is_num(0);
$test_perl->exit_isnt_num(1);
$test_perl->exit_cmp_ok('<', 1);

SKIP:
   {
   skip("not sure about Win32 signal support", 2) if $^O eq 'MSWin32';
   is( $test_perl->signal_value, undef, "signal_value" );
   $test_perl->signal_is_undef;
   }

is( $test_perl->stdout_value, "foo\nbar\n", "stdout_value" );
is( Test::Command::_slurp($test_perl->stdout_file), "foo\nbar\n", "stdout_file" );
$test_perl->stdout_is_eq("foo\nbar\n");
$test_perl->stdout_isnt_eq("bar\nfoo\n");
{
local $^W;
$test_perl->stdout_is_num(0);
$test_perl->stdout_isnt_num(1);
}
$test_perl->stdout_like(qr/foo\nBAR/i);
$test_perl->stdout_unlike(qr/foo\nBAR/);
$test_perl->stdout_cmp_ok('ne', "bar\nfoo\n");
$test_perl->stdout_is_file("$FindBin::Bin/stdout.txt");

is( $test_perl->stderr_value, "bar\nfoo\n", "stderr_value" );
is( Test::Command::_slurp($test_perl->stderr_file), "bar\nfoo\n", "stderr_file" );
$test_perl->stderr_is_eq("bar\nfoo\n");
$test_perl->stderr_isnt_eq("foo\nbar\n");
{
local $^W;
$test_perl->stderr_is_num(0);
$test_perl->stderr_isnt_num(1);
}
$test_perl->stderr_like(qr/BAR\nFOO/i);
$test_perl->stderr_unlike(qr/BAR\nFOO/);
$test_perl->stderr_cmp_ok('ne', "foo\nbar\n");
$test_perl->stderr_is_file("$FindBin::Bin/stderr.txt");

## test object with ARRAY ref command

$test_perl = Test::Command->new( cmd => [$^X,
                                         '-le',
                                         'print qq(foo\nbar); print STDERR qq(bar\nfoo)' ] );

ok(defined $test_perl, 'defined $test_perl');

is(ref $test_perl, 'Test::Command', 'ref $test_perl');

## lazily run at first test

$test_perl->exit_is_num(0);
$test_perl->stdout_is_eq("foo\nbar\n");
$test_perl->stderr_is_eq("bar\nfoo\n");

package Test::Command::Derived;

use base Test::Command;

package main;

$test_perl = Test::Command::Derived->new( cmd => qq($^X -le "print qq(foo\nbar); print STDERR qq(bar\nfoo)") );

ok(defined $test_perl, 'defined $test_perl');

is(ref $test_perl, 'Test::Command::Derived', 'ref $test_perl');

$test_perl->run;

$test_perl->exit_is_num(0);
$test_perl->exit_isnt_num(1);
$test_perl->exit_cmp_ok('<', 1);
