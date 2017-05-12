#!/usr/bin/perl -w

use strict;
use Test::More tests => 20;

use_ok("Tangram::Dump");

use Data::Dumper;
use lib "t/springfield";
use Springfield;
use Set::Object qw(is_overloaded blessed);
use Tangram::Type::Dump qw(flatten unflatten);

my $homer_id;

{

    my $storage = Springfield::connect_empty();

    my $homer = 
	NaturalPerson->new( firstName => 'Homer',
			    name => 'Simpson',
			    "ih_opinions" =>
			    { work => Opinion->new(statement => 'bad'),
			      food => Opinion->new(statement => 'good'),
			      beer => Opinion->new(statement => 'better') },
			  );

    my $marge = NaturalPerson->new( firstName => 'Marge',
				    name => 'Simpson' );

    $homer->{partner} = $marge;
    $marge->{partner} = $homer;

    $homer_id = $storage->insert($homer);

    # now, make a data structure...

    my $structure = {
		     hello => $homer,
		     #foo => "bar",
		     #baz => [ qw(frop quux), $homer ],
		     #cheese => \\$marge,
		     #bananas => Set::Object->new($homer, $marge),
		    };
    flatten($storage, $structure);
    is(ref $structure->{hello}, "Tangram::Memento",
       "blessed object removed - 1");

    unflatten($storage, $structure);
    is($structure->{hello}, $homer, "unflatten - 1");

    $structure = {
		     hello => $homer,
		     foo => "bar",
		     baz => [ qw(frop quux), $homer ],
		     #cheese => \\$marge,
		     #bananas => Set::Object->new($homer, $marge),
		    };
    flatten($storage, $structure);
    is(ref $structure->{hello}, "Tangram::Memento",
       "blessed object removed - 2a");
    is(ref $structure->{baz}->[2], "Tangram::Memento",
       "blessed object removed - 2b");
    unflatten($storage, $structure);
    is($structure->{hello}, $homer, "unflatten - 2a");
    is($structure->{baz}->[2], $homer, "unflatten - 2b");

    $structure = {
		     hello => $homer,
		     foo => "bar",
		     baz => [ qw(frop quux), $homer ],
		     cheese => \\$marge,
		    };
    flatten($storage, $structure);
    is(ref $structure->{hello}, "Tangram::Memento",
       "blessed object removed - 3a");
    is(ref $structure->{baz}->[2], "Tangram::Memento",
       "blessed object removed - 3b");
    is(ref ${${$structure->{cheese}}}, "Tangram::Memento",
       "blessed object removed - 3c");
    unflatten($storage, $structure);
    is($structure->{hello}, $homer, "unflatten - 3a");
    is($structure->{baz}->[2], $homer, "unflatten - 3b");
    is(${${$structure->{cheese}}}, $marge, "unflatten - 3c");

    $structure = {
		  hello => $homer,
		  foo => "bar",
		  baz => [ qw(frop quux), $homer ],
		  cheese => \\$marge,
		  bananas => Set::Object->new($homer, $marge),
		 };
    flatten($storage, $structure);
    isnt(ref $structure->{bananas}, "Set::Object",
	 "Set::Object's replaced");
    ###my $x = dispel_overload($structure->{bananas});
    #isnt($x, 1, "no AMAGIC bits leaked");

    unflatten($storage, $structure);
    is(ref $structure->{bananas}, "Set::Object",
       "unflatten Set::Object (container)");
    is($structure->{bananas}->size, 2,
       "unflatten Set::Object (contents 1)");
    is_deeply([ sort { $a->{firstName} cmp $b->{firstName} }
		$structure->{bananas}->members ],
	      [ $homer, $marge ],
	      "unflatten Set::Object (contents 2)");

    $Data::Dumper::Indent = 1;

    #%$structure = ();
    delete $homer->{partner};
}

is(leaked, 0, "leaktest");

# now test putting it in the database...
{
    my $storage = Springfield::connect;

    my $homer = $storage->load($homer_id);

    $homer->{brains} = {
			me => $homer,
			marge => $homer->{partner},
			#beer => "good",
			#beer_from => "fridge",
			#beer_fetched_by => \\$homer->{partner},
			#family => Set::Object->new($homer,
						   #$homer->{partner})
		       };

    $storage->update($homer);
    delete $homer->{partner};
    delete $homer->{brains};
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;

    my $homer = $storage->load($homer_id);

    my $marge = $homer->{partner};

    is($homer->{brains}->{marge}, $marge,
       "PerlDump can store Tangram objects!");

}
