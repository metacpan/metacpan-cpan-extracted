use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('builtin singlequotes', <<'END', {builtin => 0});
use builtin 'true';
END

test('builtin doublequotes', <<'END', {builtin => 0});
use builtin "true";
END

test('builtin qw()', <<'END', {builtin => 0});
use builtin qw(true);
END

test('builtin multilined qw()', <<'END', {builtin => 0});
use builtin qw(
  true
);
END

test('builtin + ()', <<'END', {builtin => 0});
use builtin ();
END

done_testing;
