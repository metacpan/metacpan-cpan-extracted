use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use NKC::Transform::MARC2BIBFRAME;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = NKC::Transform::MARC2BIBFRAME->new;
my $ret = $obj->version;
is($ret, '3.0', 'Get version (default - 3.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.5.0',
);
$ret = $obj->version;
is($ret, '2.5.0', 'Get version (2.5.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.9.0',
);
$ret = $obj->version;
is($ret, '2.9.0', 'Get version (2.9.0).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '2.10.0',
);
$ret = $obj->version;
is($ret, '2.10', 'Get version (2.10).');

# Test.
$obj = NKC::Transform::MARC2BIBFRAME->new(
	'version' => '3.0.0',
);
$ret = $obj->version;
is($ret, '3.0', 'Get version (3.0).');

# Test.
eval {
	NKC::Transform::MARC2BIBFRAME->new(
		'version' => 'bad',
	);
};
is($EVAL_ERROR, "Cannot read XSLT file.\n",
	"Cannot read XSLT file.");
clean();
