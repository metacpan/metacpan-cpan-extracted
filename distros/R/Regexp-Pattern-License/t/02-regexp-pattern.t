use Test2::V0;

use Test::Regexp::Pattern;

plan 2;

regexp_patterns_in_module_ok('Regexp::Pattern::License');

regexp_patterns_in_module_ok( 'Regexp::Pattern::License::Parts', 'parts' );
