#  -*- cperl-mode -*-

use strict;

use lib 't/springfield';

use Springfield;

use Test::More tests => 70;

package Vehicle;

sub new
  {
	my $self = bless { }, shift;
  }

sub make
  {
	my $class = shift;
	my $self = bless { }, $class;
	@$self{ $self->fields } = @_;
	return $self;
  }

sub state
  {
	my $self = shift;
	join ' ', ref($self), @$self{ $self->fields };
  }

package Boat;
use base qw( Vehicle );

sub fields { qw( name knots ) }

package Plane;
use base qw( Vehicle );

sub fields { qw( name altitude ) }

package HydroPlane;
use base qw( Boat Plane );

sub fields { qw( name knots altitude whatever ) }

package main;

sub check
  {
	my ($storage, $test_name, $class, @states) = @_;
	my @objs;
	eval {
	    @objs = $storage->select($class);
	};
	is($@, "", "$test_name: selecting $class objects doesn't die");
	is(@objs, @states, "$test_name: correct # of $class objects");

	if (@objs == @states) {
	  my %states;
	  @states{ @states } = ();
	  delete @states{ map { $_->state } @objs };
	  is(keys %states, 0, "$test_name: objects correspond exactly");
	} else {
	SKIP:{
		skip("$test_name: carried error", 1);
	    }
	}
  }

sub test_mapping
  {
	my ($v, $b, $p, $h) = @_;

	my $test_name = "$v$b$p$h";
	
	my $schema = Tangram::Relational->schema
	    ( {
	       control => 'Vehicles',

	       classes =>
	       [
		Vehicle =>
		{
		 table => $v,
		 abstract => 1,
		 fields => { string => [ 'name' ] }
		},

		Boat =>
		{
		 table => $b,
		 bases => [ qw( Vehicle ) ],
		 fields => { int => [ 'knots' ] },
		},

		Plane =>
		{
		 table => $p,
		 bases => [ qw( Vehicle ) ],
		 fields => { int => [ 'altitude' ] },
		},

		HydroPlane =>
		{
		 table => $h,
		 bases => [ qw( Boat Plane ) ],
		 fields => { string => [ 'whatever' ] },
		},
	       ] } );

	use YAML;
	#diag(Dump $schema);

    SKIP: {
	    my $dbh = DBI->connect($Springfield::cs, $Springfield::user,
				   $Springfield::passwd, { PrintError => 0 });

	    # $Tangram::TRACE = \*STDOUT;
	    eval { $Springfield::dialect->retreat($schema, $dbh) };

	    eval { $Springfield::dialect->deploy($schema, $dbh); };
	    is($@, "", "$test_name: deploy succeeded")
		or skip "$test_name: deploy failed", 13;
	    $dbh->disconnect();

	    my $storage = Springfield::connect($schema);

	    # use Data::Dumper;	print Dumper $storage->{engine}->get_polymorphic_select($schema->classdef('Boat'));	die;
	    # my $t = HydroPlane->make(qw(Hydro 5 200 foo)); print Dumper $t; die;

	    eval {
		$storage->insert( Boat->make(qw( Erika 2 )),
				  Plane->make(qw( AF-1 20000 )),
				  HydroPlane->make(qw(Hydro 5 200 foo)) );
	    };
	    is($@, "", "$test_name: Inserting objects doesn't die");

	    check($storage, $test_name,
		  'Boat', 'Boat Erika 2', 'HydroPlane Hydro 5 200 foo');
	    check($storage, $test_name,
		  'Plane', 'Plane AF-1 20000', 'HydroPlane Hydro 5 200 foo');
	    check($storage, $test_name,
		  'HydroPlane', 'HydroPlane Hydro 5 200 foo');
	    check($storage, $test_name,
		  'Vehicle', 'Boat Erika 2', 'Plane AF-1 20000',
		  'HydroPlane Hydro 5 200 foo');

	    $storage->disconnect();
	}
  }

test_mapping('V', 'V', 'V', 'V');
test_mapping('V', 'V', 'V', 'H');
test_mapping('V', 'B', 'V', 'V');
test_mapping('V', 'V', 'P', 'V');
test_mapping('V', 'B', 'P', 'V');
__END__
{
	my $schema = $dialect
	  ->schema( {
				 control => 'Mappings',
				 classes =>
				 [
				  Fruit => { abstract => 1 },
				  Apple => { bases => [ 'Fruit' ] },
				  AppleTree => { fields => { iset => { fruits => 'Apple' } } }
				 ] } );

	$Tangram::TRACE = \*STDOUT;
	$dialect->retreat($schema, $cs, $user, $passwd, { PrintError => 0 });
	$dialect->deploy($schema, $cs, $user, $passwd, { PrintError => 0 });
							  
	my $storage = $dialect->connect($schema, $cs, $user, $passwd);
	$storage->insert( bless { fruits => Set::Object->new( bless { }, 'Apple' ) }, 'AppleTree' );
	$storage->disconnect();
														  
}
