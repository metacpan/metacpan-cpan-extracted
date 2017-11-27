use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('both extends and with', <<'END', {'Moose' => 0, 'Test::More' => 0, 'Exporter' => 0});
use Moose;
extends 'Test::More';
with 'Exporter';
END

test('with', <<'END', {'Moo::Role' => 0, 'Test::More' => 0});
use Moo::Role;
with 'Test::More';
END

test('extends', <<'END', {'Mo' => 0, 'Test::More' => 0});
use Mo;
extends 'Test::More';
END

test('Moose-like module that does not have Moose in its name', <<'END', {'Moxie' => 0, 'Test::More' => 0, 'Exporter' => 0});
use Moxie;
extends 'Test::More';
with 'Exporter';
END

test('Moose::Role-like module that does not have Role in its name', <<'END', {'Test::Routine' => 0, 'Test::More' => 0});
use Test::Routine;
with 'Test::More';
END

test('Mo-like module that does not have Moose in its name', <<'END', {'Pegex::Base' => 0, 'Test::More' => 0});
use Pegex::Base;
extends 'Test::More';
END

done_testing;
