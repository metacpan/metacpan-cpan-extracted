use strict;
use warnings;

use utf8;
use open qw(:std :utf8);

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Common::String -all;

ok(  is_UpperCaseStr('CAFÉ'), q[CAFÉ is uppercase] );
ok( !is_UpperCaseStr('CAFé'), q[CAFé is not (entirely) uppercase] );

ok( !is_UpperCaseStr('ŐħĤăĩ'), q[ŐħĤăĩ not entirely uppercase] );
ok( !is_LowerCaseStr('ŐħĤăĩ'), q[ŐħĤăĩ not entirely lowercase] );

ok(  is_LowerCaseStr('café'), q[café is lowercase] );
ok( !is_LowerCaseStr('cafÉ'), q[cafÉ is not (entirely) lowercase] );

ok(  is_UpperCaseSimpleStr('CAFÉ'), q[CAFÉ is uppercase] );
ok( !is_UpperCaseSimpleStr('CAFé'), q[CAFé is not (entirely) uppercase] );

ok(  is_LowerCaseSimpleStr('café'), q[café is lowercase] );
ok( !is_LowerCaseSimpleStr('cafÉ'), q[cafÉ is not (entirely) lowercase] );

done_testing;
