use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('experimental singlequotes', <<'END', {experimental => 0});
use experimental 'say';
END

test('experimental doublequotes', <<'END', {experimental => 0});
use experimental "say";
END

test('experimental qw()', <<'END', {experimental => 0});
use experimental qw(say);
END

test('experimental multilined qw()', <<'END', {experimental => 0});
use experimental qw(
  say
);
END

test('experimental + ()', <<'END', {experimental => 0});
use experimental ();
END

done_testing;
