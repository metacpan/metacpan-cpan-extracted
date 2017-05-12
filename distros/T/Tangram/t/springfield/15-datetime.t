#!/usr/bin/perl

use strict;
use lib 't/springfield';
use Springfield;
BEGIN {
    eval "use Date::Manip qw(ParseDate);";
    if ($@) {
	eval 'use Test::More skip_all => "Date::Manip not installed";';
    } else {
	eval 'use Test::More tests => 11;';
    }
}

my $do_rawtests = ($dialect =~ m/^Tangram::mysql$/);

#tests_for_dialect(qw( mysql Pg ));

#$Tangram::TRACE = \*STDOUT;

my %ids;

{
	my $storage = Springfield::connect_empty;

	my $jll = NaturalPerson->new
		(
		 firstName => 'Jean-Louis',
		 ($do_rawtests
		  ?( birthDate => '1963-8-13',
		     birthTime => '11:34:17',
		     birth => '1963-8-13 11:34:17', ) : ()),
		 incarnation => ParseDate('1963-8-13 11:34:17'),
  		);

	$ids{jll} = $storage->insert($jll);

	my $chloe = NaturalPerson->new
		(
		 firstName => 'Chloe',
		 ($do_rawtests ? (birth => '1993-7-28 13:10:00')
		  : () ),
		 incarnation => ParseDate('1993-7-28 13:10:00'),
  		);

   $ids{chloe} = $storage->insert($chloe);

   $storage->disconnect;
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;

    my $jll = $storage->load( $ids{jll} );

 SKIP:{
	skip "RAW date/time tests not worth it", 6
	    unless $do_rawtests;

	like($jll->{birthTime}, qr/11/, "raw time [1]");
	like($jll->{birthTime}, qr/34/, "raw time [2]");
	like($jll->{birthTime}, qr/17/, "raw time [3]");

	like($jll->{birthDate}, qr/1963/, "raw date [1]");
	like($jll->{birthDate}, qr/13/, "raw date [2]");
	like($jll->{birthDate}, qr/8/, "raw date [3]");
    }

    my $rp = $storage->remote(qw( NaturalPerson ));

    # FIXME - this is pretty much a hack for now.  It doesn't seem
    # straightforward to overload Tangram::DMDateTime::binop to be
    # able to wrap the arg later on.  This works for now!
     my @results = $storage->select
	( $rp, $rp->{incarnation} > $storage->to_dbms('date', '1990-01-01T12:00:00') );

    is(@results, 1, "Select by date compare");
    is($storage->id( $results[0] ), $ids{chloe},
       "got right object back" );

    like( $results[0]->{incarnation}, qr/^\d{10}:\d\d:\d\d$/,
	  "Dates returned in ISO8601 form" );

# 	if (optional_tests('epoch; no Time::Local',
# 					   eval { require 'Time::Local' }, 1)) {

# 		Springfield::test($jll->{birthDate} =~ /1963/
# 						  && $jll->{birthDate} =~ /13/
# 						  && $jll->{birthDate} =~ /8/
# 						 );
# 	}

    $storage->disconnect;
}

is(leaked, 0, "leaktest");

1;
