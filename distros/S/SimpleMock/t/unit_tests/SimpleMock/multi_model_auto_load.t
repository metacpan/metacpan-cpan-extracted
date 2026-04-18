use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::Most;
use SimpleMock;

# Loading TestMultiMock auto-loads SimpleMock::Mocks::TestMultiMock, which
# calls register_mocks with PATH_TINY + LWP_UA + DBI in a single call. All
# three should land in the base layer.
use TestMultiMock;

my %layer = %{ $SimpleMock::MOCK_STACK[0] };

ok exists $layer{PATH_TINY}, 'PATH_TINY registered from auto-loaded Mocks file';
ok exists $layer{LWP_UA},    'LWP_UA registered from auto-loaded Mocks file';
ok exists $layer{DBI},       'DBI registered from auto-loaded Mocks file';

done_testing();
