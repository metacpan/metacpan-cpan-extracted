# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN {
	$| = 1;
	eval "use Algorithm::DiffOld";
	$diffold = ! $@;
	plan tests => 24, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, @lines, @regexes, @diff);

$ret = Test::Cmd->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
1
2
3
_EOF_
1
2
3
_EOF_
ok($ret);
ok(@diff == 0);

$ret = Test::Cmd->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
1
2
3
_EOF_
1
222
3
_EOF_
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
2c2
< 222
---
> 2
_EOF_
Expected =====
1
2
3
Actual =====
1
222
3
_EOF_

$test = Test::Cmd->new;
ok($test);

$ret = $test->diff_exact("abcde\n", "a.*e\n", \@diff);
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
1c1
< a.*e
---
> abcde
_EOF_
Expected =====
abcde
Actual =====
a.*e
_EOF_

$ret = $test->diff_exact("abcde\n", "abcde\n", \@diff);
ok($ret);
ok(! @diff);

$ret = $test->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
12345
abcde
_EOF_
1\d+5
a.*e
_EOF_
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
1,2c1,2
< 1\d+5
< a.*e
---
> 12345
> abcde
_EOF_
Expected =====
1\d+5
a.*e
Actual =====
12345
abcde
_EOF_

$ret = $test->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
12345
abcde
_EOF_
12345
abcde
_EOF_
ok($ret);
ok(! @diff);

@lines = ( "vwxyz\n", "67890\n" );
@regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

$ret = $test->diff_exact(\@lines, \@regexes, \@diff);
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
1,2c1,2
< v[^a-u]*z
< 6\S+0
---
> vwxyz
> 67890
_EOF_
Expected =====
v[^a-u]*z
6\S+0
Actual =====
vwxyz
67890
_EOF_

$ret = $test->diff_exact(\@lines, \@lines, \@diff);
ok($ret);
ok(! @diff);

$ret = $test->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
1
a
b
2
3
c
4
5
_EOF_
1
2
x
3
4
y
z
5
_EOF_
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
1a2,3
> a
> b
3d4
< x
4a6
> c
6,7d7
< y
< z
_EOF_
Expected =====
1
2
x
3
4
y
z
5
Actual =====
1
a
b
2
3
c
4
5
_EOF_

$ret = $test->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
1
2
a
3
4
b
c
5
_EOF_
1
x
y
2
3
z
4
5
_EOF_
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
2,3d1
< x
< y
4a3
> a
6d4
< z
7a6,7
> b
> c
_EOF_
Expected =====
1
x
y
2
3
z
4
5
Actual =====
1
2
a
3
4
b
c
5
_EOF_

$ret = $test->diff_exact(<<'_EOF_', <<'_EOF_', \@diff);
a
b
c
e
h
j
l
m
n
p
_EOF_
b
c
d
e
f
j
k
l
m
r
s
t
_EOF_
ok(! $ret);
ok(join('', @diff) eq $diffold ? <<'_EOF_' : <<'_EOF_');
0a1
> a
3d3
< d
5c5
< f
---
> h
7d6
< k
10,12c9,10
< r
< s
< t
---
> n
> p
_EOF_
Expected =====
b
c
d
e
f
j
k
l
m
r
s
t
Actual =====
a
b
c
e
h
j
l
m
n
p
_EOF_
