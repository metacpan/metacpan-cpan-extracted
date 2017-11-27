use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('with qw', <<'END', {'autouse' => 0}, {}, {'Carp' => 0});
use autouse 'Carp' => qw(carp croak);
END

test('with qw', <<'END', {'autouse' => 0}, {}, {'Data::Dumper' => 0});
use autouse 'Data::Dumper';
END

done_testing;
