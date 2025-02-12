use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::InfoBox;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Street;

# Test.
my $obj = Tags::HTML::InfoBox->new;
my $ret = $obj->init;
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::InfoBox->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Info box object must be a instance of 'Data::InfoBox'.\n",
	"Info box object must be a instance of 'Data::InfoBox' (bad).");
clean();

# Test.
$obj = Tags::HTML::InfoBox->new;
my $bad_object = Test::MockObject->new;
eval {
	$obj->init($bad_object);
};
is($EVAL_ERROR, "Info box object must be a instance of 'Data::InfoBox'.\n",
	"Info box object must be a instance of 'Data::InfoBox' (other object).");
clean();

# Test.
$obj = Tags::HTML::InfoBox->new;
my $info_box = Test::Shared::Fixture::Data::InfoBox::Street->new;
$ret = $obj->init($info_box);
is($ret, undef, 'Init returns undef.');
