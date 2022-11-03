use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

BEGIN {
	unless (eval { require Sub::Util } && Sub::Util->VERSION >= 1.40) {
		plan skip_all => 'These tests require Sub::Util';
	}
}


subtest 'testing subname' => sub {
	is Sub::Util::subname(\&field), 'Mooish::AttributeBuilder::field', 'field ok';
	is Sub::Util::subname(\&param), 'Mooish::AttributeBuilder::param', 'param ok';
	is Sub::Util::subname(\&option), 'Mooish::AttributeBuilder::option', 'option ok';
	is Sub::Util::subname(\&extended), 'Mooish::AttributeBuilder::extended', 'extended ok';
};

done_testing;

