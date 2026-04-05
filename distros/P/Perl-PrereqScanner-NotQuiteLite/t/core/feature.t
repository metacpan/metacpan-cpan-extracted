use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('feature singlequotes', <<'END', {feature => 0});
use feature 'say';
END

test('feature doublequotes', <<'END', {feature => 0});
use feature "say";
END

test('feature qw()', <<'END', {feature => 0});
use feature qw(say);
END

test('feature multilined qw()', <<'END', {feature => 0});
use feature qw(
  say
);
END

test('feature + ()', <<'END', {feature => 0});
use feature ();
END

done_testing;
