# This test program contains all the examples from the Physics::Unit
# documentation.

use Physics::Unit::Scalar;
use Data::Dumper;

my %example_num;
sub header {
    my ($doc, $sec) = @_;
    my $num = $example_num{$doc . $sec}++;

    print "-" x 70, "\n";
    print "$doc - $sec, $num\n\n";
}

#-----------------------------------------------------------
header("Physics::Unit::Scalar", "SYNOPSIS");

    # Distances
    $d = new Physics::Unit::Distance('98 mi');
    print $d->ToString, "\n";             # prints 157715.712 meter
    $d->add('10 km');
    print $d->ToString, "\n";  # prints 167715.712 meter
    print $d->value, ' ', $d->default_unit->name, "\n";   # same thing

    # Convert
    print $d->ToString('mile'), "\n";        # prints 104.213... mile
    print $d->convert('mile'), " miles\n";   # same thing (except 'miles')

    $d2 = new Physics::Unit::Distance('2000');   # no unit given, use the default
    print $d2->ToString, "\n";                   # prints 2000 meter

    # Times
    $t = Physics::Unit::Time->new('36 hours');
    print $t->ToString, "\n";              # prints 129600 second

    # Speed = Distance / Time
    $s = $d->divide($t);            # $s is a Physics::Unit::Speed object
    print $s->ToString, "\n";    # prints 1.2941... mps

    # Automatic typing
    $s = new Physics::Unit::Scalar('kg m s');   # Unrecognized type
    print ref $s, "\n";          # $s is a Physics::Unit::Scalar
    $f = $s->divide('3000 s^3');
    print ref $f, "\n";          # $f is a Physics::Unit::Force


#-----------------------------------------------------------
header("Physics::Unit::Scalar", "DESCRIPTION");

  $d = new Physics::Unit::Distance('98 mi');
  $t = new Physics::Unit::Time('36 years');
  # $s will be of type Physics::Unit::Speed.
  $s = $d->divide($t);

  print ref $s, "\n";

#-----------------------------------------------------------
header("Physics::Unit::Scalar", "METHODS");

    # This creates an object of a derived class
    $d = new Physics::Unit::Distance('3 miles');
    print ref $d, " -> ", $d->ToString(), "\n";

    # This does the same thing; the type is figured out automatically
    # $d will be a Physics::Unit::Distance
    $d = new Physics::Unit::Scalar('3 miles');
    print ref $d, " -> ", $d->ToString(), "\n";

    # Use the default unit for the subtype (for Distance, it's meters):
    $d = new Physics::Unit::Distance(10);
    print ref $d, " -> ", $d->ToString(), "\n";

    # This defaults to one meter:
    $d = new Physics::Unit::Distance;
    print ref $d, " -> ", $d->ToString(), "\n";

    # Copy constructor:
    $d2 = $d->new;
    print "d2 is a ", ref $d2, " -> ", $d2->ToString(), "\n";

