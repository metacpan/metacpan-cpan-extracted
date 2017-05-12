# Test Case for bind and commands
#  This test to see if the break command works in bindings. i.e. keeps further bindings from
#   being being run.
#

use Tcl::pTk;
#use Tk;
use Test;

plan tests => 2;

$| = 1;

my $TOP = MainWindow->new;

my $button1Pressed = 0;
my $button2Pressed = 0;

my $b = $TOP->Button( -text    => 'Button1',
                      -width   => 10,
                      -command => sub { $button1Pressed = 1; },
);
$b->pack(qw/-side top -expand yes -pady 2/);

my $b2 = $TOP->Button( -text    => 'Button2',
                      -width   => 10,
                      -command => sub { $button2Pressed = 1; },
);
$b2->pack(qw/-side top -expand yes -pady 2/);


my $indivBinding = 0;
my $classBinding = 0;

# Indiv button binding
$b->bind(
        '<3>',
        sub {
                   my @args = @_;
                   #print "indivBinding\n";
                   $indivBinding = 1;
           }
        
);


# Button class binding
$b->bind( ref($b),
        '<3>',
        sub {
                   my @args = @_;
                  # print "classBinding\n";
                   $classBinding = 1;
                   Tcl::pTk::break();
           }
        
);

# Check to see if break doesn't die outside of a binding
Tcl::pTk::break();

# Generate some events for testing

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}
$b->eventGenerate('<3>'); # For checking event source for class binding

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}


ok( $classBinding, 1, "Class binding fired");
ok( $indivBinding, 0, "Indiv binding should not fire");


