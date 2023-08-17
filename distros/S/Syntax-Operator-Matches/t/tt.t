use Test2::V0;
use Test2::Require::Module 'Types::Common';

use Syntax::Operator::Matches;
use Types::Common -lexical, -types;

ok( 'foo' matches Str );
ok( not 'foo' matches HashRef );

done_testing;
