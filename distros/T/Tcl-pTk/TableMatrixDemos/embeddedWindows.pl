##########
### Demo of using embedded windows in TableMatrix

###  This works well, but can be slow for very large tables with many
###   windows.
###
###  See edit_styles.pl for an alternative that is faster for larger
###    tables

use Tcl::pTk qw/:perlTk/;
use Tcl::pTk::TableMatrix;

use Tcl::pTk::BrowseEntry;

use Data::Dumper qw( DumperX);
my $top = MainWindow->new;

my $arrayVar = {};

foreach my $row  (0..20){
	foreach my $col (0..10){
		$arrayVar->{"$row,$col"} = "r$row, c$col";
	}
}



my $t = $top->Scrolled('TableMatrix', -rows => 21, -cols => 11, 
                              -width => 6, -height => 6,
			      -titlerows => 1, -titlecols => 1,
			      -variable => $arrayVar,
			      -selectmode => 'extended',
			      -resizeborders => 'both',
			      -titlerows => 1,
			      -titlecols => 1,
			      -bg => 'white',
			     #  -state => 'disabled'
			    #  -colseparator => "\t",
			    #  -rowseparator => "\n"
                    );
		    
$t->tagConfigure('active', -bg => 'gray90', -relief => 'sunken');
$t->tagConfigure( 'title', -bg => 'gray85', -fg => 'black', -relief => 'sunken');

################ Put in some embedded windows ################
my $l = $top->Checkbutton(-text => 'CheckButton');
$t->windowConfigure("3,3", -sticky => 's', -window => $l);


my $c = $top->BrowseEntry(-label => "Month:");
$c->insert("end", "January");
$c->insert("end", "February");
$c->insert("end", "March");
$c->insert("end", "April");
$c->insert("end", "May");
$c->insert("end", "June");
$c->insert("end", "July");
$c->insert("end", "August");
$c->insert("end", "September");
$c->insert("end", "October");
$c->insert("end", "November");
$c->insert("end", "December");


$t->windowConfigure("2,2", -sticky => 'ne', -window => $c);

# Leave enough room for the windows
$t->colWidth(2,20);
$t->colWidth(3,20);

$t->pack(-expand => 1, -fill => 'both');

MainLoop;
