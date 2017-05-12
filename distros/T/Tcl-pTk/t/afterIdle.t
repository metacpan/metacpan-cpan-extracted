# Check of OnDestroy operation

use Tcl::pTk;
#use Tk;

use Test;

plan tests => 1;

my $top = MainWindow->new;

my $afterIdleCalled = 0;

my $menubar = $top->Frame(qw/-relief raised -background DarkGreen -bd 2/);
$menubar->pack(-side => 'top', -fill => 'x');

#$menubar->bind('<Destroy>', sub{ print STDERR "Frame Destroyed\n"});

$menubar->afterIdle(['_dummySub', $top]);

$top->after(1000,sub{$top->destroy});

MainLoop;

ok($afterIdleCalled, 1, 'AfterIdle Callback not called');

# Dummy sub to set if method => object form works with afterIdel
sub Tcl::pTk::Widget::_dummySub{
        my $self = shift;
        $afterIdleCalled = 1;
}
