use Test2::V0;
use Test2::Require::Perl 'v5.12';

use Regexp::Pattern;

use Test::Regexp::Pattern;

plan 5;

my $OPTS = {};

my $re = re( "License::fsful", $OPTS );
ok $re;
isa_ok $re, ['Regexp'], 're object is a Regexp';
ref_ok $re, 'REGEXP', 're object is a native Regexp object';

regexp_patterns_in_module_ok 'Regexp::Pattern::License', $OPTS;
regexp_patterns_in_module_ok 'Regexp::Pattern::License::Parts', 'parts',
	$OPTS;

done_testing;
