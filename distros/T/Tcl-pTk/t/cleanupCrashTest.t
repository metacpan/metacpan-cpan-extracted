#!/usr/local/bin/perl -w

# Simple example that crashes Tcl when run, before the cleanup mods of Tcl::pTk made on 3/26/09
#

use Tcl::pTk;
use Test;

plan test => 1;

my $top = MainWindow->new;

my $label = $top->Label( -text => "Main Window" )->pack();

my $optionsDialog = $top->Toplevel( -title => 'Plot Options' );

# 'Auto' Label
$optionsDialog->Label( -text => 'Auto' )->pack();

my $minY;

# Min Check Button and Value:
$optionsDialog->Checkbutton( -text     => 'Minimum',
                             -variable => \$minY, # Cammenting this out makes the crash go away
                             -relief   => 'flat'
)->pack();



$top->after(1000,
        sub{
                        # use settings to update the
                        # settings
                        $optionsDialog->destroy;
                        #$self->{window}->update;
                        $top->Busy;
                        $top->Unbusy;
        });

$top->after(
        3000,
        sub {
                $top->destroy;
        }
) unless (@ARGV);    # if args supplied, don't exit right away (for debugging)

MainLoop;

ok( 1, 1, "If we got here, we passed (no crashes)");


        

