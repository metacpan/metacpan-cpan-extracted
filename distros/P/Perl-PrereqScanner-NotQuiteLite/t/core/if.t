use strict;
use warnings;
use Test::More;
use t::Util;

local $t::Util::EVAL = 1;

test('if cond => namespace', <<'END', {if => 0, Exporter => 0});
use if $] => Exporter;
END

test('if cond => string', <<'END', {if => 0, Exporter => 0});
use if $] => "Exporter";
END

test('if cond => namespace', <<'END', {if => 0, 'Test::More' => 0});
use if $] => Test::More;
END

test('if cond => string', <<'END', {if => 0, 'Test::More' => 0});
use if $] => "Test::More";
END

test('cond may have commas', <<'END', {if => 0, 'Test::More' => 0});
use if [1, 2 => 3] => "Test::More";
END

test('cond may have commas', <<'END', {if => 0, 'Test::More' => 0});
use if [1, 2 => qw/foo/] => "Test::More";
END

done_testing;
