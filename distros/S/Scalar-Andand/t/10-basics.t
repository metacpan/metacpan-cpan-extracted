#!perl -T

use Test::More tests => 2;
use Scalar::Andand;

for (Tester->new, undef, 4) {
	$_->andand->do_something
}

package Tester;

use Test::More;

sub new {
	return bless {};
}

sub do_something {
	ok($_[0], "$_[0] is true");
}
sub Scalar::Andand::Scalar::do_something {
	ok($_[0], "$_[0] is true");
}
