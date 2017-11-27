use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('without arg', <<'END', {'later' => 0}, {}, {'Carp' => 0});
use later 'Carp';
END

test('with an optional hash', <<'END', {'later' => 0}, {}, {'Data::Dumper' => 0});
use later 'Data::Dumper', do_fuss => 1;
END

done_testing;
