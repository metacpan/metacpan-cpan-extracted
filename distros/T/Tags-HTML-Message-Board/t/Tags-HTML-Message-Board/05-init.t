use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Message::Board;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Test.
my $obj = Tags::HTML::Message::Board->new;
my $board = Test::Shared::Fixture::Data::Message::Board::Example->new;
my $ret = $obj->init($board);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::Message::Board->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Data object must be a 'Data::Message::Board' instance.\n",
	"Data object must be a 'Data::Message::Board' instance (undef).");
clean();

# Test.
$obj = Tags::HTML::Message::Board->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Data object must be a 'Data::Message::Board' instance.\n",
	"Data object must be a 'Data::Message::Board' instance (object).");
clean();

# Test.
$obj = Tags::HTML::Message::Board->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Data object must be a 'Data::Message::Board' instance.\n",
	"Data object must be a 'Data::Message::Board' instance (string).");
clean();
