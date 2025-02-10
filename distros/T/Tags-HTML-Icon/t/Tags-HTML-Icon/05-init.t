use strict;
use warnings;

use Data::Icon;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Icon;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
my $icon = Data::Icon->new(
	'url' => 'https://example.com/image.png',
);
my $ret = $obj->init($icon);
is($ret, undef, 'Right init (image with url).');

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
eval {
	$obj->init;
};
is($EVAL_ERROR, "Icon object is required.\n",
	"Icon object is required.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Icon object must be a instance of 'Data::Icon'.\n",
	"Icon object must be a instance of 'Data::Icon'. (scalar)");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'tags' => $tags,
);
my $mock = Test::MockObject->new;
eval {
	$obj->init($mock);
};
is($EVAL_ERROR, "Icon object must be a instance of 'Data::Icon'.\n",
	"Icon object must be a instance of 'Data::Icon'. (different object)");
clean();
