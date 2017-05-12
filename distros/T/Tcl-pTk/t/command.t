# Example of the Ev sematics in Tcl::pTk to get the Tcl '%x, %y', etc substitutions
#

use Tcl::pTk;
use Test;

plan tests => 3;

$| = 1;

my $TOP = MainWindow->new;

my $b = $TOP->Button( -text    => 'Button',
                      -width   => 10,
                      -command => sub { print "You pressed a button\n" },
);
$b->pack(qw/-side top -expand yes -pady 2/);

my $b2 = $TOP->Button( Name => 'nondefaultname', 
                      -text    => 'Button',
                      -width   => 10,
                      ,
);
$b2->pack(qw/-side top -expand yes -pady 2/);


# Set a callback after creation
$b2->configure(-command => sub { print "You pressed a button\n" });

my $command = $b->cget(-command);

ok( ref($command), 'Tcl::pTk::Callback');

# Check for a callback return type for callback specified during widget creation.

$command = $b2->cget(-command);

ok( ref($command), 'Tcl::pTk::Callback');

# Check for the optional name being used in the creation of b2
# 
ok($b2->PathName, '.nondefaultname03');

$TOP->after(1000,sub{$TOP->destroy});
MainLoop;

