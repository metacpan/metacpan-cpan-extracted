#!/usr/bin/perl -w

use strict;
use Test::More tests => 14;
use FindBin qw($Bin);

my $sep = $^O eq 'MSWin32' ? ';' : ':';
$ENV{PERL5LIB} = join($sep, "$Bin/../lib", grep { defined } $ENV{PERL5LIB});

# test normal use - failure
my $output = `$^X t/someclass.pl 2>&1`;
is($output, "1..0 # Skip missing/broken dependancies; SomeClass\n",
   "include SomeClass (missing) bails out");
is($?, 0, "correct RC");

$ENV{PERL5LIB} = join($sep, $Bin, grep { defined } $ENV{PERL5LIB});

$output = `$^X t/someclass.pl 2>&1`;
is($output, "1..1\nok 1\n",
   "include SomeClass (present) succeeds");
is($?, 0, "correct RC");

$output = `$^X t/someclass-version.pl 1.00 2>&1`;
is($output, "1..1\nok 1\n",
   "include SomeClass 1.00 (present) succeeds");
is($?, 0, "correct RC");

$output = `$^X t/someclass-version.pl 1.01 2>&1`;
is($output, "1..0 # Skip missing/broken dependancies; SomeClass (1.00 < 1.01)\n",
   "include SomeClass 1.01 (insufficient version) bails out");
is($?, 0, "correct RC");

$output = `$^X t/someclass-import.pl somefunc 2>&1`;
is($output, "1..1\nok 1 - somefunc sure is func-y\n",
   "include SomeClass qw(somefunc) succeeds");
is($?, 0, "correct RC");

$output = `$^X t/someclass-import.pl somebadfunc 2>&1`;
like($output, qr/import failure/,
     "include SomeClass qw(somebadfunc) failed");
is($?, 0, "correct RC");

$output = `$^X t/twoclasses.pl 2>&1`;
is($output, "1..1\nok 1\n",
   "include SomeClass 1.00 (present) succeeds");
is($?, 0, "correct RC");
