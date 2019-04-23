#!/usr/bin/perl
#

### Example of subclassing #####
###  This script tests for proper output value typing of the major
###   categories of PDLA primitive operations.
###       For example:
###           If $pdlderived is a PDLA::derived object (subclassed from PDLA),
###              then $pdlderived->sumover should return a PDLA::derived object.
###      
use PDLA::LiteF;
use Test::More tests => 14;


# Test PDLA Subclassing via hashes

########### Subclass typing Test ###########

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
## Now check to see if the different categories of primitive operations
##   return the PDLA::Derived type.
package main;

# Create a PDLA::Derived instance

$z = PDLA::Derived->new( ones(5,5) ) ;

ok(ref($z)eq"PDLA::Derived", "create derived instance");



#### Check the type after incrementing:
$z++;
ok(ref($z) eq "PDLA::Derived", "check type after incrementing");


#### Check the type after performing sumover:
$y = $z->sumover;
ok(ref($y) eq "PDLA::Derived", "check type after sumover");


#### Check the type after adding two PDLA::Derived objects:
$x = PDLA::Derived->new( ones(5,5) ) ;
$w = $x + $z;
ok(ref($w) eq "PDLA::Derived", "check type after adding");

#### Check the type after calling null:
$a1 = PDLA::Derived->null();
ok(ref($a1) eq "PDLA::Derived", "check type after calling null");



##### Check the type for a byops2 operation:
$w = ($x == $z);
ok(ref($w) eq "PDLA::Derived", "check type for byops2 operation");

##### Check the type for a byops3 operation:
$w = ($x | $z);
ok(ref($w) eq "PDLA::Derived", "check type for byops3 operation");

##### Check the type for a ufuncs1 operation:
$w = sqrt($z);
ok(ref($w) eq "PDLA::Derived", "check type for ufuncs1 operation");

##### Check the type for a ufuncs1f operation:
$w = sin($z);
ok(ref($w) eq "PDLA::Derived", "check type for ufuncs1f operation");

##### Check the type for a ufuncs2 operation:
$w = ! $z;
ok(ref($w) eq "PDLA::Derived", "check type for ufuncs2 operation");

##### Check the type for a ufuncs2f operation:
$w = log $z;
ok(ref($w) eq "PDLA::Derived", "check type for ufuncs2f operation");

##### Check the type for a bifuncs operation:
$w =  $z**2;
ok(ref($w) eq "PDLA::Derived", "check type for bifuncs operation");

##### Check the type for a slicing operation:
$a1 = PDLA::Derived->new(1+(xvals zeroes 4,5) + 10*(yvals zeroes 4,5));
$w = $a1->slice('1:3:2,2:4:2');
ok(ref($w) eq "PDLA::Derived", "check type for slicing operation");

##### Check that slicing with a subclass index works (sf.net bug #369)
$a1 = sequence(10,3,2);
$idx = PDLA::Derived->new(2,5,8);
ok(defined(eval 'my $r = $a1->slice($idx,"x","x");'), "slice works with subclass index");
