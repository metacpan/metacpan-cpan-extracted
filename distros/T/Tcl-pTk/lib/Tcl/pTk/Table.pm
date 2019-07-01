#
# This is a reimplementation of the perl/tk Tk::Table widget using the Tablematrix widget
#   The original perl/tk approach can't be used for Tcl::pTk, because it uses the ManageGeometry methods,
#    which aren't supported in Tcl::pTk
#

package Tcl::pTk::Table;

our ($VERSION) = ('1.02');

use strict;

use Tcl::pTk::TableMatrix;

use base qw(Tcl::pTk::Derived Tcl::pTk::Frame);

Construct Tcl::pTk::Widget 'Table';


sub Populate
{
 my ($t,$args) = @_;
 $t->SUPER::Populate($args);
 
 my $scrollbars = delete $args->{-scrollbars};
 my $tableMatrix;
 
 # create tableMatrix with scrollbars, if -scrollbars option present
 if( $scrollbars ){
         $tableMatrix = $t->Scrolled('TableMatrix', -scrollbars => $scrollbars, -rows => 1, -cols => 1, 
                 -titlerows => 0, -titlecols => 0, -roworigin => 1, -colorigin => 1);
 }
 else{
         $tableMatrix = $t->TableMatrix(-rows => 1, -cols => 1, -titlerows => 0, -titlecols => 0, -roworigin => 1, -colorigin => 1);
 }

 # Initialize widget storage
 $t->{widgets} = {}; # Mapping of row/col index to widget
 $t->{Width}   = []; # Mapping of col number to col width
 $t->{Height}  = []; # Mapping of row number to row height
 
 $tableMatrix->pack(-expand => 1, -fill => 'both');
 
 $t->Advertise('TableMatrix', $tableMatrix);
         
 $t->ConfigSpecs('-scrollbars'         => [PASSIVE   => 'scrollbars','Scrollbars','nw'],
                 
                 # TakeFocus doesn't do anything, just present for Tk::Table Compatibility
                 '-takefocus'          => [PASSIVE => 'takeFocus','TakeFocus',1],  
                 '-rows'               => [PASSIVE => 'rows','Rows',10],
                 '-columns'            => [PASSIVE => 'columns','Columns',10],
                 '-fixedcolumns'       => [{-titlecols => $tableMatrix}  => 'fixedcolumns', 'fixedcolumns', 0], # fixedcolumns mapped to tablematrix -titlecols
                 '-fixedrows'          => [{-titlerows => $tableMatrix}  => 'fixedrows',    'fixedrows',    0], # fixedrows mapped to tablematrix -titlerows
                 DEFAULT               => [$tableMatrix]
                 );


}



sub get
{
 my ($t,$row,$col) = @_;
 return $t->{widgets}{"$row,$col"};

}


sub clear {
    my $self = shift;
    
    my $tm = $self->Subwidget('TableMatrix'); # Work with the tablematrix
    
    # Get our widget store
    my $widgets =  $self->{widgets};

    # Delete all widgets
    $tm->windowDelete(keys %$widgets);
    $tm->configure(-rows => 1, -cols => 1);
    %$widgets = ();
}


sub put
{
 my ($t,$row,$col,$w) = @_;
 
 my $tm = $t->Subwidget('TableMatrix'); # Work with the tablematrix
 my $minrow = $tm->cget(-roworigin);
 my $maxrow = $minrow + $tm->cget(-rows)-1;
 my $mincol = $tm->cget(-colorigin);
 my $maxcol = $tm->cget(-cols)-1;
 
 # Text entries get turned into Label widgets
 $w = $t->Label(-text => $w) unless (ref $w);
 
 if ( $row > $maxrow )
  {
   $t->{Height}[$row] = 0;
   $maxrow = $row;
  }
 elsif( $row < $minrow )
  {
   $t->{Height}[$row] = 0;
   $minrow = $row;
  }
 if ($col > $maxcol )
  {
   $t->{Width}[$col] = 0;
   $maxcol = $col;
  }
 elsif( $col < $mincol)
  {
   $t->{Width}[$col] = 0;
   $mincol = $col;
  }
  
 # Put the widget in our widget store
 my $index = "$row,$col"; 
 my $old = $t->{widgets}{$index};
 $t->{widgets}{$index} = $w;
 
 # Update the tables row/col size
 $tm->configure(-rows => ($maxrow-$minrow)+1, -cols => $maxcol-$mincol+1, -roworigin => $minrow, -colorigin => $mincol);
 
 # Store it in the tablematrix as an embedded window
 $tm->windowConfigure($index, -window => $w);
 $w->idletasks if( ref($w) =~ /frame/i); # tablematrix won't show embedded widgets in a frame, unless an update has been called 
 
 # Update col widths and heights for the supplied row/col 
 $t->_updateColWidth($col);
 $t->_updateRowHeight($row);

 return $old;
}


# Internal method to update the col width, based on the requested width of the embedded widgets
sub _updateColWidth {
    my $self = shift;
    my $col  = shift;
      
    my $tm = $self->Subwidget('TableMatrix'); # Work with the tablematrix
    my $minrow = $tm->cget(-roworigin);
    my $maxrow = $minrow + $tm->cget(-rows)-1;
    
    # Get our widget store
    my $widgets =  $self->{widgets};

    # Go thru all rows in the col
    my $newWidth = 0;
    my @indexes = map "$_,$col", ($minrow..$maxrow);
    foreach my $index(@indexes){
            my $w = $widgets->{$index};
            if( defined $w){
                    my $wid = $w->reqwidth();
                    $newWidth = $wid if ($wid > $newWidth);
            }
    }
    
    # Set new col width (negative number to specify in pixels)
    $tm->colWidth($col, -$newWidth);
    
}

# Internal method to update the row height, based on the requested width of the embedded widgets
sub _updateRowHeight {
    my $self = shift;
    my $row  = shift;
      
    my $tm = $self->Subwidget('TableMatrix'); # Work with the tablematrix
    my $mincol = $tm->cget(-colorigin);
    my $maxcol = $mincol + $tm->cget(-cols)-1;
    
    # Get our widget store
    my $widgets =  $self->{widgets};

    # Go thru all cols in the row
    my $newHeight = 0;
    my @indexes = map "$row,$_", ($mincol..$maxcol);
    foreach my $index(@indexes){
            my $w = $widgets->{$index};
            if( defined $w){
                    my $h = $w->reqheight();
                    $newHeight = $h if ($h > $newHeight);
            }
    }
    
    # Set row height (negative number to specify in pixels)
    $tm->rowHeight($row, -$newHeight);
    
}

# Short-cut method to create and put a widget
sub Create
{
 my $t = shift;
 my $r = shift;
 my $c = shift;
 my $kind = shift;
 $t->put($r,$c,$t->$kind(@_));
}

#
# configure methods
#


sub totalColumns
{
    my $self = shift;
      
    my $tm = $self->Subwidget('TableMatrix'); # Work with the tablematrix
    return $tm->cget(-cols);
}

sub totalRows
{
    my $self = shift;
      
    my $tm = $self->Subwidget('TableMatrix'); # Work with the tablematrix
    return $tm->cget(-rows);
}


# Return the row/col position of a given widget
sub Posn
{
 my ($t,$s) = @_;

 # Get our widget store
 my $widgets =  $t->{widgets};
 
 # Make reverse lookup;
 my %reverseWidgets = reverse %$widgets;
 
 my $index = $reverseWidgets{$s};
 return () unless defined $index;
 
 return split(",", $index);
}



