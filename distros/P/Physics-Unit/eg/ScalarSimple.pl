# This contains, among other things, the examples from the
# Physics::Unit::Scalar documentation.

use Physics::Unit::Scalar;


# Manipulate Distances

$d = new Physics::Unit::Distance('98 mi');
print "Distance is " . $d->ToString . "\n";

$d->add('10 km');
print "Sum is " . $d->ToString . "\n";

$miles = $d->ToString('mile');
print "Or, in miles:  $miles\n";
print "    which is " . $d->convert('mile') . " miles\n";

# Use the default unit for distance, which is meter
$d2 = new Physics::Unit::Distance('2000');
print "\$d2 is " . $d2->ToString . "\n";


# Manipulate Times

$t = Physics::Unit::Time->new('36 years');
print "36 years is " . $t->ToString . "\n";


# Compute a Speed = Distance / Time
$speed = $d->divide($t);
print "Speed is " . $speed->ToString . "\n";


# Create a Scalar with an unknown dimensionality

$s = new Physics::Unit::Scalar('kg m s');

# This calculation produces an object of the correct type
# automagically:  $f is a Physics::Unit::Force

$f = $s->divide('3000 s^3');
print "Force is " . $f->ToString . "\n";

