## version2.tcl
##
## This demo uses most features of the table widget
##
## jeff.hobbs@acm.org
##  Converted to perl/tk by John Cerney


use Tcl::pTk;
use Tcl::pTk::TableMatrix;
use Test;


my ($rows,$cols) = (25,20); # number of rows/cols
my $top = MainWindow->new;

# This will skip if Tktable not present
my $retVal = $top->interp->pkg_require('Tktable');

unless( $retVal){
	plan tests => 1;
        skip("Tktable Tcl package not available", 1);
        exit;
}

plan test => 2;


# Sub to fill the array variable
sub fill{

	my ($array,$x,$y) = @_;
	my ($i,$j);
	for( $i = -$x; $i<$x; $i++){
		for( $j = -$y; $j<$y; $j++){
			$array->{"$i,$j"} = "r$i,c$j";
		}
	}
}



## Test out the use of a callback to define tags on rows and columns
sub colSub{
	my $col = shift;
	return "OddCol" if( $col > 0 && $col%2) ;
}


my $label = $top->Label(-text => "TableMatrix v2 Example");


my $arrayVar = {};

fill($arrayVar, $rows,$cols); # fill up the array variable


my $t = $top->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
			      -variable => $arrayVar,
                              -width => 6, -height => 8,
			      -titlerows => 1, -titlecols => 2,
			      -roworigin =>  -5,  -colorigin  => -2, 
			      -coltagcommand => \&colSub,
			      -selectmode => 'extended',
			      -selecttitles => 0,
			      -drawmode => 'single',

                    );

# Check tk classname of the widget
my $actualWidget = $t->Subwidget('scrolled');
my $class = $actualWidget->class();
#print "class = $class\n";
ok($class, 'TableMatrix', "Tk Class check");


my $button = $top->Button( -text => "Exit", -command => sub{ $top->destroy});		    
$label->pack( -expand => 1, -fill => 'both');

$t->pack(-expand => 1, -fill => 'both');
$button->pack(-expand => 1, -fill => 'both');



# hideous Color definitions here:
$t->tagConfigure('OddCol', -bg => 'brown', -fg => 'pink');
$t->tagConfigure('title', -bg => 'red', -fg => 'blue', -relief => 'sunken');
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

# $initWindow->Label(-image => $top->Photo(-file => Tk->findINC('Xcamel.gif')))->pack;


my $perltkLogo = $top->Photo(-file => Tcl::pTk->findINC('Xcamel.gif'));

$t->tagConfigure('logo', -image =>  $perltkLogo, -showtext => 1);
$t->tagCell('logo', '1,2', '2,3', '4,1');
$t->tagCell('dis', '2,1', '1,-1', '3,0');
$t->colWidth(qw/ -2 8 -1 9 0 12 4 14/);


$t->set( '1,1' => "multi-line\ntext\nmight be\ninteresting" ,
	'3,2' => "more\nmulti-line\nplaying\n" ,
	'2,2' => "null\0byte" );


$i = -1;

# This is in the row span
my $l = $top->Label(-text => "Window s", -bg => 'yellow');
$t->windowConfigure("6,0", -sticky => 's', -window => $l);

# This is in the row titles
$l = $top->Label(-text => "Window ne", -bg => 'yellow');
$t->windowConfigure("4,-1", -sticky => 'ne', -window => $l);

# This will get swallowed by a span
$l = $top->Label(-text => "Window ew", -bg => 'yellow');
$t->windowConfigure("5,3", -sticky => 'ew', -window => $l);


# This is in the col titles
$l = $top->Label(-text => "Window nsew", -bg => 'yellow');
$t->windowConfigure("-5,1", -sticky => 'nsew', -window => $l);

$l = $t->parent->Label(-text => "Sibling l", -bg => 'orange');
$t->windowConfigure("5,1", -sticky => 'nsew', -window => $l);

$t->spans( '-1,-2' => '0,3',  '1,2' =>  '0,5','3,2' => '2,2',  '6,0' => '4,0');

$top->after(1000, sub{ $top->destroy;}) unless(@ARGV); # If args supplied (debug mode), don't quit after 1 second

MainLoop;

ok(1,1,"TableMatrix Debug Demo");

