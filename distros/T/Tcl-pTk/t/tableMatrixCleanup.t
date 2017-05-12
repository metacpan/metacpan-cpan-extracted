#!/usr/local/bin/perl -w

# Tablematrix prototype support in Tcl/pTk
#   This includes the Variable Tracing that works with large arrays, without causing
#   performance issues.
#   

use Tcl::pTk;
use Tcl::pTk::TableMatrix;
use Test;



use Data::Dumper;

$| = 1; # Pipes Hot
my $top = MainWindow->new;

# This will skip if Tktable not present
my $retVal = $top->interp->pkg_require('Tktable');

unless( $retVal){
	plan test => 1;
        skip("Tktable Tcl package not available", 1);
        exit;
}

plan test => 2;

my $arrayVar = {};

#print "Filling Array...\n";
my ($rows,$cols) = (20, 10);
foreach my $row  (0..($rows-1)){
	foreach my $col (0..($cols-1)){
		$arrayVar->{"$row,$col"} = "$row,$col";
	}
}
#print "Creating Table...\n";
## Test out the use of a callback to define tags on rows and columns
sub colSub{
	my $col = shift;
	return "OddCol" if( $col > 0 && $col%2) ;
}

my $varTraceCmd;

my $label = $top->Label(-text => "TableMatrix v2 Example");
{
        my $toplevel = $top->Toplevel();
        my $t = $toplevel->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
#        my $t = $toplevel->TableMatrix( -rows => $rows, -cols => $cols, 
                                      -width => 6, -height => 6,
                                       -titlerows => 1, -titlecols => 1,
                                      -variable => $arrayVar,
                                      -coltagcommand => \&colSub,
                                      -colstretchmode => 'last',
                                      -rowstretchmode => 'last',
                                      -selectmode => 'extended',
                                      -selecttitles => 0,
                                      -drawmode => 'slow',
                            );
        
        my $button = $toplevel->Button( -text => "Exit", -command => 
                sub{ $t = undef; $toplevel->destroy
                     });		    
        
        # Color definitions here:
        $t->tagConfigure('OddCol', -bg => 'lightsalmon1', -fg => 'black');
        $t->tagConfigure('title', -bg => 'lightyellow2', -fg => 'blue', -relief => 'sunken');
        $t->tagConfigure('dis', -state => 'disabled');
        
        my $i = -1;
        my $first = $t->cget(-colorigin);
        my $anchor;
        foreach $anchor( qw/ n s e w nw ne sw se c /){
                $t->tagConfigure($anchor, -anchor => $anchor);
                $t->tagRow($anchor, ++$i);
                $t->set( "$i,$first",$anchor);
        }
        $top->fontCreate('courier', -family => 'courier', -size => 10);
        $t->tagConfigure('s', -font => 'courier', -justify => 'center');
        
        
        $t->colWidth( -2 => 8, -1 => 9, 0=> 12,  4=> 14);
        
        $label->pack( -expand => 0, -fill => 'y');
        
        $t->pack(-expand => 1, -fill => 'both');
        $button->pack(-expand => 0, -fill => 'x');
        
        # Get Name of trace command (for checking later that it has been deleted)
        $varTraceCmd = $t->Subwidget('tablematrix')->{varTraceCmd};
        #print "command = $varTraceCmd\n";

        #my @commands = $t->interp->invoke('info', 'command', $varTraceCmd);
        #print "commands = ".join(", ", @commands)."\n";
 
        # Change the -variable option, TableMatrix should redisplay and refresh
        $top->after(1000, sub{
                        # Change all of arrayVar to something else
                        foreach (keys %$arrayVar){
                                $arrayVar->{$_} = "Changed!";
                        }
                        $t->configure(-variable => $arrayVar);
                        
                        my $value = $t->get("1,1");
                        ok( $value, "Changed!", "Check of -variable change");
                }
        );
                        
        
        # Delete the toplevel after some time. widgets should be destroyed and cleaned-up
        $top->after(2000, sub{
                        $toplevel->destroy;
                        my @commands = $t->interp->invoke('info', 'command', $varTraceCmd);
                        
                        if( Tcl::pTk::WIDGET_CLEANUP ){
                                # There should be nothing in @commands, if the trace command was properly deleted
                                ok(scalar(@commands), 0, "Check of trace command deletion");
                                #print "commands = ".join(", ", @commands)."\n";
                        }
                        else{
                                skip("Widget cleanup not enabled", 1);
                        }
                        
                        
                }) unless(@ARGV); # if args supplied, don't exit right away (for debugging)
               


}


$top->after(3000, sub{
                $top->destroy;
}) unless(@ARGV); # if args supplied, don't exit right away (for debugging)
 

MainLoop;


        

