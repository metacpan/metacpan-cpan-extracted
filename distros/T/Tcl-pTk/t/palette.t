# Test Case setPalette commands
#

use Tcl::pTk;
use Test;

plan tests => 1;

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

# Generate some events for testing
$TOP->after(1000, sub{
                $TOP->setPalette('seashell4'); 
}
);

# Generate some events for testing
$TOP->after(2000, sub{
                $TOP->bisque()
}
);

$TOP->after(4000,
        sub{
                ok( 1, 1, "setPalette check");

                $TOP->destroy;
        });
MainLoop;

