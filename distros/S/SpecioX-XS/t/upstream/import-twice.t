use strict;
use warnings;
use SpecioX::XS;
## skip Test::Tabs

use Test::Fatal;
use Test::More 0.96;

use Specio::Library::Builtins;

is(
    exception { Specio::Library::Builtins->import },
    undef,
    'no exception importing the same library twice'
);

isa_ok( t('Num'), 'Specio::Constraint::Simple' );

done_testing();
