use strict;
use warnings;

use Data::Image;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Image;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
my $image = Data::Image->new(
	'url' => 'https://example.com/image.png',
);
my $ret = $obj->init($image);
is($ret, undef, 'Right init (image with url).');

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
$image = Data::Image->new(
	'url_cb' => sub {
		return 'https://example.com/image.png';
	},
);
$ret = $obj->init($image);
is($ret, undef, 'Right init (image with url callback).');

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'img_src_cb' => sub {
		return 'https://example.com/image.png';
	},
	'tags' => $tags,
);
$image = Data::Image->new;
$ret = $obj->init($image);
is($ret, undef, 'Right init (image with url from constructor callback).');

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
eval {
	$obj->init;
};
is($EVAL_ERROR, "Image object is required.\n",
	"Image object is required.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Image object must be a instance of 'Data::Image'.\n",
	"Image object must be a instance of 'Data::Image'. (scalar)");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
my $mock = Test::MockObject->new;
eval {
	$obj->init($mock);
};
is($EVAL_ERROR, "Image object must be a instance of 'Data::Image'.\n",
	"Image object must be a instance of 'Data::Image'. (different object)");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
$image = Data::Image->new;
eval {
	$obj->init($image);
};
is($EVAL_ERROR, "No image URL.\n",
	"No image URL.");
clean();
