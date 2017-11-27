use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('with a string', <<'END', {aliased => 0, 'DateTime' => 0});
use aliased 'DateTime' => 'DT';
END

test('with bare name', <<'END', {aliased => 0, 'DateTime' => 0});
use aliased DateTime => 'DT';
END

test('with qw', <<'END', {aliased => 0, 'DateTime' => 0});
use aliased qw/DateTime/ => 'DT';
END

done_testing;
