# Demo of tile widget

use Tcl::pTk;

use Test;

plan test => 1;


my $TOP = MainWindow->new;


my $version = $TOP->tclVersion;
# print "version = $version\n";

# Skip if Tcl/pTk version is < 8.5
if( $version < 8.5 ){
        skip("Tile widgets only works for Tcl >= 8.5", 1);
        exit;
}


my $msg = $TOP->ttkLabel( -text => 
        "Ttk is the new Tk themed widget set. One of the widgets it includes is a tree widget, which can be configured to display multiple columns of informational data without displaying the tree itself. This is a simple way to build a listbox that has multiple columns. Clicking on the heading for a column will sort the data by that column. You can also change the width of the columns by dragging the boundary between them.",
        qw/ -wraplength 4i -justify left/)->pack(-side => 'top', -fill => 'x');
 
        
# Make the button frame
my $bigFrame = $TOP->ttkFrame()->pack(-expand => 'y', -fill => 'both');

my $tree = $bigFrame->Scrolled('ttkTreeview',-columns => [qw/ country capital currency/], -show => 'headings',       -scrollbars => 'se' )->pack(-fill => 'both', -expand => 1);
#my $tree = $bigFrame->ttkTreeview(-columns => [qw/ country capital currency/], -show => 'headings')->pack(-fill => 'both', -expand => 1);

my @data = (        
    'Argentina',	'Buenos Aires',		'ARS',
    'Australia',	'Canberra',		'AUD',
    'Brazil',		'Brazilia',		'BRL',
    'Canada',		'Ottawa',		'CAD',
    'China',		'Beijing',		'CNY',
    'France',		'Paris',		'EUR',
    'Germany',		'Berlin',		'EUR',
    'India',		'New Delhi',		'INR',
    'Italy',		'Rome',			'EUR',
    'Japan',		'Tokyo',		'JPY',
    'Mexico',		'Mexico City',		'MXN',
    'Russia',		'Moscow',		'RUB',
    'South Africa',	'Pretoria',		'ZAR',
    'United Kingdom',	'London',		'GBP',
    'United States',	'Washington, D.C.',	'USD',
    );


$style = $tree->cget(-style);
my $font = $tree->ttkStyleLookup( $style, -font);

## Code to insert the data nicely
foreach my $col (qw/ country capital currency /){
        my $name = ucfirst($col);
        # Set heading name and sort fommand, using the real (not scrolled) tree widget
        $tree->heading($col, -command => [\&SortBy, $tree->Subwidget('scrolled'), $col, 0], -text => $name );
        
        my $len = $tree->fontMeasure($font, $name);
        #print "Setting $col width to $len\n";
        $tree->column($col, -width, $len+10);
}


while(@data){
        my $country  = shift @data;
        my $capital  = shift @data;
        my $currency = shift @data;
        
        $tree->insert('', 'end', -values => [$country, $capital, $currency]);
        
        # Auto-set length of field basd on data init
        my %rowLookup; # Hash for quick lookup
        @rowLookup{qw/ country capital currency /} = ($country, $capital, $currency);
        foreach my $col (qw/ country capital currency /){
             
                my $len = $tree->fontMeasure($font, $rowLookup{$col}."  ");
                if( $tree->column($col, -width) < $len ){
                        #print "setting $col width to $len\n";
                        $tree->column($col, -width => $len);
                }
        }
                     
}

$TOP->after(1000, sub{ $TOP->destroy }) unless (@ARGV); # Persist if any args supplied, for debugging


 MainLoop;
 
ok(1);
 
## Code to do the sorting of the tree contents when clicked on
sub SortBy{
        my ($tree, $col, $direction) = @_;
       
        #print "tree is a ".ref($tree)."\n";
        
        # Build something we can sort
        my @data;
        my @rows = $tree->children('');
        foreach my $row( @rows){
                push @data, [$tree->set($row, $col), $row];
        }
        my @indexes = (0..$#rows);
        
        my @sortedIndexes;
        if( $direction ){ # forward sort
                my @sorted = sort{ $a->[0] cmp $b->[0] } @data;
                @sortedIndexes = map $_->[1], @sorted;
        }
        else{
                my @sorted = sort{ $b->[0] cmp $a->[0] } @data;
                @sortedIndexes = map $_->[1], @sorted;
        }
    
        # Now reshuffle the rows into the sorted order
        my $r = 0;
        foreach my $index(@sortedIndexes){
                $tree->move($index, '', $r);
                $r++;
        }
        
        # Switch the heading so that it will sort in the opposite direction
        $tree->heading($col, -command => [\&SortBy, $tree, $col, !$direction]);
}
        

