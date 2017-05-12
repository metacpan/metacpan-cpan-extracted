# Test of getting/setting callbacks from -command options
#

use Tcl::pTk;
use Test;

plan tests => 2;

$| = 1;

my $TOP = MainWindow->new;

my $buttonPressed = 0;
my $b = $TOP->Button( -text    => 'Button',
                      -width   => 10,
                      -command => sub { $buttonPressed = 1;
                                        print "You pressed a button\n" },
);
$b->pack(qw/-side top -expand yes -pady 2/);



my @conf = $b->configure();

my ($commandEntry) = grep $_->[0] eq '-command', @conf;

my $callback = $commandEntry->[4];

ok(ref($callback), 'Tcl::pTk::Callback', "No Arg Configure Callback Return Check");

# Set the command option again to what was returned
$b->configure(-command => $callback);


$TOP->after(1000, sub{
                $b->invoke();
                $TOP->destroy();
                }
);


MainLoop;

ok($buttonPressed, 1, "Callback properly reset ");

