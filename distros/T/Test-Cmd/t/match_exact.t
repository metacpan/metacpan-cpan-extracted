# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 10, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, @lines, @regexes);

$ret = Test::Cmd->match_exact("abcde\n", "a.*e\n");
ok(! $ret);

$ret = Test::Cmd->match_exact("abcde\n", "abcde\n");
ok($ret);

$test = Test::Cmd->new;
ok($test);

$ret = $test->match_exact("abcde\n", "a.*e\n");
ok(! $ret);

$ret = $test->match_exact("abcde\n", "abcde\n");
ok($ret);

$ret = $test->match_exact(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
1\d+5
a.*e
_EOF_
ok(! $ret);

$ret = $test->match_exact(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
12345
abcde
_EOF_
ok($ret);

@lines = ( "vwxyz\n", "67890\n" );
@regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

$ret = $test->match_exact(\@lines, \@regexes);
ok(! $ret);

$ret = $test->match_exact(\@lines, \@lines);
ok($ret);
