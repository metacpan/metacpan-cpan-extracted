#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use_ok("Tangram::Dump");

use Data::Dumper;
use lib 't/springfield';
use Springfield;
use Set::Object qw(is_overloaded blessed);

SKIP:{
    #skip "Storable broken on Pg - see lib/Tangram/Pg.pod", 3
	#if $Springfield::vendor eq "Pg";
my $homer_id;

{

    my $storage = Springfield::connect_empty();

    my $homer = 
	NaturalPerson->new( firstName => 'Homer',
			    name => 'Simpson',
			  );

    my $marge = NaturalPerson->new( firstName => 'Marge',
				    name => 'Simpson' );

    $homer->{partner} = $marge;
    $marge->{partner} = $homer;

    $homer_id = $storage->insert($homer);

    delete $homer->{partner};
    delete $marge->{partner};
}

is(leaked, 0, "leaktest");

# now test putting it in the database...
{
    my $storage = Springfield::connect;

    my $homer = $storage->load($homer_id);

    $homer->{thought} = {
			 me => $homer,
			 marge => $homer->{partner},
			 beer => "good",
			 beer_from => "fridge",
			 beer_fetched_by => \\$homer->{partner},
			 # fails leaktest ... more investigation required
			 #family => Set::Object->new($homer,
						    #$homer->{partner})
		       };

    $storage->update($homer);
    delete $homer->{partner};
    delete $homer->{thought};
}

is(leaked, 0, "leaktest");

{
    my $storage = Springfield::connect;

    my $homer = $storage->load($homer_id);

    my $marge = $homer->{partner};

    is($homer->{thought}->{marge}, $marge,
       "Storable can store Tangram objects!");

}
}
