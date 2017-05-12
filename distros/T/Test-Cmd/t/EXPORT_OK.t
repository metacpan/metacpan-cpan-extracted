# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 5, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd qw(match_exact match_regex);
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, @lines, @regexes);

$test = Test::Cmd->new;
ok($test);

$test->match_sub(\&match_exact);

$ret = $test->match("abcde\n", "a.*e\n");
ok(! $ret);

$ret = $test->match("abcde\n", "abcde\n");
ok($ret);


$test->match_sub(\&match_regex);

$ret = $test->match("abcde\n", "a.*e\n");
ok($ret);
