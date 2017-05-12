# -*- perl -*-

# test script for the Persistathon - set TANGRAM_TRACE=1 in the
# environment for a nice log of what queries Tangram is running.

use lib "t/musicstore";
use Prerequisites;
use strict;

use Test::More tests => 25;
use Tangram::Storage;

# various items that will "persist" between test blocks
use vars qw($storage);
my ($oid, $id, $r_cd, $r_artist, $band, $row, $join, $filter);

# open a storage connection - this will be
# Tangram::Relational->connect(), etc.
$storage = DBConfig->dialect->connect(MusicStore->schema, DBConfig->cparm);

{

    # 1. create a new database object of each type in the schema
    my ($cd, @songs, $band, @people);
    $band = CD::Band->new
	({ name => "The Upbeats",
	  popularity => "World Famous in New Zealand",
	  cds => Set::Object->new
	  (
	   $cd=
	   CD->new({title => "The Upbeats",
		    publishdate => iso('2004-04-01'),
		    songs => [
			      @songs=
			      CD::Song->new({name => "Hello"}),
			      CD::Song->new({name => "Drizzle"}),
			      CD::Song->new({name => "From the Deep"}),
			     ],
		  }),
	  ),
	  members => Set::Object->new
	  (
	   @people =
	   CD::Person->new({ name => "Jeremy Glenn" }),
	   CD::Person->new({ name => "Dylan Jones" }),
	  ),
	});

    # stick it in
    $oid = $storage->insert($band);
    $id = $storage->export_object($band);
    ok($oid, "Inserted a band and associated objects");

    # 2. print the object IDs
    if ( -t STDIN ) {  #unless running in the harness...
	diag($_) foreach
	    ("Band: ".$storage->export_object($band),
	     "People: ".join(",", $storage->export_object(@people)),
	     "CD storage ID: ".$storage->export_object($cd),
	     "Songs: ".join(",", $storage->export_object(@songs)));
    }

    # put in some extra data for fun
    require 'insert_extra_data.pl';
}

# objects should now be gone, as they have fallen out of scope
is($CD::c, 0, "no objects leaked");

{
    # two loading strategies - one is the `exported' object, where you
    # pass in a type and an ID - note that any superclass is OK (the
    # import is polymorphic)
    $band = $storage->import_object("CD::Artist", $id);
    isa_ok($band, "CD::Band", "Band loaded by exported ID");

    # the second is to import by oid, which includes the class ID...
    my $band2 = $storage->load($oid);
    isa_ok($band2, "CD::Band", "Band loaded by OID");

    is($band, $band2, "Seperate loads returned same object");
}

is($CD::c, 1, "no objects leaked");

{
    # 4. fetch an artist record by name (exact match)
    $r_artist = $storage->remote("CD::Artist");

    my @artists = $storage->select
	( $r_artist,
	  $r_artist->{name} eq "The Upbeats" );

    is(@artists, 1, "got an object out");

    # extra demonstration - is it the same object as $band ?
    is($artists[0], $band, "selects return cached objects");
}

is($CD::c, 1, "no objects leaked");

{
    # 5. fetch an artist record with a search term (globbing / LIKE /
    #    etc)
    my (@artists) = $storage->select
	( $r_artist,
	  $r_artist->{name}->upper()->like(uc("%beat%")),
	);

    is(@artists, 2, "got two artists matching %beat%");
    ok(Set::Object->new(@artists)->includes($band),
       "select still returns cached objects");
    undef($band);
}

is($CD::c, 0, "no objects leaked");

{
    # 6. fetch CD records by matching on a partial *artist's* name,
    #    using a cursor if possible.
    $r_cd = $storage->remote("CD");

    $join = ($r_cd->{artist} == $r_artist);
    my $query = $r_artist->{name}->upper()->like(uc("%beat%"));
    my $filter = $join & $query;

    my $cursor = $storage->cursor ( $r_cd, $filter );

    my @cds;
    while ( my $cd = $cursor->current ) {
	push @cds, $cd;
	$cursor->next;
    }
    is(@cds, 3, "Found three CDs by artists matching %beat%");

    # if we just wanted the count:
    my ($count) = $storage->count($filter);
    is($count, 3, "Can do simple COUNT() queries - compat");

    $count = $storage->count($r_cd, $filter);
    is($count, 3, "Can do simple COUNT() queries - proper");

    # maybe some other aggregation type queries:
    ($row) = $storage->select
	( undef, # no object
	  filter => $filter,
	  retrieve => [ $r_cd->{publishdate}->min(),
			$r_cd->{publishdate}->max(),
		      ],
	);

    # this could probably be considered a design caveat
    $_ = $storage->from_dbms("date", $_) foreach @$row;
}

is($CD::c, 0, "no objects leaked");

{

    is_deeply($row, [ '1999-10-26T00:00:00', '2004-04-01T00:00:00' ],
	      "aggregation type queries");

    # 7. fetch unique CD records by matching on a partial artist's
    #    *or* partial CD name, using a cursor if possible.
    my $query =
	( $r_artist->{name}->upper()->like(uc("%beat%"))
	  | $r_cd->{title}->upper()->like(uc("%beat%")) );

    my $filter = $join & $query;
    my $cursor = $storage->cursor ( $r_cd, $filter );

    my @cds=();
    while ( my $cd = $cursor->current ) {
	diag ("found cd = " .$cd->title.", artist = ".$cd->artist->name);
	push @cds, $cd;
	$cursor->next;
    }
    is(@cds, 4, "Found four CDs by CD or artist name matching %beat%");

}

is($CD::c, 0, "no objects leaked");

{
    #use YAML;
    #local($Tangram::TRACE) = \*STDERR;
    #local($Tangram::DEBUG_LEVEL) = 3;
    # 8. update a record or two
    my ($pfloyd) = $storage->select
	( $r_artist,
	  $r_artist->{name} eq "Pink Floyd" );

    my $cd;
    $pfloyd->cds->insert
	($cd=
	 CD->new({ title => "The Dark Side of The Moon",
		   publishdate => iso("2004-04-06"),
		   songs => [ map { CD::Song->new({ name => $_ }) }
			      "Speak To Me/Breathe", "On The Run",
			    "Time", "The Great Gig in the Sky",
			      "Money", "Us And Them",
			      "Any Colour You Like", "Brain Damage",
			    "Eclipse",
			  ],
		 })
	);
    $pfloyd->popularity("legendary");
    $storage->update($pfloyd);

    ok($storage->id($cd), "Automatically added a new Set member");
}

is($CD::c, 0, "no objects leaked");

{
    my ($pfloyd) = $storage->select
	( $r_artist,
	  $r_artist->{name} eq "Pink Floyd" );
    is($pfloyd->popularity, "legendary", "saved an object property");
}

is($CD::c, 0, "no objects leaked");

{
    # 9. delete some records
    my (@gonners) = $storage->select
	($r_artist,
	 $r_artist->{popularity} eq "one hit wonder");

    $storage->erase(@gonners);

    ok(!$storage->id($gonners[0]), "No longer part of storage");
}

is($CD::c, 0, "no objects leaked");


our %formats;

BEGIN {
%formats =
    ( 4 => "%Y",
      10 => "%Y-%m-%d",
      19 => "%Y-%m-%dT%H:%M:%S",
    );
}

sub iso {
    my $str = shift;
    Time::Piece->strptime($str, $formats{length($str)});
}

