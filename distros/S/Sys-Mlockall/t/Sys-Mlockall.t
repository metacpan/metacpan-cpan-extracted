#!/usr/bin/perl

use strict;
use warnings (FATAL => 'all');

use Test::More;
use Sys::Mlockall qw(:all);
use Config;

my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
  $secure_perl_path .= $Config{_exe}
    unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

eval "use BSD::Resource";
if($@) {
  plan skip_all => 'Failed to load BSD::Resource';
} else {
  diag "Loaded BSD::Resource";
  if(setrlimit(RLIMIT_MEMLOCK(), 1048576 * 32, 1048576 * 32)) {
    diag "Set RLIMIT_MEMLOCK to 32MB";
  } else {
    plan skip_all => "Failed to set RLIMIT_MEMLOCK: $!";
  }
}

plan 'no_plan';

my $rv;

diag "$secure_perl_path t/ext/mlockall-first.pl";
$rv = system($secure_perl_path, 't/ext/mlockall-first.pl');

my($eval, $sig, $core) = ($? >> 8, $? & 127, $? & 128);
diag "exit value: $eval, signal: $sig, core: $core";
isnt($eval, 0, "script crashed as expected");

diag "Dropping root permissions";
$< = $> = 65534;

$rv = mlockall(MCL_FUTURE | MCL_CURRENT);
diag "mlockall: $!" if($rv);
is($rv, 0, "successfully locked RAM");

$rv = munlockall();
diag "munlockall: $!" if($rv);
is($rv, 0, "successfully unlocked RAM");

diag "allocate 64MB";
my $buffer = "x" x (1048576*64);

$rv = mlockall(MCL_FUTURE | MCL_CURRENT);
diag "mlockall: $!" if($rv);
is($rv, -1, "failed to lock RAM");

