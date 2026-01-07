# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

package Test::CloneSet;

use 5.012;
use strict;
use warnings;

use parent qw(Exporter);

use Scalar::Util qw(blessed);

our $VERSION = v0.1.2;

our @EXPORT_OK = qw(&test_something);

sub test_something($ $ $ $) {
	my ( $test, $thing, $name, $color ) = @_;

	Test::More::subtest(
		"$test" => sub {
			Test::More::plan( tests => 3 );

			my $fine =
				   defined($thing)
				&& defined blessed($thing)
				&& $thing->isa('Something');

			Test::More::ok( $fine, 'we have something' );
		SKIP:
			{
				if ( !$fine ) {
					Test::More::skip(
						'cannot test the attributes of nothing', 2,
					);
				}

				Test::More::is( $thing->name,  $name,  'the right name' );
				Test::More::is( $thing->color, $color, 'the right color' );
			}
		},
	);

	return 1;
}

1;
