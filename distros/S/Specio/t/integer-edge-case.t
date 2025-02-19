use strict;
use warnings;

use Test::More 0.96;

use Specio::Declare;
use Specio::Library::Builtins;

my $int = t('Int');
ok( $int->check(42),                   '42 is an Int' );
ok( $int->check(42.0),                 '42.0 is an Int' );
ok( !$int->check(42.5),                '42.5 is not an Int' );
ok( !$int->check(124512.000000000123), '124512.000000000123 is not an Int' );

done_testing();
