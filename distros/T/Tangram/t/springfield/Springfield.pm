use strict;

use lib "t";

use Tangram qw(:compat_quiet);

use Tangram::RawDate;
use Tangram::RawTime;
use Tangram::RawDateTime;

use Tangram::FlatArray;
use Tangram::FlatHash;
use Tangram::PerlDump;
use Tangram::Storable;
use Tangram::IDBIF;

package Springfield;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %id @kids @opinions $no_date_manip);

eval 'use Tangram::Type::Date::Manip';

$no_date_manip = $@;

@ISA = qw( Exporter );

@EXPORT = qw( &optional_tests $schema testcase &leaktest &leaked &test &begin_tests &tests_for_dialect $dialect $cs $user $passwd stdpop %id @kids @opinions);
@EXPORT_OK = @EXPORT;

use vars qw($cs $user $passwd $dialect $vendor $schema);
use vars qw($no_tx $no_subselects $table_type);

use lib "t";
use DBConfig;

{
    my ($tx, $subsel, $ttype);
    ($cs, $user, $passwd) = DBConfig->cparm;

    $no_tx = DBConfig->no_tx;
    $no_subselects = DBConfig->no_subselects;
    $table_type = DBConfig->table_type;
    $vendor = DBConfig->vendor;

    $dialect = DBConfig->dialect;

}

sub list_if {
  shift() ? @_ : ()
}

$schema = 
    ( {

   #set_id => sub { my ($obj, $id) = @_; $obj->{id} = $id },
   #get_id => sub { shift()->{id} },

   sql =>
   {
    cid_size => 3,

    # Allow InnoDB style tables
    ( $table_type ? ( table_type => $table_type ) : () ),

    dumper => "Data::Dumper",
   },

   class_table => 'Classes',

   classes =>
   [
      Person =>
      {
         abstract => 1,
       fields =>
       {
	string => { colour => undef,
		  },
       },
      },

      NaturalPerson =>
      {
	   bases => [ qw( Person ) ],

	   fields =>
	   {
		string =>
		{
		 firstName => undef,
		 name => undef,
		},

		int => [ qw( age person_id ) ], # ks.perl@kurtstephens.com 2003/10/16

		ref =>
		{
		 partner => undef,
		 credit => { aggreg => 1 },
		},

	    # only test the RAW columns with PostgreSQL and MySQL
	    ($vendor =~ m/^(Pg|mysql)/
		 ?
		 (rawdate => [ qw( birthDate ) ],
		  rawtime => [ qw( birthTime ) ],
		  rawdatetime => [ qw( birth ) ],
		 ):()),

	    ($no_date_manip ? () : ( dmdatetime => [ qw( incarnation ) ] )),
	    #($no_time_piece ? () : ( timepiece => [ qw( timepiece ) ] )),
	    #($no_date_manip ? () : ( dmdatetime => [ qw( incarnation ) ] )),

		array =>
		{
		 children =>
		 {
		  class => 'NaturalPerson',
		  table => 'a_children',
		  aggreg => 1,
		 },
		 belongings =>
		 {
		  class => 'Item',
		  aggreg => 1,
		  deep_update => 1
		 },
		 a_opinions =>
		 {
		  class => 'Opinion',
		  table => 'a_opinions',
		 }
		},

		ihash =>
		{
		 ih_opinions =>
		 {
		  class => 'Opinion',
		  back => "ih_parent",
		 }
		},

		hash =>
		{
		 h_opinions =>
		 {
		  class => 'Opinion',
		  table => 'h_opinions',
		 }
		},

		iarray =>
		{
		 ia_children =>
		 {
		  class => 'NaturalPerson',
		  coll => 'ia_ref',
		  slot => 'ia_slot',
		  back => 'ia_parent',
		  aggreg => 1,
		 },
		 ia_opinions =>
		 {
		  class => 'Opinion',
		 }
		},

		set =>
		{
		 s_children =>
		 {
		  class => 'NaturalPerson',
		  table => "s_children",  #__
		  aggreg => 1,
		 },
		 #s_parents =>
		 #{
		  #class => 'NaturalPerson',
		  #table => 's_children',
		  #coll => "item",
		  #item => "coll",
		 #},
		 s_opinions =>
		 {
		  class => 'Opinion',
		  table => 's_opinions', #__
		 }
		},

		iset =>
		{
		 is_children =>
		 {
		  class => 'NaturalPerson',
		  coll => 'is_ref',
		  slot => 'is_slot',
		  back => 'is_parent',
		  aggreg => 1,
		 },
		 is_opinions =>
		 {
		  class => 'Opinion',
		 }
		},

		flat_array => [ qw( interests ) ],

		flat_hash => [ qw( opinions ) ],

		perl_dump => [ qw( brains ) ],

		( $vendor !~ m/^Peegee$/
		  ? (storable => [ qw( thought ) ])
		  : () ),
	   },
      },

	Opinion =>
	{
	 fields =>
	 {
	  string => [ qw( statement ) ],
	 },
	},

	LegalPerson =>
	{
	 bases => [ qw( Person ) ],
	 table => "Person",

	 fields =>
	 {
	  string =>
	  [ qw( name ) ],

	  ref =>
	  {		
	   manager => { null => 1 }
	  },
	 },
	},

	EcologicalRisk =>
	{
	 abstract => 1,

	 fields =>
	 {
	  int => [ qw( curies ) ],
	 },
	},
   
	NuclearPlant =>
	{
	 bases => [ qw( LegalPerson EcologicalRisk ) ],

	 fields =>
	 {
	  array =>
	  {
	   employees =>
	   {
		class => 'NaturalPerson',
		table => 'employees'
	   }
	  },
	 },
	},

	Credit =>
	{
	 fields =>
	 {
	  #int => { limit => { col => 'theLimit' } },
	  int => { limit => 'theLimit' },
	 }
	},

        Item =>
        {
	 fields =>
	 {
	  string => [ qw(name) ],
	  ref =>
	  {
	   owner => { deep_update => 1 }
	  }
	 }
	},

    Faerie => {
	       fields =>
	       { idbif => { -poof => # there goes another one!
			    undef
			 #   { dumper => "Storable" }
			  },
		 string => [ qw(name) ],
	       },
	      },

    FaerieHairy => {
		    fields =>
		    {
		     string => [ qw(name) ],
		     idbif => { friends => undef,
				enemies => undef,
				#-options => { dumper => "Storable" },
			      } },
		   },

    Sprite => {
	       table => qw(Faerie),
	       bases => [ qw(Faerie) ],
	       fields => { string => [ qw(foo) ], },
	      },

    Nymph => {
	      table => qw(FaerieHairy),
	      bases => [ qw(FaerieHairy) ],
	      fields => { idbif => [ qw(buddies) ],
			},
	     },

   ],

      } );

if ( $ENV{"NORMALIZE_TEST"} ) {
    $schema->{normalize} = 
	sub {
	    local($_)=shift;
	    print STDERR "topic is $_\n";
	    s/NaturalPerson/NP/;
	    s/$/_n/;
	    return $_;
	};
}

$schema = Tangram::Schema->new($schema);

sub connect
  {
	my $schema = shift || $Springfield::schema;
	my $opts = shift || {};
	my $storage = $dialect->connect($schema, $cs, $user, $passwd, $opts) || die;
	$no_tx = $storage->{no_tx} unless defined $no_tx;
	$no_subselects = $storage->{no_subselects};
	return $storage;
  }

sub empty
  {
	my $storage = shift || Springfield::connect;
	my $schema = shift || $Springfield::schema;
	my $conn = $storage->{db};

	foreach my $classdef (values %{ $schema->{classes} }) {
	    $conn->do("DELETE FROM $classdef->{table}") or die
		unless $classdef->{stateless};
	}

	$conn->do('DELETE FROM a_children');
	$conn->do('DELETE FROM s_children');
  }

sub connect_empty
  {
	my $schema = shift || $Springfield::schema;
	my $storage = Springfield::connect($schema);
	empty($storage, $schema);
	return $storage;
  }

use vars qw( $test );

sub begin_tests
{
   print "1..", shift, "\n";
   $test = 1;
}

sub _caller
{
	my @caller = caller(1);
	return "$caller[1] line $caller[2]";
}

sub test
{
	my $ok = shift;
   print 'not ' unless $ok;
   print 'ok ', $test++;
	print " - "._caller()."\n";

	my ($fun, $file, $line) = caller;
	print "$file($line) : error\n" unless $ok;
}

*testcase = \&test;

sub leaktest
{
   if ($SpringfieldObject::pop == 0)
   {
      print "ok $test - leaktest "._caller()."\n";
   }
   else
   {
		my ($fun, $file, $line) = caller;
      print "not ok $test - leaktest "._caller()."\n";
		print "$file($line) : error: $SpringfieldObject::pop object(s) leaked\n";
   }

   $SpringfieldObject::pop = 0;

   ++$test;
}

sub leaked
{
   return $SpringfieldObject::pop;
}

sub tx_tests
{
	my ($tests, $code) = @_;

	if ($no_tx)
	{
		print STDERR "tests $test-", $test + $tests - 1, " (transactions) skipped on this platform ";
		test(1) while $tests--;
	}
	else
	{
		&$code;
	}
}

sub optional_tests
{
	my ($what, $proceed, $tests) = @_;

	$test ||= 1;

	unless ($proceed)
	{
		print STDERR "tests $test-", $test + $tests - 1,
			" ($what) skipped on this platform ";
		test(1) while $tests--;
	}

	return $proceed;
}

sub tests_for_dialect {
	my %dialect;
	@dialect{@_} = ();
	return if exists $dialect{ (split ':', $cs)[1] };

	begin_tests(1);
	optional_tests($dialect, 0, 1);
	exit;
  }

#use Data::Dumper;
#print Dumper $schema;
#deploy;

@kids = qw( Bart Lisa Maggie );

sub stdpop
{
    my $storage = Springfield::connect_empty;
    my $children = shift || "children";

    $NaturalPerson::person_id = 0; # ks.perl@kurtstephens.com 2003/10/16

    my @children = (map { NaturalPerson->new( firstName => $_ ) }
		    @kids);
    $children[0]->{age} = 10;
    $children[1]->{age} = 8;
    $children[2]->{age} = 1;
    @id{ @kids } = $storage->insert( @children );

    # *cough* hack *cough*
    main::like("@id{@kids}", qr/^\d+ \d+ \d+$/, "Got ids back OK")
	    if defined &main::like;

    my %ops = ( "beer" => Opinion->new(statement => "good"),
		     "donuts" => Opinion->new(statement => "mmm.."),
		     "heart disease" =>
		     Opinion->new(statement => "Heart What?"));

    @opinions = map { $_->{statement} } values %ops;

    my $homer;
    {
	$homer = NaturalPerson->new
	(
	 age => 38,
	 firstName => 'Homer',
	 ($children =~ m/children/
	  ? ($children =~ m/s_/
	     ? ( $children => Set::Object->new(@children) )
	     : ( $children => [ @children ] ) )
	  : () ),
	 ($children =~ m/opinion/
	  ? ($children =~ m/h_/
	     ? ($children => { %ops })
	     : ($children =~ m/a_/
		? ($children => [ values %ops ])
		: ($children => Set::Object->new( values %ops ) )
	       )
	    )
	  : ()
	 )
	);
    }

    $id{Homer} = $storage->insert($homer);
    main::isnt($id{Homer}, 0, "Homer inserted OK")
	    if defined &main::isnt;

    my $marge = NaturalPerson->new( firstName => 'Marge',
				    age => 37,
				  );

    # cannot have >1 parent with a one to many relationship!
    if ($children =~ m/children/) {
	if ($children =~ m/^i/) {
	} elsif ($children =~ m/s_/) {
	    $marge->{$children} = Set::Object->new(@children);
	} else {
	    $marge->{$children} = [ @children ]
	}
    }

    $id{Marge} = $storage->insert($marge);
    main::isnt($id{Marge}, 0, "Marge inserted OK")
	    if defined &main::isnt;

    my $abraham = NaturalPerson->new( firstName => 'Abraham',
				      age => 62,
				      ($children =~ m/children/
				       ? ($children =~ m/s_/
					  ? ( $children => Set::Object->new($homer) )
					  : ( $children => [ $homer ] ) )
				       : () ),
				    );
    $id{Abraham} = $storage->insert($abraham);

    $storage->disconnect;
}

package SpringfieldObject;

use vars qw( $pop $VERBOSE );

sub new
{
   my $pkg = shift;
   ++$pop;
   my $foo = bless { $pkg->defaults, @_ }, $pkg;
   print STDERR "# I am alive!  $foo\n"
       if $VERBOSE;
   return $foo;
}

sub defaults
{
   return ();
}

sub DESTROY
{
#   die if exists shift->{id};
    print STDERR "# I am dying!  $_[0]\n"
	if $VERBOSE;
   --$pop;
}

package Person;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

sub as_string
{
   die 'subclass responsibility';
}

#use overload '""' => sub { shift->as_string }, fallback => 1;

package NaturalPerson;
use vars qw(@ISA);
@ISA = qw( Person );

# BEGIN ks.perl@kurtstephens.com 2003/10/16
our $person_id = 0;
# END ks.perl@kurtstephens.com 2003/10/16

sub defaults
{
   'person_id' => ++ $person_id, # ks.perl@kurtstephens.com 2003/10/16
   a_children => [], ia_children => [],
	s_children => Set::Object->new, is_children => Set::Object->new,
   h_opinions => {}
}

sub as_string
{
   my ($self) = @_;
	local $^W; # why? get use of undefined value otherwise
   exists($self->{name}) && exists($self->{firstName}) && "$self->{firstName} $self->{name}"
	|| $self->{firstName} || $self->{name}
}

package LegalPerson;

use vars qw(@ISA);
@ISA = 'Person';

sub as_string
{
   return shift->{name};
}

package NuclearPlant;
use vars qw(@ISA);
@ISA = qw( LegalPerson );

package Opinion;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

package Credit;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

package Item;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

package Faerie;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

package FaerieHairy;
use vars qw(@ISA);
@ISA = qw( SpringfieldObject );

1;
