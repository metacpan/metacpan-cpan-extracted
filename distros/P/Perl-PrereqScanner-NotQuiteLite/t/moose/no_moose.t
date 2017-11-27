use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('no moose', <<'END', {Moose => 0, Foo => 0});
use Moose;
extends qw/Foo/;
no Moose;
extends qw/Bar/; # this should be from something else
END

done_testing;
