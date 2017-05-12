# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Tag::Reader::Perl;
use Test::More 'tests' => 3;

# Test.
eval {
	Tag::Reader::Perl->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");

# Test.
eval {
	Tag::Reader::Perl->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
my $obj = Tag::Reader::Perl->new;
isa_ok($obj, 'Tag::Reader::Perl');
