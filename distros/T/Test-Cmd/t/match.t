# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 31, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, @lines, @regexes);

$test = Test::Cmd->new;
ok($test);

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

$test = Test::Cmd->new(match_sub => \&Test::Cmd::match_exact);
ok($test);

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

@orig_lines = ( "vwxyz\n", "67890\n" );
@orig_regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

@lines = @orig_lines;
@regexes = @orig_regexes;
$ret = $test->match(\@lines, \@regexes);
ok(! $ret);

ok($lines[0] eq $orig_lines[0]);
ok($lines[1] eq $orig_lines[1]);
ok($regexes[0] eq $orig_regexes[0]);
ok($regexes[1] eq $orig_regexes[1]);

@lines = @orig_lines;
@regexes = @orig_regexes;
$ret = $test->match(\@lines, \@lines);
ok($ret);

ok($lines[0] eq $orig_lines[0]);
ok($lines[1] eq $orig_lines[1]);
ok($regexes[0] eq $orig_regexes[0]);
ok($regexes[1] eq $orig_regexes[1]);

eval "use Algorithm::DiffOld";

if ($@) {

	for ($i = 0; $i < 11; $i++) {
		skip(1, 0);
	}

} else {

	$test = Test::Cmd->new(match_sub => \&Test::Cmd::diff_regex);
	ok($test);

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

	$test = Test::Cmd->new(match_sub => \&Test::Cmd::diff_exact);
	ok($test);

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

}
