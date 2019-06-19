package Tcl::pTk::TableMatrix::Spreadsheet;

our ($VERSION) = ('1.00');

=head1 NAME

Tcl::pTk::TableMatrix::Spreadsheet - Table Display with Spreadsheet-like bindings.

=head1 SYNOPSIS

  use Tcl::pTk;
  use Tcl::pTk::TableMatrix::Spreadsheet;



  my $t = $top->Scrolled('Spreadsheet', -rows => 21, -cols => 11, 
                              -width => 6, -height => 6,
			      -titlerows => 1, -titlecols => 1,
			      -variable => $arrayVar,
			      -selectmode => 'extended',
			      -titlerows => 1,
			      -titlecols => 1,
			      -bg => 'white',
                    );

=head1 DESCRIPTION

L<Tcl::pTk::TableMatrix::Spreadsheet> is a L<Tcl::pTk::TableMatrix>-derived widget that implements
some bindings so the resulting widget behaves more like a spreadsheet.

B<Bindings Added:>

=over 1

=item *

Row/Col resize handles appear when the cursor is placed
over a row/col border line in the rol/col title area. 

Dragging these handles will resize the row or column. If multiple rows or columns
are selected, then the new row/col size will apply to all row/cols selected.

Note: With the base Tk::TableMatrix, it is possible to resize the row/cols by dragging
on any cell border. To be more spreadsheet-like, Tk::TableMatrix::Spreadsheet  defaults to enable row/col
resizing only thru the title row/col dragging. To override this default behavoir, set the -resizeborder option to
'both' at startup.

=item *

A popup menu for row/col insert/delete appears when the mouse is right-clicked in the
row/col title areas. 

=item *

Cells activate (i.e. the contents become edit-able) only when the cell is double-clicked
or the F2 button is pressed. The default L<Tcl::pTk::TableMatrix> behavior is for the
cell to be activated when the cell is single-clicked.

=item *

The Escape key causes any changes made to a cell to be canceled and the current
selection cleared.

=item *

The return key causes the the current cell to move down.

=item *

The tab (or shift tab) key causes the current cell to be moved to the right (left).

=item *

The delete key will delete the current selection, if no cell is currently active.

=item *

The Mouse button 2 (middle button) paste from the PRIMARY. (Control-v pastes from the
clipboard).

=back

=head1 Additional Information

Widget methods, options, etc, are inherited from the L<Tcl::pTk::TableMatrix> widget. See its 
docs for additional information.

=cut




use Carp;


use Tcl::pTk (qw/ Ev /);
use Tcl::pTk::TableMatrix;
use Tcl::pTk::Derived;

use base qw/ Tcl::pTk::Derived Tcl::pTk::TableMatrix/;


Tcl::pTk::Widget->Construct("Spreadsheet");


sub ClassInit{
	my ($class,$mw) = @_;

	$class->SUPER::ClassInit($mw);
        
	
	#  Bind our motion routine to change cursors for row/column resize
	$mw->bind($class,'<Motion>',['GeneralMotion',$mw, Ev('x'), Ev('y')]);

	# Over-ride default button release binding
	#  so a cell won't activate by just clicking
	$mw->bind($class,'<ButtonRelease-1>',['Button1Release', $mw]);

	# Edit (activate) a cell if it is double-clicked
	#   Or F2 is pressed
	$mw->bind($class,'<Double-1>',
		[sub
		 {
		  my $w = shift;
                  my ($x,$y) = @_;
		  if ($w->Exists)
		   {
		    $w->CancelRepeat;
		    $w->activate('@' . $x.",".$y);
		   }
		 }, Ev('x'), Ev('y')
                 ]
	);
	$mw->bind($class,'<F2>',
		[sub
		 {
		  my $w = shift;
                  my ($x,$y) = @_;
		  if ($w->Exists)
		   {
		    $w->CancelRepeat;
                    # Get the current selected cell, if one exists
                    my $location = eval { $w->index('anchor'); }; 
                   
		    # print "location = $location\n";
                    return unless($location);

                    $w->activate($location);
		   }
		 }, Ev('x'), Ev('y')
                 ]
	);




	$mw->bind($class,'<Escape>',
		sub
		 {
		  my $w = shift;
		  $w->reread; # undo any changes if editing a cell
    		  my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);
		  $w->activate($upperLeft);
		  $w->selectionClear('all');
		  
		 }
	);


	# Make the return key enter and move down
	$mw->bind($class,'<Return>',['MoveCell',1,0]);
	$mw->bind($class,'<KP_Enter>',['MoveCell',1,0]);
	
	# Make the tab key enter and move right
 	$mw->bind($class,'<Tab>',
			sub{ 
				my $w = shift;
				$w->MoveCell(0,1);
				Tcl::pTk->break;
			}
	);
 	$mw->bind($class,'<Shift-KP_Tab>',['MoveCell',0,-1]);

        # Make the delete key delete the selection, if no active cell
 	$mw->bind($class,'<Delete>',
		sub{
			my $self = shift;
			my $active;
			# Get the current active cell, if one exists
			eval { $active = $self->index('active'); }; 

			$active = '' if( $@); # No Active cell found;

			# No Active cell if it is set to the upper left column (esc key pressed)
    			my $upperLeft = $self->cget(-roworigin).",".$self->cget(-colorigin);

			$active = '' if( $active eq $upperLeft); # No Active cell found;
			
			if( $active eq ''){  # No Active Cell, delete the selection
				   eval
				    {
				     $self->curselection(undef);# Clear whatever is selected
				     $self->selectionClear();
				     }
			}
			else{  # There is a current active cell, perform delete in that
				$self->deleteActive('insert');
			}
		}
		
	);
	
	# middle mouse button release pastes from PRIMARY (control v pastes from clipboard)
	 $mw->bind(
		  $class,
	 	  $mw->windowingsystem ne 'aqua' ? '<ButtonRelease-2>' : '<ButtonRelease-3>',
		  [sub
		   {
		    my $w = shift;
		    my ($x, $y) = @_;
		    $w->Paste($w->index('@' . $x.",".$y),'PRIMARY') unless ($Tcl::pTk::TableMatrix::tkPriv{'mouseMoved'});
		   }, Ev('x'), Ev('y')
                   ]
		 );


          # Make Left-Right arrow keys move cells around (like the parent class), but
          #  if we are editing a cell, make the edit-cursor move around
          $mw->bind($class,'<Left>',
                   sub
                   {
                    my $w = shift;
	
                    # Check for an active cell (i.e. we are currently editing)
                    my $active = eval { $w->index('active'); }; 
                    if( $active && $active ne '0,0' ){
                            my $posn = $w->icursor;
                            $w->icursor($posn - 1);
                    }
                    else{
                            # Not editing a cell, just move the selected cell around
                            $w->MoveCell(0,-1); 
                    }
                   }
           );

          $mw->bind($class,'<Right>',
                   sub
                   {
                    my $w = shift;
	
                    # Check for an active cell (i.e. we are currently editing)
                    my $active = eval { $w->index('active'); }; 
                    if( $active  && $active ne '0,0' ){
                            my $posn = $w->icursor;
                            $w->icursor($posn + 1);
                    }
                    else{
                            # Not editing a cell, just move the selected cell around
                            $w->MoveCell(0,1); 
                    }
                   }
           );
          

};


sub Populate {
    my ($cw, $args) = @_;
    
    # Set Default Args:
    $args->{-bg} = 'white' unless defined( $args->{-bg});
    
    $args->{-colstretchmode} = 'unset' unless defined( $args->{-colstretchmode});

    # Default behavior is to not allow cell resizing, just at the row/col titles (like Excel)
    $args->{-resizeborders}  = 'none' unless defined( $args->{-resizeborders});
    
    
    $cw->SUPER::Populate($args);
    
    # default Tags
    $cw->tagConfigure('active', -bg => 'gray90', -relief => 'sunken', -fg => 'black');
    $cw->tagConfigure( 'title', -bg => 'gray85', -fg => 'black', -relief => 'sunken');
   
   
    # setup Popup Menu (right mouse-button press) for common operations
    my $popup = $cw->Menu('-tearoff' => 0);
    $popup->command('-label' => 'Insert',  '-command' => ['insertRowCol',$cw] );
    $popup->command('-label' => 'Delete',  '-command' => ['deleteRowCol',$cw] );
    #$popup->command('-label' => 'Clear Contents', '-command' => ['curselection', $cw,''] );
    #$popup->command('-label' => 'Clear Contents', '-command' => sub{ $cw->interp->invoke($cw, 'curselection', '')});
    $popup->command('-label' => 'Clear Contents', '-command' => 
            sub{$cw->interp->Eval("set empty {}");
                $cw->interp->Eval("$cw curselection  \$empty")});
 
 
 
 
    # Bind a sub for right mouse button press
    $cw->bind(
	$cw->windowingsystem ne 'aqua' ? '<ButtonPress-3>' : '<ButtonPress-2>', 

	[ sub {
	
                my $cw = shift;
                my ($x, $y) = @_;

		# Don't Do anything if we are on a cell border
		#  This keeps the right-click menu from pop-ing up
		#  when starting a cell re-size
		my @border = $cw->border('mark',$x,$y);
		#print "border = '".join("', '",@border)."', state = ".$cw->cget(-state)." border size = ".scalar(@border)."\n";
                
                
		# return if on a border or if not in edit mode
	        return if( scalar(@border) || ( $cw->cget(-state) =~ /disabled/i ));
		

		my $inTitleArea = 0;  # Flag = 1 if we are in a title Area
		my $inSelectedArea = 0; # Flag = 1 if we are in a selected area
			
		my $pointerLoc = $cw->index('@'."$x,$y");
		$cw->{pointerLoc} = $pointerLoc; # Save pointer location for the insert/delete row routines
					         # After the local menu pops up and a item is selected, the pointer
						 #  location won't be valid anymore
		
		#print "Pointer over = '$pointerLoc'\n";
		
		if( $cw->tagIncludes('title',$pointerLoc) && $pointerLoc ne '0,0' ){
			# print "Pointer over a title area\n";
			$inTitleArea = 1;
			
		}
		if( $cw->selectionIncludes($pointerLoc)){
			$inSelectedArea = 1;
			# print "In Selected Area\n";
		}

		if( $inTitleArea && !$inSelectedArea){ # select the row/col if
						       # in title area and not selected
			$cw->BeginSelect($pointerLoc);
		}
			
		if( $inTitleArea ){
			$popup->Popup('-popover' => 'cursor', '-popanchor' => 'nw');
		}
		
	}, Ev('x'), Ev('y')
        ]
     );

    
}

# Sub to insert row/cols
sub insertRowCol{

	my $cw = shift;

	my $pointerLoc = $cw->{pointerLoc}; # use the pointer locatin from before the popup window came up
	my ($r,$c) = split(",",$pointerLoc);
	#print "pointerLoc = $r, $c\n";
	
	if( $r <= 0){ # Insert Col
		my %cols;
		@cols{map /(\d+)$/, $cw->tagCell('sel')} = 1;
		my @cols = sort {$a <=> $b} keys %cols;
		
		my $minCol = $cols[0];
		my $colCount = $cols[-1] - $minCol + 1;
		$cw->insertCols($minCol,-$colCount);
		
		# Make selection and clear
		my $lastRow = $cw->index('end','row');
		$cw->selectionSet("0,$minCol","$lastRow,".$cols[-1]);
		$cw->curselection('');		
	}
	elsif( $c <= 0 ){
		my %rows;
		@rows{map /^(\d+)/, $cw->tagCell('sel')} = 1;
		my @rows = sort {$a <=> $b} keys %rows;
		
		my $minRow = $rows[0];
		my $rowCount = $rows[-1] - $minRow + 1;
		$cw->insertRows($minRow,-$rowCount);
		
		# Make selection and clear
		my $lastCol = $cw->index('end','col');
		$cw->selectionSet("$minRow,0",$rows[-1].",$lastCol");
		$cw->curselection('');		
		
	}
	
}

# Sub to delete row/cols
sub deleteRowCol{

	my $cw = shift;

	my $pointerLoc = $cw->{pointerLoc}; # use the pointer locatin from before the popup window came up
	my ($r,$c) = split(",",$pointerLoc);
	#print "pointerLoc = $r, $c\n";
	
	if( $r <= 0){ # Delete Col
		my %cols;
		@cols{map /(\d+)$/, $cw->tagCell('sel')} = 1;
		my @cols = sort {$a <=> $b} keys %cols;
		
		my $minCol = $cols[0];
		my $colCount = $cols[-1] - $minCol + 1;
		$cw->deleteCols($minCol,$colCount);
		
		# Make selection
		my $lastRow = $cw->index('end','row');
		$cw->selectionSet("0,$minCol","$lastRow,".$cols[-1]);
	}
	elsif( $c <= 0 ){
		my %rows;
		@rows{map /^(\d+)/, $cw->tagCell('sel')} = 1;
		my @rows = sort {$a <=> $b} keys %rows;
		
		my $minRow = $rows[0];
		my $rowCount = $rows[-1] - $minRow + 1;
		$cw->deleteRows($minRow,$rowCount);
		
		# Make selection
		my $lastCol = $cw->index('end','col');
		$cw->selectionSet("$minRow,0",$rows[-1].",$lastCol");
		
	}
	
}

# General Motion routine. Sets the border cursor to <-> if on a row border.
#  or vertical resize cursor if on a col border

sub GeneralMotion{

	my $self  = shift;
        my $mw    = shift;
        my ($x, $y) = @_;
        
	my $rc = $self->index('@' . $x.",".$y);
	return unless($rc);
	
	my ($row,$col) = split(',',$rc);
	my $rowColResize = $self->{rowColResize};  # Flag = 1 if cursor has been changed for a row/col resize
	my $rowColResizeOldCursor = $self->{rowColResizeOldCursor};          #  name of old cursor that was changed;
	my $rowColResizeOldBDCursor = $self->{rowColResizeBDOldCursor};          #  name of old BD cursor that was changed;
	
	my @border = $self->borderMark($x,$y);
	if( scalar(@border) ){  # we are on a border
		my ($r,$c) = @border;
		
		# print "In motion $r, $c: $row, $col\n";
		
		# my $currentBDCursor = $self->cget(-bordercursor);

		if( ($col <= 0) && ($r =~ /\d/)  ){
			# print "Row Border = $r\n";
			# print "Setting Row Border \n";
			unless($rowColResize){
				$self->{rowColResizeOldCursor} = $self->cget(-cursor);
				$self->{rowColResizeBDOldCursor} = $self->cget(-bordercursor);
				$self->configure(-cursor => 'sb_v_double_arrow',
					-bordercursor => 'sb_v_double_arrow');
				$self->{rowColResize} = 1;
				$self->{rowColResizeRow} = $r;
				$self->{rowColResizeCol} = undef;
			}
			
		}
		elsif( ($row <= 0) && ($c =~ /\d/) ){
			# print "Col Border = $c\n";
			unless($rowColResize){
				$self->{rowColResizeOldCursor} = $self->cget(-cursor);
				$self->{rowColResizeBDOldCursor} = $self->cget(-bordercursor);
				$self->configure(-cursor => 'sb_h_double_arrow',
					-bordercursor => 'sb_h_double_arrow');
				$self->{rowColResize} = 1;
				$self->{rowColResizeRow} = undef;
				$self->{rowColResizeCol} = $c;
			}

		}
		
	}
	else{
		if( $rowColResize && !($self->{rowColResizeDrag}) ){  # Change cursor back if it has been changed, and
									# we aren't currently doing a row/col resize drag.
			#print "Setting to $oldCursor\n";
			$self->configure(-cursor => $rowColResizeOldCursor,
				-bordercursor => $rowColResizeOldBDCursor);
			$self->{rowColResize} = 0;
		}

	}
			
		
}

######################################################################3
## Over-ridden beginselect. Sets the rowColResizeDrag to indicate
## that we are doing a row or column resize operation
sub borderDragto{
	my $self = shift;
	my @args = @_;
	
       if( !$self->{rowColResizeDrag}){
	       #print "StartDrag\n";
	       $self->{oldResizeBorders} = $self->cget(-resizeborders); # save the value of resizeborders so we can restore it later
	       $self->configure(-resizeborders => 'both');
       }
	$self->{rowColResizeDrag} = 1;  # Flag = 1 if we are currently doing a row/col resize drag
	$self->SUPER::borderDragto(@args);
}

##################################################################
# Over-ridden Motion routine. Does a row/col resize if
#   row/col resize cursors are active
#    This is needed for linux for the row resize to work
#      Not sure why
sub Motion{
	my $self  = shift;
	my $rc = shift;

        my ($x, $y) = split(',', $rc);
	if( $self->{rowColResize}){ # Do a row/col resize if cursors active
		
		if( !$self->{rowColResizeDrag}){   # Same as the borderDragTo, somethings this gets called first
			#print "StartDrag\n";
	       		$self->{oldResizeBorders} = $self->cget(-resizeborders); # save the value of resizeborders so we can restore it later
	      	 	$self->configure(-resizeborders => 'both');
		}
		$self->{rowColResizeDrag} = 1;  # Flag = 1 if we are currently doing a row/col resize drag
		$self->SUPER::borderDragto($x,$y);
	}
	else{
		
		$self->SUPER::Motion($rc);
	}
}
			
#############################################################
## Over-ridden beginselect. Doesn't select if we are doing a row/col resize
sub BeginSelect{
	my $self  = shift;
	my $rc = shift;
	
	return if( $self->{rowColResize}); # Don't Select if currently doing a row/col resize
	
        # Cancel an edit, if one is being edited (i.e. active cell defined)
	my $active;    # Current active cell
	# Get the current active cell, if one exists
	eval { $active = $self->index('active'); }; 
        
        if( $active ){ # If an active cell (i.e. cell being edited, commit it by activating upper left
                # No Active cell if it is set to the upper left column (i.e. esc key pressed)
                my $upperLeft = $self->cget(-roworigin).",".$self->cget(-colorigin);
                $self->activate($upperLeft) if( $active ne $upperLeft);
        }

        
	# print "Calling inherited BeginSelect\n";
	$self->SUPER::BeginSelect($rc);
	
}


#############################################################
## Over-ridden TableInsert. 
##  If a  key is pressed and a cell is not activated. Activate the
##    current cell and insert the key pressed
sub TableInsert{
	my $self  = shift;
	my $key = shift;


	# Activate the current anchor position, if 
	#  key pressed, and no cell currently active
	
	# Get the current active cell, if one exists
	eval { $active = $self->index('active'); }; 
		
	$active = '' if( $@); # No Active cell found;

	# No Active cell if it is set to the upper left column (esc key pressed)
    	my $upperLeft = $self->cget(-roworigin).",".$self->cget(-colorigin);

	$active = '' if( $active eq $upperLeft); # No Active cell found;

	if( $key ne '' && $active eq '' ){
        	my $anchor = $self->index('anchor');
		$self->activate($anchor);
		$self->deleteActive(0,'end'); # delete text from the cell
	}
		
	$self->SUPER::TableInsert($key);
	
}


#############################################################
## Over-ridden MoveCell. 
##  This method performs moving cells in a more Excel-like way:
##   1) Moving cell when one is active unactivates the cell and then selects (not activates)
##      the new cell
##   2) Moving cell when none is active moves the anchor point cell, if one exits.
##   3)  Does nothing otherwise

sub MoveCell{

	my $w = shift;
	my $x = shift; # Delta X for moving
	my $y = shift; # Delta y for moving
	my $c;
	my $cell;      # new cell index
	my $true;
	my $r;
        
	#print "MoveCell $x $y\n";
	my $fromCell; # Cell to move from (Could be an active cell, if present, or selection anchor point
		      #  if present.
		      
	my $active;    # Current active cell

	# Get the current active cell, if one exists
	eval { $active = $w->index('active'); }; 

	$active = '' if( $@); # No Active cell found;

	# No Active cell if it is set to the upper left column (i.e. esc key pressed)
    	my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);

	$active = '' if( $active eq $upperLeft); # No Active cell found;

	if( $active eq ''){  # no active cell found, see if there is a selection
		my $anchor = eval{$w->index('anchor')};

				
		unless( defined($anchor) ){
			# print "Anchor not defined\n";
			return;
		}
		
		$fromCell = $anchor;
	}
	else{
		$fromCell = $active;
	}
			

	($r,$c) = split(',',$fromCell);
	# my $currentCell = "$r,$c";

	$cell = $w->index(($r += $x).",".($c += $y));


	$w->activate($upperLeft) if( $active ne '');
	$w->see($cell);
        #print "calling beginSelect on $cell\n";
        #$w->SUPER::BeginSelect($cell);
	if ($w->cget('-selectmode') eq 'browse')
	 {
	  $w->selection('clear','all');
	  $w->selection('set',$cell);
	 }
	elsif ($w->cget('-selectmode') eq 'extended')
	 {
	  $w->selection('clear','all');
	  $w->selection('set',$cell);
	  $w->selection('anchor',$cell);
	  $Tcl::pTk::TableMatrix::tkPriv{'tablePrev'} = $cell;
	 }
}	
	

#############################################################
## Over-ridden Paste. 
##  This method performs pasting cells in a more Excel-like way:
##   Paste Data will be pasted into the current selection anchor point
##     if no current cell is active, otherwise it pastes starting at the active
##       cell.
##
##   If no current active cell, and no anchor point, does nothing.
sub Paste{
	 my $w = shift;
	 my $cell = shift || ''; 
	 my $source = shift || 'CLIPBOARD';  # Default is to paste from the clipboard
	 my $data;
	 
	 # Check for active cell or anchor cell:
	 unless($cell){


		my $active;    # Current active cell

		# Get the current active cell, if one exists
		eval { $active = $w->index('active'); }; 

		$active = '' if( $@); # No Active cell found;

		# No Active cell if it is set to the upper left column (i.e. esc key pressed)
    		my $upperLeft = $w->cget(-roworigin).",".$w->cget(-colorigin);

		$active = '' if( $active eq $upperLeft); # No Active cell found;

		if( $active eq ''){  # no active cell found, see if there is a selection
			$cell = $w->index('anchor');

			return unless( $cell); # don't paste if no anchor point and no active

		}
		else{
			$cell = $active;
		}

	 }
	 
	 eval{ $data = $w->SelectionGet(-selection => $source); }; return if($@);
 	 $w->PasteHandler($cell,$data);
 	 $w->focus if ($w->cget('-state') eq 'normal');
}


#############################################################
#
# Sub called when button 1 released. 
#   Takes care or row/col border drags. 
#     Also checks to see if more than one row/col is selected during
#     a row/col resize, so those row/cols will be resized as well
sub Button1Release{
    my $w  = shift;
    #print "Button Release 1\n";
    if ( $w->{rowColResizeDrag} ) {   # Row/Col resize finishing up
        my @selRowCol = $w->curselection;
        if ( $w->{rowColResizeRow} ) { # Row risize, check for other rows selected
            my $row = $w->{rowColResizeRow};

            my $newRowHeight = $w->rowHeight($row);
            #print "Resized row $row to height" . $newRowHeight . "\n";

           # Find other selected rows (must be contiguous selected from the drag row)
            my $rowOrg = $w->cget( -roworigin );
            my $colOrg = $w->cget( -colorigin );
            my $rowMax = $rowOrg + $w->cget( -rows ) - 1;    # max row in table
            my $firstDataRow =
              $rowOrg + $w->cget( -titlerows );              # first Data Row
            my $firstDataCol =
              $colOrg + $w->cget( -titlecols );              # first Data Col
            my @otherRowsSelected;
            foreach my $row ( ( $row + 1 ) .. $rowMax ) {    # Increasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$row,$firstDataCol") );
                push @otherRowsSelected, $row;
            }
            foreach my $row ( reverse( $firstDataRow .. ( $row - 1 ) ) )
            {                                                # Decreasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$row,$firstDataCol") );
                push @otherRowsSelected, $row;
            }

            # Set New row height for other rows
            if (@otherRowsSelected) {

                #  Set args to row => height, row => height ...
                my @rowHeightArgs =
                  map { $_ => $newRowHeight } @otherRowsSelected;
                $w->rowHeight(@rowHeightArgs);
            }
        }
        elsif ( $w->{rowColResizeCol} ) { # Col risize, check for other Cols selected
            my $col = $w->{rowColResizeCol};

            my $newColWidth = $w->colWidth($col);
            #print "Resized col $col to width" . $newColWidth . "\n";

           # Find other selected cols (must be contiguous selected from the drag col)
            my $rowOrg = $w->cget( -roworigin );
            my $colOrg = $w->cget( -colorigin );
            my $colMax = $colOrg + $w->cget( -cols ) - 1;    # max col in table
            my $firstDataRow =
              $rowOrg + $w->cget( -titlerows );              # first Data Row
            my $firstDataCol =
              $colOrg + $w->cget( -titlecols );              # first Data Col
            my @otherColsSelected;
            foreach my $col ( ( $col + 1 ) .. $colMax ) {    # Increasing cols
                #print "Checking for inclusion of $firstDataRow,$col\n";
                last unless ( $w->selectionIncludes("$firstDataRow,$col") );
                push @otherColsSelected, $col;
            }
            foreach my $col ( reverse( $firstDataCol .. ( $col - 1 ) ) )
            {                                                # Decreasing rows
                #print "Checking for inclusion of $row,$firstDataCol\n";
                last unless ( $w->selectionIncludes("$firstDataRow,$col") );
                push @otherColsSelected, $col;
            }

            # Set Col width height for other rows
            if (@otherColsSelected) {

                #  Set args to row => height, row => height ...
                my @colWidthArgs =
                  map { $_ => $newColWidth } @otherColsSelected;
                $w->colWidth(@colWidthArgs);
            }
        }
    }

    if($w->{rowColResizeDrag}){
    
        # restore the value of resize borders to what is was before
	if( my $oldResizeborders = $w->{oldResizeBorders}){
    		$w->configure(-resizeborders => $oldResizeborders);
		delete $w->{oldResizeBorders};
	}
    
    	#print "Drag Finished\n";
    }
    
    $w->{rowColResizeDrag} = 0;        # reset row/col resize dragging flag
    $w->{rowColResizeRow}  = undef;    # reset row resize flag
    $w->{rowColResizeCol}  = undef;    # reset col resize flag
    if ( $w->Exists ) {
        $w->CancelRepeat;

    }
}


# Button1 --
#
#  Overridden from the parent class
#
#  Make clicking the mouse button in an cell being edited cause the insertion cursor
#  to go to that location.
#  If not being edited, act like normal (i.e. call the parent Button1)
#
#
# Arguments:
#   w	- the table widget
#   x	- x coord
#   y	- y coord
# Results:
#   Returns nothing
#
sub Button1 {
	my $w = shift;
	my ( $x, $y ) = @_;
        
        # Check for an active cell (i.e. we are currently editing)
        my $active = eval { $w->index('active'); }; 
        if( $active){
            # Check to see if the mouse click was in the active cell
            my $clickedCell = eval{ $w->index('@'.$x.','.$y) };
            if( $clickedCell && ($clickedCell eq $active) ){
                    $w->activate('@'.$x.','.$y);
                    return;
            }
        }
        
        $w->SUPER::Button1($x,$y);
}

# B1Motion --
#
#  Overridden from the parent class
#
#  Makes risizing of row/cols possible only from the row/col titls areas (like excel)
#
# Arguments:
#   w	- the table widget
#   x	- x coord
#   y	- y coord
# Results:
#   Returns nothing
#
sub B1Motion {

	my $w = shift;
        my ($x,$y) = @_;
        
	my $rowColResize = $w->{rowColResize};  # Flag = 1 if cursor has been changed for a row/col resize
        
        # if the row/col handles are present Or we aren't over a border, do a normal B1Motion
        if( $rowColResize || !$Tcl::pTk::TableMatrix::tkPriv{borderInfo}  ) {
                $w->SUPER::B1Motion($x,$y);
        }
        else{
                return;
        }
}

1;

