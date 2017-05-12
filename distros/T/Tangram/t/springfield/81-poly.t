#  -*- perl -*-
#

#
# Portions (c) Sam Vilain, 2003

use strict;
use Test::More tests => 8;
use lib "t/springfield";
use Springfield;

# $Tangram::TRACE = \*STDOUT;

my $beer;

{
   my $storage = Springfield::connect_empty;

   my @oids =
   $storage->insert
   (
      NaturalPerson->new( firstName => 'Homer', name => 'Simpson' ),
      NaturalPerson->new( firstName => 'Marge', name => 'Simpson' ),
      LegalPerson->new( name => 'Kwik Market' ),
      LegalPerson->new( name => 'Springfield Nuclear Power Plant' ),
      Opinion->new(statement => "beer is good"),
   );

   $beer = pop @oids;

   $storage->disconnect;
}

is(leaked, 0, "Nothing leaked yet!");

{
   my $storage = Springfield::connect;

   my @res;
   my $results = join( ', ', sort map { $_->as_string }
		       (@res = $storage->select('Person')) );
   #print "$results\n";

   is($results,
      'Homer Simpson, Kwik Market, Marge Simpson, Springfield Nuclear Power Plant',
      "Polymorphic retrieval via Tangram::Storage->select()"
     );

   ok($storage->oid_isa($storage->id(shift(@res)), "Person"),
      "oid_isa(positive)") while @res;

   ok(!$storage->oid_isa($beer, "Person"),
      "oid_isa(negative)");

   $storage->disconnect;
}

is(leaked, 0, "Nothing leaked yet!");

