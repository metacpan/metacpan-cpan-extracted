# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure::Utils qw(clean);
use PYX::SGML::Tags;
use Tags::Output::Raw;
use Tags::Output::Indent;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
eval {
	PYX::SGML::Tags->new(
		'tags' => undef,
	);
};
is($EVAL_ERROR, "Bad 'Tags::Output::*' object.\n",
	"Bad 'Tags::Output::*' object - undef");
clean();

# Test.
eval {
	PYX::SGML::Tags->new(
		'tags' => 'foo',
	);
};
is($EVAL_ERROR, "Bad 'Tags::Output::*' object.\n",
	"Bad 'Tags::Output::*' object - string.");
clean();

# Test.
eval {
	PYX::SGML::Tags->new(
		'tags' => PYX::SGML::Tags->new,
	);
};
is($EVAL_ERROR, "Bad 'Tags::Output::*' object.\n",
	"Bad 'Tags::Output::*' object - bad object.");
clean();

# Test.
my $obj = PYX::SGML::Tags->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'PYX::SGML::Tags');

# Test.
$obj = PYX::SGML::Tags->new(
	'tags' => Tags::Output::Indent->new,
);
isa_ok($obj, 'PYX::SGML::Tags');
