#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MooseX::Types::LaxNum;
use Moose::Util::TypeConstraints;
{
    my $subtype = subtype( { as => 'LaxNum' } );
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got a subtype' );

    my @rejects = (
	'hello',
	undef
	);
    my @accepts = (
	'  123  ',
	"1\n",
	"\n1",
	'123',
	"0 but true",
	"Inf",
	"Infinity",
	"NaN",
	'123.4367',
	'3322',
	'13e7',
	'0',
	'0.0',
	'.0',
	'0.',
	'0.',
	0.0,
	123,
	13e6,
	123.4367,
	10.5
	);

    for( @rejects )
    {
	my $printable = defined $_ ? $_ : "(undef)";
	ok( !$subtype->check($_), "constraint rejects $printable" );
    }
    ok( $subtype->check($_), "constraint accepts $_" ) for @accepts;
}

done_testing;
