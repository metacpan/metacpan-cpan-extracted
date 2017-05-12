# check.pl

use strict;
use Test;
use Tcl::pTk;  # import eventtypes, because we are going to check to see if DoOneEvent works



use vars qw/$TOP $WIPERS $BRAKES $SOBER $POINT_SIZE/;

plan tests => 1;

my $TOP = MainWindow->new();



    # initialize variables if not defined
    foreach ( $WIPERS, $BRAKES, $SOBER){
            $_ = 0 unless( defined($_));
    }
    
    my $var = $TOP->Button(
        -text    => 'Button',
    );
    $var->pack(qw/-side bottom -expand 1/);

    my(@pl) = qw/-side top -pady 2 -anchor w/;
    my $b1 = $TOP->Checkbutton(
        -text     => 'Wipers OK',
        -variable => \$WIPERS,
	-relief   => 'flat')->pack(@pl);
    my $b2 = $TOP->Checkbutton(
        -text     => 'Brakes OK',
        -variable => \$BRAKES,
	-relief   => 'flat')->pack(@pl);
    my $b3 = $TOP->Checkbutton(
        -text     => 'Driver Sober',
        -variable => \$SOBER,
	-relief   => 'flat')->pack(@pl);
        
    $POINT_SIZE = 10;
    foreach my $p (10, 12, 18, 24) {
	$TOP->Radiobutton(
            -text     => "Point Size $p",
            -variable => \$POINT_SIZE,
            -relief   => 'flat',
            -value    => $p,
        )->pack(@pl);
    }
    
$TOP->after(1000,sub{$TOP->destroy});

ok(1, 1, "Check/Radio button Creation");

MainLoop;

1;
