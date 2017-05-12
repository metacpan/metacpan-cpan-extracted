# -*- perl -*-

# in this script, we re-org the database by loading in objects from
# one storage and saving them in another.

use lib "t/musicstore";
use lib "t";
use Prerequisites;
use TestNeeds qw(Heritable::Types 1.01);
use Set::Object;

use Test::More tests => 6;

my $cd = new CD;

# to make things interesting, we put the data into a single table,
# which turns our nice relational database into an old school
# heirarchical database.  After all, unless you have a radical schema
# change, this whole operation of a re-org is pretty pointless!

my $storage = DBConfig->dialect->connect
    (MusicStore->schema, DBConfig->cparm);

# some DBI drivers (eg, Informix) don't like two connections from the
# same process
my $storage2 = DBConfig->dialect->connect
    (MusicStore->pixie_like_schema, DBConfig->cparm);

my @classes = qw(CD CD::Artist CD::Song);

# the simplest way would be to use something akin to this:
#
#   $storage2->insert(map { $storage->select($_) } @classes);
#
# however, this exposes one of the caveats with such an "open slander
# insertion" policy.

# If you let any node in an object structure be inserted as an object,
# automatically storing all its sub-trees, there is no easy way to see
# if a given node that is being inserted isn't already a sub-part of
# another stored node.

# My intention is to make Tangram::Storage->insert() take care of this
# for you.  I can see this working within the next two Tangram
# releases:

# why bother with a database if you're just going to load it into
# memory, you might ask?  Well, this test script is demo-ing the
# reschema support.
my @objects = map { $storage->select($_) } @classes;

# we insert only CD objects into $storage2.
my @cds = grep { $_->isa("CD") } @objects;
$storage2->insert( @cds );

# later;
# $storage2->insert($storage->select("CD"));

my $unknown = set();
my %known;

for my $object ( @objects ) {
    if ( my $oid = $storage2->id($object) ) {
	$known{$oid} = $object;
    }
    else {
	$unknown->insert($object);
    }
}

is( keys %known, @cds, "number of objects inserted");

is( (grep { $_->isa("CD") } values %known),
    (keys %known),
    "all inserted objects are CDs");

is( $unknown->size,
    (@objects - @cds),
    "correct number of uninserted objects")

is( (grep { ! $_->isa("CD") } $unknown->members),
    $unknown->size,
    "no uninserted objects are CDs");

$storage2->unload_all();

is( (grep { $_ } $storage2->id( @objects ) ),
    0,
    "unload forgets the objects" );

is_deeply( [ sort @cds ],
	   [ sort $storage2->select("CD") ],
	   "but they are still the same objects!" );
