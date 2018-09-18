use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('exclude inner package', <<'END', {'Moose' => 0, 'Exporter' => 0});
package Foo;

package main;
use Moose;
extends 'Foo';
with 'Exporter';
END

test('exclude inner package with comment', <<'END', {'Moose' => 0, 'Exporter' => 0});
package # hide from PAUSE
  Foo;

package main;
use Moose;
extends 'Foo';
with 'Exporter';
END

done_testing;
