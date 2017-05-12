# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 13, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, @lines, @regexes);

$test = Test::Cmd->new;
ok($test);

$test->match_sub(\&Test::Cmd::match_exact);

$ret = $test->match("abcde\n", "a.*e\n");
ok(! $ret);

$ret = $test->match("abcde\n", "abcde\n");
ok($ret);

$ret = $test->match(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
1\d+5
a.*e
_EOF_
ok(! $ret);

$ret = $test->match(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
12345
abcde
_EOF_
ok($ret);

@lines = ( "vwxyz\n", "67890\n" );
@regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

$ret = $test->match(\@lines, \@regexes);
ok(! $ret);

$ret = $test->match(\@lines, \@lines);
ok($ret);


$test->match_sub(\&Test::Cmd::match_regex);

$ret = $test->match("abcde\n", "a.*e\n");
ok($ret);

$ret = $test->match(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
1\d+5
a.*e
_EOF_
ok($ret);

@lines = ( "vwxyz\n", "67890\n" );
@regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

$ret = $test->match(\@lines, \@regexes);
ok($ret);


$test->match_sub(sub { $_[1] eq $_[2] });

$ret = $test->match("foo\n", "foo\n");
ok($ret);

$ret = $test->match("foo\n", "bar\n");
ok(! $ret);
