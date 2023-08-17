use Test2::V0;

use Test2::Require::Module 're::engine::RE2' => '0.18';

use Regexp::Pattern;
use re::engine::RE2;

use Test::Regexp::Pattern;

plan 5;

my $OPTS = { engine => 'RE2' };

my $re = re( "License::fsful", $OPTS );
ok $re;
isa_ok $re, ['Regexp'],          're object is a Regexp';
isa_ok $re, ['re::engine::RE2'], 're object is an RE2 object';

regexp_patterns_in_module_ok 'Regexp::Pattern::License', $OPTS;
regexp_patterns_in_module_ok 'Regexp::Pattern::License::Parts', 'parts',
	$OPTS;

done_testing;
