use strict;
use warnings;

use CPAN::Changes;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::CPAN::Changes;
use Test::MockObject;
use Test::More 'tests' => 6;
use Test::NoWarnings;

package My::CPAN::Changes;

use base qw(CPAN::Changes);

our $VERSION = 0.400002;

sub new {
	my $class = shift;
	return bless {}, $class;
}

package main;

# Test.
my $obj = Tags::HTML::CPAN::Changes->new;
my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
);
my $ret = $obj->init($changes);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::CPAN::Changes->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "Data object must be a 'CPAN::Changes' instance.\n",
	"Data object must be a 'CPAN::Changes' instance (undef).");
clean();

# Test.
$obj = Tags::HTML::CPAN::Changes->new;
eval {
	$obj->init(Test::MockObject->new);
};
is($EVAL_ERROR, "Data object must be a 'CPAN::Changes' instance.\n",
	"Data object must be a 'CPAN::Changes' instance (object).");
clean();

# Test.
$obj = Tags::HTML::CPAN::Changes->new;
eval {
	$obj->init('bad');
};
is($EVAL_ERROR, "Data object must be a 'CPAN::Changes' instance.\n",
	"Data object must be a 'CPAN::Changes' instance (string).");
clean();

# Test.
my $bad_obj = My::CPAN::Changes->new;
$obj = Tags::HTML::CPAN::Changes->new;
eval {
	$obj->init($bad_obj);
};
is($EVAL_ERROR, "Minimal version of supported CPAN::Changes is 0.500002.\n",
	"Minimal version of supported CPAN::Changes is 0.500002. (0.400002).");
clean();
