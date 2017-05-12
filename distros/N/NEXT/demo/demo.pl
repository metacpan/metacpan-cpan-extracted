use NEXT;

package A;
sub A::method   { print "$_[0]: A method\n"; $_[0]->NEXT::method() }
sub A::DESTROY  { print "$_[0]: A dtor\n"; $_[0]->NEXT::DESTROY() }

package B;
use base qw( A );
sub B::AUTOLOAD { print "$_[0]: B AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
sub B::DESTROY  { print "$_[0]: B dtor\n"; $_[0]->NEXT::DESTROY() }

package C;
sub C::DESTROY  { print "$_[0]: C dtor\n"; $_[0]->NEXT::DESTROY() }

package D;
@D::ISA = qw( B C E );
sub D::method   { print "$_[0]: D method\n"; $_[0]->NEXT::method() }
sub D::AUTOLOAD { print "$_[0]: D AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
sub D::DESTROY  { print "$_[0]: D dtor\n"; $_[0]->NEXT::DESTROY() }
sub D::oops     { print "$_[0]: D oops\n"; $_[0]->NEXT::method() }

package E;
@E::ISA = qw( F G );
sub E::method   { print "$_[0]: E method\n";
			 $_[0]->NEXT::method();
			 $_[0]->NEXT::method() }
sub E::AUTOLOAD { print "$_[0]: E AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
sub E::DESTROY  { print "$_[0]: E dtor\n"; $_[0]->NEXT::DESTROY() }

package F;
sub F::method   { print "$_[0]: F method\n"; }
sub F::AUTOLOAD { print "$_[0]: F AUTOLOAD\n"; }
sub F::DESTROY  { print "$_[0]: F dtor\n"; }

package G;
sub G::method   { print "$_[0]: G method\n"; $_[0]->NEXT::method() }
sub G::AUTOLOAD { print "$_[0]: G AUTOLOAD\n"; $_[0]->NEXT::AUTOLOAD() }
sub G::DESTROY  { print "$_[0]: G dtor\n"; $_[0]->NEXT::DESTROY() }

package main;

my $obj = bless {}, "D";

print "\nRedispatch actual methods:\n";
$obj->method();

print "\nRedispatch actual methods again (should be identical):\n";
$obj->method();

print "\nRedispatch AUTOLOADed methods:\n";
$obj->missing_method();

print "\nNamed method can't redispatch to named method of different name:\n";
eval { $obj->oops() } || print $@;

eval q{
	package C;
	sub AUTOLOAD { print "$_[0]: C AUTOLOAD\n"; $_[0]->NEXT::method() };
};
print "\nAUTOLOADed method can't redispatch to named method:\n";
eval { $obj->missing_method(); } || print $@;

eval q{ 
	package C;
	sub method { print "$_[0]: C method\n"; $_[0]->NEXT::AUTOLOAD() };
};
print "\nNamed method can't redispatch to AUTOLOADed method:\n";
eval { $obj->method(); } || print $@;

print "\nBase class methods only redispatched within hierarchy:\n";
my $ob2 = bless {}, "B";
$ob2->method();         
$ob2->missing_method(); 

print "\nCan redispatch destructors:\n";
