#!/usr/local/bin/perl -w

# Example/test of using the Pane widget (translated from Tk::Pane to use the
#  tcl ScrollableFrame widget
# This test skips if BWidget tcl package not available.
#   

use Tcl::pTk;
use Tcl::pTk::Pane;
#use Tk;
#use Tk::Pane;

use Test;
plan tests => 1;

$| = 1; # Pipes Hot
my $top = MainWindow->new;

# This will return undef if BWidget not present
my $retVal = $top->interp->pkg_require('BWidget');

unless( $retVal){
        skip("BWidget Tcl package not available", 1);
        exit;
}


my $sff = $top->Scrolled('Pane',  -scrollbars => 'soe',
    -sticky => 'we',
        -width => 200, -height => 200);

#my $dude = $top->Pane();

my $sf = $sff->frame();
# turn path into a widget
#$sf = $top->interp->declare_widget($sf, 'Tcl::pTk::Frame');

my @labels;
foreach my $i (1..25){
        my $Label = $sff->Label(-text => "Label $i")->pack();
        push @labels, $Label;
}

$sff->pack(-fill => 'both', -expand => 1);

$top->after(1000,
        sub{
                $sff->see($labels[14], -anchor => 'n');
        }
        );
$top->after(2000,
        sub{
                $top->destroy();
        }
        );

MainLoop;

ok(1);
