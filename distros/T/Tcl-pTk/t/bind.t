# Test Case for bind and commands
#

use Tcl::pTk;
use Test;

plan tests => 15;

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

# Check a button created with the fast option (i.e. the underscore)
my $b3 = $TOP->_Button( -text    => 'Button3',
                      -width   => 10,
                      );

my ($mouseX, $mouseY); # x/y coords for the following binding
$TOP->bind(
        '<2>',[
        sub {
                   my @args = @_;
                   ($mouseX, $mouseY) = @args[1,2];
                   #print "Args = ".join(", ", @args)."\n";
                   #print "You pressed mouse button 2\n";
           }, Ev('x'), Ev('y')
           ]
        
);

# Indiv button
$b->bind(
        '<3>',
        sub {
                   my @args = @_;
                   print "You pressed mouse button 3\n";
           }
        
);

my $eventSource;

# whole class binding button
$TOP->bind(ref($b),
        '<Shift-3>',
        sub {
                   my @args = @_;
                   $eventSource = $_[0]; # record the event source
                   print "You pressed shift mouse 3\n";
           }
        
);



my @bindings = $TOP->bind();
#print "TOP binding: ".join(", ", @bindings)."\n";
ok( join(", ", @bindings), '<Button-2>', "No Arg bind call");

my $binding = $TOP->bind('<2>');
ok( ref($binding) , 'Tcl::pTk::Callback', "bind returns Tcl::pTk::Callback Object");
#print "binding = $binding\n";


@bindings = $TOP->bind(ref($TOP));
ok( join(", ", @bindings), '', "Class Tag bind call with no bindings defined");
#print "TOP bind return with ".ref($TOP)." single arg: ".join(", ", @bindings)."\n";

# Cancel a binding and put it backbinding
$TOP->bind('<2>', undef);
@bindings = $TOP->bind();
#print "TOP binding: ".join(", ", @bindings)."\n";

$TOP->bind(
        '<2>',[
        sub {
                   my @args = @_;
                   ($mouseX, $mouseY) = @args[1,2];
                   #print "Args = ".join(", ", @args)."\n";
                   #print "You pressed mouse button 2\n";
           }, Ev('x'), Ev('y')
           ]
        
);

###########################################
@bindings = $b->bind();
ok( join(", ", @bindings), '<Button-3>', "Button1 bind return with no args");
#print "button1 bind return with no args: ".join(", ", @bindings)."\n";

@bindings = $b->bind(ref($b));
ok( join(", ", @bindings), '<Shift-Button-3>', "button1 bind return with ".ref($b)." single arg");
#print "button1 bind return with ".ref($b)." single arg: ".join(", ", @bindings)."\n";

###########################################
@bindings = $b2->bind();
ok( join(", ", @bindings), '', "button2 bind return with no args");
#print "button2 bind return with no args: ".join(", ", @bindings)."\n";

@bindings = $b2->bind(ref($b2));
ok( join(", ", @bindings), '<Shift-Button-3>', "button1 bind return with ".ref($b)." single arg");
#print "button2 bind return with ".ref($b)." single arg: ".join(", ", @bindings)."\n";

ok( join(", ", $b2->bindtags), 'Tcl::pTk::Button, Button, .btn03, ., all', "button2 bindtags");

# widget created with the _Button call should have correct perl/tk-compatible bindtags
ok( join(", ", $b3->bindtags), 'Tcl::pTk::Button, Button, .btn04, ., all', "button2 bindtags");

#print "b3 bindings = ".join(", ", $b3->bindtags())."\n";
my $classBinding = $b2->bind(ref($b2), '<Shift-3>');
ok( ref($classBinding), 'Tcl::pTk::Callback', ref($b2)." Class Binding Returns Callback Object");
#print ref($b2)." Class Binding = $classBinding\n";
############################################
# Check of bindtags
my @existingBindTags = $b2->bindtags();
$b2->bindtags(["bogus", "fred"]);
ok( join(", ", $b2->bindtags), 'bogus, fred', "bindtags check");
#print "button2 bindtags = ".join(", ", $b2->bindtags)."\n";
$b2->bindtags([@existingBindTags]);


# Check the commands associated with the buttons
$b->invoke();
$b2->invoke();

ok($button1Pressed, 1, "Button 1 pressed");
ok($button2Pressed, 1, "Button 1 pressed");

# Generate some events for testing
$TOP->update();
$TOP->idletasks();

$TOP->eventGenerate('<2>', -x => 50, -y => 60); # For checking x/y substitution

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}

$b2->eventGenerate('<Shift-3>'); # For checking event source for class binding

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}

ok( join(", ", $mouseX, $mouseY), '50, 60', "Binding Ev Substitution");
ok( ref($eventSource), 'Tcl::pTk::Button', "Class Binding Event Source");


