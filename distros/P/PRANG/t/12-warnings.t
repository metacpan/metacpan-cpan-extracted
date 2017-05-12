#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);

{

	package Rigel;
	use Moose;
	use PRANG::Graph;

	has_element 'algedi' => (
		is => "ro",
		isa => "Algedi",
	);

	sub root_element {
		'rigel';
	}
	sub xmlns { }
	with 'PRANG::Graph';

	package Algedi;
	use Moose;
	use PRANG::Graph;
	has_attr 'pollux' => (
		is => "ro",
	);
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, "@_" };
eval { Rigel->new->to_xml };
like(
	$@, qr{required element not set.*/rigel/algedi},
	"error when slot missing on to_xml makes sense"
);
like(
	$warnings[0], qr{expected element is not required.*Rigel/algedi},
	"appropriate warning raised",
);

#eval { Rigel->new->to_xml };
#like($@, qr{algedi.*is required},
#"it's eventually marked as required");
