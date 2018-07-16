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

plan test => 10;

my $arrayVar = {};

#print "Filling Array...\n";
my ($rows,$cols) = (20, 10);
foreach my $row  (0..($rows-1)){
	foreach my $col (0..($cols-1)){
		$arrayVar->{"$row,$col"} = "$row,$col";
	}
}

my ($CmdRow, $CmdCol);
####### Callback for the -command option #####
sub tblCmd{ 
	my ($array, $set, $row,$col,$val) = @_;
	#my @args = @_;
	#print "In Table Command, Args = '".join("', '",@args)."'\n";
        
        # Save the row/col values so we can check later
        $CmdRow = $row;
        $CmdCol = $col;
        
	my $index = "$row,$col";
	if( $set ){
		$array->{$index} = $val;
	}
	else{
		if( defined( $array->{$index})){
			return $array->{$index};
		}
		else{
			return '';
		}
	}
}


my $label = $top->Label(-text => "TableMatrix v2 Example");
my $t = $top->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
#        my $t = $toplevel->TableMatrix( -rows => $rows, -cols => $cols, 
                                      -width => 6, -height => 6,
                                       -titlerows => 1, -titlecols => 1,
                                      -variable => $arrayVar,
                                      -command => [\&tblCmd, $arrayVar],
                                      -coltagcommand => \&colSub,
                                      -colstretchmode => 'last',
                                      -rowstretchmode => 'last',
                                      -selectmode => 'extended',
                                      -selecttitles => 0,
                                      -drawmode => 'slow',
                            );


# Create browsecmd callback
my ($prevIndex, $currentIndex) = ('', '');
$t->configure(-browsecmd => sub{
         ($prevIndex, $currentIndex) = @_;
         
         #print "prevIndex = $prevIndex currentIndex = $currentIndex\n";
});

# Setup selectioncommand callback
my ($NumRows,$NumCols,$selection,$noCells);
$t->configure(  
		-selectioncommand => sub{
					($NumRows,$NumCols,$selection,$noCells) = @_;
					my @args = @_;
					#print "In Selection Command, Args = '".join("', '",@args)."'\n";
					return $selection;
					}
		);




# Setup test for browsecmd callback
$top->after(1000, sub{
                $t->activate('2,2');
                ok($prevIndex, '',    "browsecmd previndex 1");
                ok($currentIndex, '2,2', "browsecmd currentIndex 1");
});

# Setup test for other callbacks
$top->after(2000, sub{
                $t->activate('2,3');
                ok($prevIndex, '2,2',    "browsecmd previndex 2");
                ok($currentIndex, '2,3', "browsecmd currentIndex 2");

                # Check to see if CmdRow and CmdCol are defined
                ok(defined($CmdRow), 1, '-command row arg defined');
                ok(defined($CmdCol), 1, '-command col arg defined');
                
                # check selectioncommand callback
                $t->selection('set',  '2,2',   '3,5');
                my $seltext = $t->GetSelection(); # clear out current selection
                ok($seltext, $selection, "selectioncommand selected text");
                ok($NumRows, 2, "selectioncommand NumRows");
                ok($NumCols, 4, "selectioncommand NumCols");
                ok($noCells, 8, "selectioncommand NoCells");


});



$t->pack();


$top->after(3000, sub{
                $top->destroy;
}) unless(@ARGV); # if args supplied, don't exit right away (for debugging)
 

MainLoop;


        

