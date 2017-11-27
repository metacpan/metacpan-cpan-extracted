use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('class accessor with antlers', <<'END', {'Class::Accessor' => 0, 'Test::More' => 0});
use Class::Accessor 'antlers';
extends 'Test::More';
END

test('class accessor moose-like with version', <<'END', {'Class::Accessor' => 0.34, 'Test::More' => 0});
use Class::Accessor 0.34 'mooselike';
extends 'Test::More';
END

done_testing;
