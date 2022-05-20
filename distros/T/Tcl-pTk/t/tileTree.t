# Demo of tile widget

use warnings;
use strict;

use Tcl::pTk;

use Test::More;
use Test::Deep;


my $TOP = MainWindow->new;

# This will skip if Tile widgets not available
unless ($Tcl::pTk::_Tile_available) {
    $TOP->destroy;
    plan skip_all => 'Tile unavailable';
}

plan tests => 8;

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


my $style = $tree->cget(-style);
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

my @IDs;
while(@data){
        my $country  = shift @data;
        my $capital  = shift @data;
        my $currency = shift @data;
        
        push @IDs, $tree->insert('', 'end', -values => [$country, $capital, $currency]);
        
        # Auto-set length of field based on data init
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

# New tests added in response to
# https://github.com/chrstphrchvz/perl-tcl-ptk/issues/7

is(scalar(@IDs), 15, 'Obtain IDs for each inserted item');

# Test bbox command
# make sure last item is invisible
$tree->see($IDs[0]);
$TOP->update;
is($tree->bbox($IDs[14]), undef,
    '`bbox` command should return undef for invisible item');
# now make sure last item is visible
$tree->see($IDs[14]);
$TOP->update;
my $tree_bbox = [$tree->bbox($IDs[14])];
is(scalar(@$tree_bbox), 4,
    '`bbox` command should return list for visible item');

# Test selection command
my $set_selected_IDs = [$IDs[10], @IDs[13..14]];
$tree->selection('set', $set_selected_IDs);
my $get_selected_IDs = [$tree->selection()];
is_deeply($get_selected_IDs, $set_selected_IDs,
    '`selection` command should return selected items as Perl list (not Tcl list)');

# Test item -values command
my $get_values = [$tree->item($IDs[14], '-values')];
is_deeply($get_values, ['United States', 'Washington, D.C.', 'USD'],
    '`item -values` command should return values of item as Perl list (not Tcl list)');

# Test tag command
SKIP: {
    skip '`tag add` and `tag has` require Tcl/Tk 8.5.9 or later, '
       . 'or Tile 0.8.4.0 for Tcl/Tk 8.4',
        1 unless $Tcl::pTk::_Tile_ge_0840;
    my $set_tagged_IDs = [@IDs[5..6], $IDs[8], $IDs[11]];
    $tree->tag('add', 'Europe', $set_tagged_IDs);
    my $get_tagged_IDs = [$tree->tag('has', 'Europe')];
    is_deeply($get_tagged_IDs, $set_tagged_IDs,
        '`tag has` command should return tagged items as Perl list (not Tcl list)');
}

# Test cellselection command
SKIP: {
    skip '`cellselection` requires Tcl/Tk 8.7 or later',
        2 if $TOP->interp->Eval(sprintf('catch {%s cellselection}',
                $tree->Subwidget('scrolled')->PathName));

    # set using selection list
    my $set_selected_cells = [
        [$IDs[10], 'country'],
        [$IDs[12], 'capital'],
        [$IDs[14], 'currency'],
    ];
    $tree->cellselection('set', $set_selected_cells);
    my $get_selected_cells = [$tree->cellselection()];
    cmp_deeply($get_selected_cells, noclass($set_selected_cells),
        '`cellselection` command should return selected items as Perl list (not Tcl list)'
      . ' (set using selection list)');

    # set using rectangular selection
    $set_selected_cells = [
        [$IDs[11], 'capital'],
        [$IDs[11], 'currency'],
        [$IDs[12], 'capital'],
        [$IDs[12], 'currency'],
    ];
    $tree->cellselection('set', [$IDs[11], 'capital'], [$IDs[12], 'currency']);
    $get_selected_cells = [$tree->cellselection()];
    cmp_deeply($get_selected_cells, noclass($set_selected_cells),
        '`cellselection` command should return selected items as Perl list (not Tcl list)'
      . ' (set using rectangular selection)');
}

$TOP->idletasks;
(@ARGV) ? MainLoop : $TOP->destroy; # Persist if any args supplied, for debugging

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
        

