#!/usr/bin/perl
#
use PDLA::LiteF;
use Test::More tests => 8;


########### Test of Subclassed-object copying for simple function cases ###########


##  First define a PDLA-derived object:
package PDLA::Derived;
@PDLA::Derived::ISA = qw/PDLA/;

sub new {
   my $class = shift;

   my $data = $_[0];

   my $self;
   if(ref($data) eq 'PDLA' ){ # if $data is an object (a pdl)
	   $self = $class->initialize;
	   $self->{PDLA} = $data;
   }
   else{	# if $data not an object call inherited constructor
	   $self = $class->SUPER::new($data);
   }

   return $self;
}

####### Initialize function. This over-ridden function is called by the PDLA constructors
sub initialize {
	my $class = shift;
        my $self = {
                PDLA => PDLA->null, 	# used to store PDLA object
		someThingElse => 42,
        };
	$class = (ref $class ? ref $class : $class );
        bless $self, $class;
}

###### Derived Object Needs to supply its own copy #####
sub copy {
	my $self = shift;
	
	# setup the object
	my $new = $self->initialize;
	
	# copy the PDLA
	$new->{PDLA} = $self->{PDLA}->SUPER::copy;

	# copy the other stuff:
	$new->{someThingElse} = $self->{someThingElse};

	return $new;

}


#######################################################
package main;

###### Testing Begins #########

# Create New PDLA::Derived Object
#   (Initialize sets 'someThingElse' data member
#     to 42)
$im = new PDLA::Derived [
  [ 1, 2,  3,  3 , 5],
  [ 2,  3,  4,  5,  6],
  [13, 13, 13, 13, 13],
  [ 1,  3,  1,  3,  1],
  [10, 10,  2,  2,  2,]
 ];

#  Set 'someThingElse' Data Member to 24. (from 42)
$im->{someThingElse} = 24;

# Test to see if simple functions (a functions
#    with signature sqrt a(), [o]b() ) copies subclassed object correctly.
my @simpleFuncs = (qw/ 
bitnot sqrt abs sin cos not exp log10 /);

foreach my $op( @simpleFuncs){
	
	$w = $im->$op(); 

	ok($w->{someThingElse} == 24, "$op subclassed object correctly"); 
}
