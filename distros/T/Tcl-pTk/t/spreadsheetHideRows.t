# Example of Tk::TableMatrix::SpreadsheetHideRows widget:
#   Table display with hidden detail data
#
# This example displays made-up average temperature data
#  for different time periods (quarter and months), and regions.

# Updated to have more spans. 3/8/06. Fully expanding Row 2 and the
#    lower level Rows should look ok, with the spans restoring back
#    to where they were.

use Tcl::pTk;

use Tcl::pTk::TableMatrix::SpreadsheetHideRows;
use Test;
plan tests => 1;

my $top = MainWindow->new;

# This will skip if Tktable not present
my $retVal = $top->interp->pkg_require('Tktable');

unless( $retVal){
        skip("Tktable Tcl package not available", 1);
        exit;
}

my $arrayVar = {};

my @rawdata = (qw/ 
Quarter	Month	Region	State	AvgTemp	
1	--	South	--	39	
2	--	South	--	61	
3	--	South	--	65	
4	--	South	--	45	
/);



foreach my $row  (0..4){
	foreach my $col (0..5){
		next if( $col == 0);
			
		$arrayVar->{"$row,$col"} = shift @rawdata;
	}
}


my $expandData = {
	1 => { data => [ [ '','','Jan', 'South','--',33],
	                 [ '','','Feb', 'South','--',38],
	                 [ '','','Mar', 'South','--',45],
			 ],
	       tag => 'detail',		
	       expandData => {
	       			1 => { data => [ [ '','','', '','Texas',35],
				        	  [ '','','', '','Ok',36],
				        	  [ '','','', '','Ark',37],
						 ],
				       tag => 'detail2',
				       },
	       			2 => { data => [ [ '','','', '','Texas',41],
				        	  [ '','','', '','Ok',42],
				        	  [ '','','', '','Ark',43],
						 ],
				       tag => 'detail2',
				       },
	       			3 => { data => [ [ '','','', '','Texas',51],
				        	  [ '','','', '','Ok',52],
				        	  [ '','','', '','Ark',53],
						 ],
				       tag => 'detail2',
				       },
			      },
	       },
	       
	2 => { data => [ [ '','','Apr', 'South','--',55],
	        	 [ '','','May', 'South','--',61],
	        	 [ '','','Jun', 'South','--',68],
	        	 ],
	       tag => 'detail',
	       spans => [ 1 => '0,1'],
	       expandData => {
	       			2 => { data => [ [ '','','', '','Texas',58],
				        	  [ '','','', '','Ok',65],
				        	  [ '','','', '','Ark',60],
						 ],
				       tag => 'detail2',
				       }
			      }
	       },
	 4 => { data => [['','Sorry, Detail Data Not Available Until Next month']],
	 	tag => 'detail',
		spans => [ 1 => '0,3']
		},
	       
	};

my $t = $top->Scrolled('SpreadsheetHideRows', -rows => 5, -cols => 6, 
                              -width => 6, -height => 6,
			      -titlerows => 1, -titlecols => 1,
			      -variable => $arrayVar,
			      -selectmode => 'extended',
			      -resizeborders => 'both',
			      -selectorCol => 0,
			      -expandData => $expandData
			     #  -state => 'disabled'
			    #  -colseparator => "\t",
			    #  -rowseparator => "\n"
                    );

# Tags for the detail data:
$t->tagConfigure('detail', -bg => 'palegreen', -relief => 'sunken');
$t->tagConfigure('detail2', -bg => 'lightskyblue1', -relief => 'sunken');



$t->pack(-expand => 1, -fill => 'both');

$top->after(1000,sub{$top->destroy}) unless(@ARGV); # auto-quit unless commands supplied (for debugging)

ok(1, 1, "SpreadsheetHideRows Widget Creation");

MainLoop;
