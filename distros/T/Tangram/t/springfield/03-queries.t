# -*- perl -*-


# Portions Copyright (c) 2002-2004, Sam Vilain.  All rights reserved.
# This program is free software; you may use it and/or modify it under
# the same terms as Perl itself.

use strict;
use lib "t/springfield";
use Springfield;

# $Tangram::TRACE = \*STDOUT;

use Test::More tests => 24;

#--------------------
# setup tests
{
   my $storage = Springfield::connect_empty;

   my $homer = NaturalPerson->new( firstName => 'Homer', name => 'Simpson' );
   my $marge = NaturalPerson->new( firstName => 'Marge', name => 'Simpson' );

   $marge->{partner} = $homer;
   $homer->{partner} = $marge;

   $storage->insert( $homer );

   $storage->insert( NaturalPerson->new( firstName => 'Montgomery',
					 name => 'Burns' ) );

   delete $homer->{partner};

   $storage->disconnect();
}
is(&leaked, 0, "leaktest");

#--------------------
# filter on string field
{
   my $storage = Springfield::connect;

   my ($person) = $storage->remote(qw( NaturalPerson ));

   my @results = $storage->select
       ( $person,
	 $person->{name} eq 'Simpson' );

   is(join( ' ', sort map { $_->{firstName} } @results ),
      'Homer Marge',
      "filter on string field");

   $storage->disconnect();
}      
is(&leaked, 0, "leaktest");

#--------------------
# logical and
{
   my $storage = Springfield::connect;

   my ($person) = $storage->remote(qw( NaturalPerson ));

   my @results = $storage->select
       ( $person,
	 ($person->{firstName} eq 'Homer') &
	 ($person->{name}      eq 'Simpson'  ) );

   is( @results, 1, "Logical and");
   is ( $results[0]{firstName},
	'Homer',
	"Logical and" );

   $storage->disconnect();
}      
is(&leaked, 0, "leaktest");

#--------------------
# join on a ref link
{
   my $storage = Springfield::connect;

   my ($person, $partner) = $storage->remote(qw( NaturalPerson
						 NaturalPerson ));

   my @results = $storage->select
       ( $person,
	 ($person->{partner} == $partner) &
	 ($partner->{firstName} eq 'Marge') );

   is( @results, 1, "Logical and");
   is ( $results[0]{firstName},
	'Homer',
	"Logical and" );

   $storage->disconnect();
}      
is(&leaked, 0, "leaktest");

#--------------------
# two birds with one stone; test that Tangram doesn't go disconnecting
# DBI handles that it was passed!
my $dbh = DBI->connect($cs, $user, $passwd)
    or die "DBI->connect failed; $DBI::errstr";

#--------------------
# now, test IS NOT NULL query
{
   my $storage = Springfield::connect(undef, { dbh => $dbh });

   my ($person) = $storage->remote(qw( NaturalPerson ));

   my @results = $storage->select( $person, $person->{partner} != undef );

   is(join( ' ', sort map { $_->{firstName} } @results ),
      'Homer Marge',
      "!= undef test");

   $storage->disconnect();
}
is(&leaked, 0, "leaktest");

#--------------------
# test outer joins; only really make sense with retrieve

SKIP:{
   skip "SQLite can't do nested joins", 2
       if DBConfig->dialect =~ /sqlite/i;

   skip "MySQL known to return incorrect results for nested joins", 2
       if DBConfig->dialect =~ /mysql/i;

# first, setup some test data
{
   my $storage = Springfield::connect(undef, { dbh => $dbh });
   my @people = $storage->select("NaturalPerson");
   $storage->insert
       (LegalPerson->new(name => "Springfield Nuclear Power Plant",
			 colour => "Fluourescant Green",
			));
   for ( @people ) {
       $_->{colour} = "Yellow";
   }
   $storage->update(@people);
}

{
   my $storage = Springfield::connect(undef, { dbh => $dbh });

   #local($Tangram::TRACE) = \*STDERR;

   my ($person, $partner) = $storage->remote(qw( NaturalPerson
						 NaturalPerson ));

   # FIXME - polymorphic outer joins don't work.  This query
   # might actually return wrong results.  A rethink is required.
   my $test_it = sub {

       my $cursor = $storage->cursor
	   (
	    $person,
	    @_
	   );

       my @results;
       while ( my $person = $cursor->current ) {
	   push @results, ($person->{firstName}.":"
			   .join(":",map { $_||""} $cursor->residue));
	   $cursor->next();
       }

       #diag(Data::Dumper::Dumper(\@results));

       is_deeply(\@results,
		 [ qw( Homer:Marge:Yellow Marge:: Montgomery:: ) ],
		 "outer join");
   };

   $test_it->(
	retrieve => [ $partner->{firstName},
		      $partner->{colour},
		    ],
	order => [ $person->{firstName} ],
	outer_filter => ( ($person->{partner} == $partner) &
			  ($partner->{firstName} == "Marge") ),
	     );

   #$Tangram::Global = 1;

   $test_it->(
	retrieve => [ $partner->{firstName},
		      $partner->{colour},
		    ],
	filter => ($person->{partner} == $partner),
	order => [ $person->{firstName} ],
	outer_filter => ($partner->{firstName} == "Marge"),
	      force_outer => $partner
	     );

   $storage->disconnect();
}
}
is(&leaked, 0, "leaktest");

# here is the test for Tangram not disconnecting - this should work.
eval {
    my $sth = $dbh->prepare("select count(*) from Tangram")
	or die $DBI::errstr;
    $sth->execute();
    my @res = $sth->fetchall_arrayref;
};
ok(!$DBI::err,
   "Disconnect didn't disconnect a supplied DBI handle");

#--------------------
# BEGIN ks.perl@kurtstephens.com 2002/10/16
# Test non-commutative operator argument swapping
{
   my $storage = Springfield::connect;

   my ($person) = $storage->remote(qw( NaturalPerson ));
 
   # local $Tangram::TRACE = \*STDERR;
   my @results = $storage->select
       ( $person,
	 ( 1 <= $person->{person_id} )      &
	 ( $person->{person_id} <= 2 )
	 );
   
   is(@results, 2, "non-commutative operator argument swapping" );

   $storage->disconnect();
}      

is(&leaked, 0, "leaktest");
# END ks.perl@kurtstephens.com 2002/10/16

# test selecting some columns with no filter or object
{
   my $storage = Springfield::connect;

   my ($person) = $storage->remote(qw( NaturalPerson ));

   #local $Tangram::TRACE = \*STDERR;
   my @results = $storage->select
       ( undef,
	 retrieve => [ $person->{id} ],
	 order    => [ $person->{id} ],
       );

   is(@results, 3, "no filter or object (get all IDs)" );

   # now try to load them - this does really kooky stuff with
   # polymorphic selects (seemingly makes one select per subclass)
   my @objects = $storage->select
       ( $person,
	 $person->{id}->in(@results),
       );

   is(@objects, 3, "selected results");
   isa_ok($_, "Person", "selected item") foreach (@objects);

   # test that class_id works for classes not in schema (an empty
   # subclass test)
   @UndeadPerson::ISA = qw(NaturalPerson);
   is($storage->class_id("UndeadPerson"),
      $storage->class_id("NaturalPerson"), 
      "Storage can handle Undead objects");

   $storage->disconnect();

}
is(&leaked, 0, "leaktest");


$dbh->disconnect();
