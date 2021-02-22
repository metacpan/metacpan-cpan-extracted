#!perl
use strict;
use warnings;

use Test::More 1.0;

require 't/lib/setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

use Test::Without::Module qw( Test::Prereq Module::CPANTS::Analyse );

my @tuples = (
	[ qw( Module::Release::Prereq   check_prereqs  ) ],
	[ qw( Module::Release::Kwalitee check_kwalitee ) ],
	);

foreach my $tuple ( @tuples ) {
	my( $module, $method ) = @$tuple;

	my $rc = eval "{ package Module::Release; require $module; $module\->import  }";
	ok( defined $rc, "Loading $module succeeds" );

	my $release = $class->new( quiet => 1 );
	can_ok( $release, $method );

	eval { $release->$method };
	my $at = $@;

	like( $at, qr/You need/i, "Gets right error message" );
	};

done_testing();

