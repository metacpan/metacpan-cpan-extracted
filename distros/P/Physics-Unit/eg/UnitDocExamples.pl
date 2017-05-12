# This test program contains all the examples from the Physics::Unit
# documentation.

use Physics::Unit ':ALL';   # exports all util. function names
use Data::Dumper;

my %example_num;
sub header {
    my ($doc, $sec) = @_;
    my $num = $example_num{$doc . $sec}++;

    print "-" x 70, "\n";
    print "$doc - $sec, $num\n\n";
}

#-----------------------------------------------------------
header("Physics::Unit", "SYNOPSIS");

    use Physics::Unit ':ALL';   # exports all util. function names
    # Define your own unit named "ff"
    $ff = new Physics::Unit('furlong / fortnight', 'ff');
    print $ff->type, "\n";         # prints:  Speed
    # Convert to mph; this prints:  One ff is 0.0003720... miles per hour
    print "One ", $ff->name, " is ", $ff->convert('mph'), " miles per hour\n";
    # Get canonical string representation
    print $ff->expanded, "\n";     # prints:  0.0001663... m s^-1
    # More intricate unit expression (using the newly defined unit 'ff'):
    $gonzo = new Physics::Unit "13 square millimeters per ff";
    print $gonzo->expanded, "\n";  # prints:  0.07816... m s
    # Doing arithmetic maintains the types of units
    $m = $ff->copy->times("5 kg");
    print "This ", $m->type, " unit is ", $m->ToString, "\n";
    # prints: This Momentum unit is 0.8315... m gm s^-1


#-----------------------------------------------------------
header("Physics::Unit", "Functions");

  InitBaseUnit('Beauty' => ['sonja', 'sonjas', 'yh']);

  print "Beauty:  " . Physics::Unit::LookName('Beauty') . "\n";

#-----------------------------------------------------------
header("Physics::Unit", "Functions");

  InitPrefix('gonzo' => 1e100, 'piccolo' => 1e-100);
  $beautification_rate = new Physics::Unit('5 piccolosonjas / hour');

  print "gonzo:  " . Physics::Unit::LookName('gonzo') . "\n";
  print "piccolo:  " . Physics::Unit::LookName('piccolo') . "\n";
  print "beautification_rate:  " . $beautification_rate->ToString() . "\n";

#-----------------------------------------------------------
header("Physics::Unit", "Functions");

  InitUnit( ['chris', 'cfm'] => '3 piccolosonjas' );

  print "chris:  " . GetUnit('chris')->ToString() . "\n";
  print "cfm:  " . GetUnit('cfm')->ToString() . "\n";

#-----------------------------------------------------------
header("Physics::Unit", "Functions");

  InitUnit( ['mycron'], '3600 sec' );
  print Dumper(GetUnit('mycron'));

  InitUnit( ['mycron'], 'hour' );
  InitUnit( ['mycron'], GetUnit('hour') );

#-----------------------------------------------------------
header("Physics::Unit", "Functions");

  InitTypes( 'Blooming' => 'sonja / year' );

  print "Blooming:  " . Physics::Unit::LookName('gonzo') . "\n";

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  # Create a new, named unit:
  $u = new Physics::Unit ('3 pi furlongs', 'gorkon');

  print Dumper($u);

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  print GetUnit('rod')->type, "\n";  # 'Distance'

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  $u1 = new Physics::Unit('kg m^2/s^2');
  $t = $u1->type;       #  ['Energy', 'Torque']
  print Dumper $t;
  $u1->type('Energy');  #  This establishes the type once and for all
  $t = $u1->type;       #  'Energy'
  print Dumper $t;
  # Create a new copy of a predefined, typed unit:
  $u3 = GetUnit('joule')->new;
  $t = $u3->type;       # 'Energy'
  print Dumper $t;

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  print GetUnit('calorie')->expanded, "\n";  # "4184 m^2 gm s^-2"

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  print GetUnit('mile')->convert('foot'), "\n";  # 5280

#-----------------------------------------------------------
header("Physics::Unit", "Methods");

  $u = new Physics::Unit('36 m^2');
  print $u->ToString() . "\n";
  $u->divide('3 meters');   # now '12 m'
  print $u->ToString() . "\n";
  $u->divide(3);            # now '4 m'
  print $u->ToString() . "\n";
  $u->divide('.5 sec');     # now '8 m/s'
  print $u->ToString() . "\n";


print "\n\nok\n";

