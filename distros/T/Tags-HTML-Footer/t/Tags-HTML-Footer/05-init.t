use strict;
use warnings;

use Data::HTML::Footer;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Footer;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Footer->new;
my $footer = Data::HTML::Footer->new;
my $ret = $obj->init($footer);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::Footer->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Footer object must be a 'Data::HTML::Footer' instance.\n",
	"Footer object must be a 'Data::HTML::Footer' instance.");
clean();

# Test.
$obj = Tags::HTML::Footer->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Footer object must be a 'Data::HTML::Footer' instance.\n",
	"Footer object must be a 'Data::HTML::Footer' instance.");
clean();

# Test.
$obj = Tags::HTML::Footer->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Footer object must be a 'Data::HTML::Footer' instance.\n",
	"Footer object must be a 'Data::HTML::Footer' instance.");
clean();
