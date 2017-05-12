use v5.12;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.0");

use parent qw(Exporter);

use Scalar::Util qw(blessed);

sub test_something($ $ $ $)
{
	my ($test, $thing, $name, $color) = @_;

	Test::More::subtest("$test" => sub {
		Test::More::plan(tests => 3);

		my $fine = defined($thing) &&
		    defined blessed($thing) &&
		    $thing->isa('Something');

		Test::More::ok($fine, 'we have something');
		SKIP:
		{
			Test::More::skip('cannot test the attributes of nothing', 2) unless $fine;

			Test::More::is($thing->name, $name, 'the right name');
			Test::More::is($thing->color, $color, 'the right color');
		}
	})
}

1;
