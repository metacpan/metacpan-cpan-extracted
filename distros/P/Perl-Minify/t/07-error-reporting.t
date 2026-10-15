#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify minify_sub minify_error);

# Note: PPI is very lenient and parses most things, so we test with
# scenarios that cause actual failures in our code paths

# 1. Empty input
my $r1 = minify('');
ok(defined($r1), 'empty code returns defined (empty result)');
my $err = minify_error();
is($err, '', 'no error for empty code');

# 2. Nonexistent subroutine
my $r2 = minify_sub('sub foo { }', 'bar');
ok(!defined($r2), 'nonexistent sub returns undef');
$err = minify_error();
ok($err, 'error message is set for missing sub');
like($err, qr/not found/, 'error message mentions not found') or diag "got: $err";
like($err, qr/bar/, 'error message includes sub name') or diag "got: $err";

# 3. Valid code clears error
my $r3 = minify('my $x = 1;');
ok(defined($r3), 'valid code returns defined');
$err = minify_error();
is($err, '', 'error is cleared on success');

# 4. Test optimize option doesn't break things
my $r4 = minify('my $x = 2 + 3;', { optimize => 1 });
ok(defined($r4), 'optimize option works');
like($r4, qr/(2\+3|5)/, 'constant folding attempted') or diag "got: $r4";

done_testing;
