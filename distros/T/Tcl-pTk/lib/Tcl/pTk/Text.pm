use strict;


package Tcl::pTk::Text;

use Text::Tabs;

our ($VERSION) = ('1.00');

# borrowed from Tk/Text.pm without any modifications

use base  qw(Tcl::pTk::Clipboard Tcl::pTk::Widget);

use Tcl::pTk::Submethods
                   ( 'mark'   => [qw(gravity  next previous set unset)],  # names left out, because defined as a list function in Widget.pm
		     'scan'   => [qw(mark dragto)],
		     'tag'    => [qw(add cget  delete lower
				     nextrange prevrange raise remove)],
		     'window' => [qw(cget  create)],
		     'image'  => [qw(cget  create)],
		     'xview'  => [qw(moveto scroll)],
		     'yview'  => [qw(moveto scroll)],
                     'edit'   => [qw(modified redo reset separator undo)],
		     );


sub ClassInit
{
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw, 'Text'); # Call with optional 'Text' Tag
 # right-click menu
 $mw->bind(
   $class,
   $mw->windowingsystem eq 'aqua' ? '<2>' : '<3>',
   ['PostPopupMenu', Tcl::pTk::Ev('X'), Tcl::pTk::Ev('Y')],
  );
 
 # We use the 'Text' tag for the bindings below, because we are adding to the tcl text-widget
 #  bindings, which are under the 'Text' bindtag.
 $class = 'Text';
 $mw->bind($class,'<KeyPress>',['InsertKeypress',Tcl::pTk::Ev('A')]);
 $mw->bind($class,'<Insert>', \&ToggleInsertMode ) ;
 $mw->bind($class,'<Delete>','Delete');
 
 $mw->bind($class,'<F1>', 'clipboardColumnCopy');
 $mw->bind($class,'<F2>', 'clipboardColumnCut');
 $mw->bind($class,'<F3>', 'clipboardColumnPaste');
 
 $mw->bind($class,'<BackSpace>','Backspace');
 
 $mw->MouseWheelBind($class);


}


sub selectAll
{
 my ($w) = @_;
 $w->tagAdd('sel','1.0','end');
}

sub unselectAll
{
 my ($w) = @_;
 $w->tagRemove('sel','1.0','end');
}

sub adjustSelect
{
 my ($w) = @_;
 my $Ev = $w->XEvent;
 $w->ResetAnchor($Ev->xy);
 $w->SelectTo($Ev->xy,'char')
}

sub selectLine
{
 my ($w) = @_;
 my $Ev = $w->XEvent;
 $w->SelectTo($Ev->xy,'line');
 Tcl::pTk::catch { $w->markSet('insert','sel.first') };
}

sub selectWord
{
 my ($w) = @_;
 my $Ev = $w->XEvent;
 $w->SelectTo($Ev->xy,'word');
 Tcl::pTk::catch { $w->markSet('insert','sel.first') }
}

sub Backspace
{
 my ($w) = @_;
 my $sel = Tcl::pTk::catch { $w->tag('nextrange','sel','1.0','end') };
 if (defined $sel)
  {
   $w->delete('sel.first','sel.last');
   return;
  }
 $w->deleteBefore;
}

sub Delete
{
 my ($w) = @_;
 my $sel = Tcl::pTk::catch { $w->tag('nextrange','sel','1.0','end') };
 if (defined $sel)
  {
   $w->delete('sel.first','sel.last')
  }
 else
  {
   $w->delete('insert');
   $w->see('insert')
  }
}

sub deleteBefore
{
 my ($w) = @_;
 if ($w->compare('insert','!=','1.0'))
  {
   $w->delete('insert-1c');
   $w->see('insert')
  }
}

sub deleteToEndofLine
{
 my ($w) = @_;
 if ($w->compare('insert','==','insert lineend'))
  {
   $w->delete('insert')
  }
 else
  {
   $w->delete('insert','insert lineend')
  }
}

sub openLine
{
 my ($w) = @_;
 $w->insert('insert',"\n");
 $w->markSet('insert','insert-1c')
}

sub InsertSelection
{
 my ($w) = @_;
 Tcl::pTk::catch { $w->Insert($w->SelectionGet) }
}

# SetCursor
# Move the insertion cursor to a given position in a text. Also
# clears the selection, if there is one in the text, and makes sure
# that the insertion cursor is visible.
#
# Arguments:
# w - The text window.
# pos - The desired new position for the cursor in the window.
sub SetCursor
{
 my ($w,$pos) = @_;
 $pos = 'end - 1 chars' if $w->compare($pos,'==','end');
 $w->markSet('insert',$pos);
 $w->unselectAll;
 $w->see('insert');
}

########################################################################
sub markExists
{
 my ($w, $markname)=@_;
 my $mark_exists=0;
 my @markNames_list = $w->markNames;
 foreach my $mark (@markNames_list)
  { if ($markname eq $mark) {$mark_exists=1;last;} }
 return $mark_exists;
}

########################################################################
sub OverstrikeMode
{
 my ($w,$mode) = @_;

 $w->{'OVERSTRIKE_MODE'} =0 unless exists($w->{'OVERSTRIKE_MODE'});

 $w->{'OVERSTRIKE_MODE'}=$mode if (@_ > 1);
 return $w->{'OVERSTRIKE_MODE'};
}

########################################################################
# pressed the <Insert> key, just above 'Del' key.
# this toggles between insert mode and overstrike mode.
sub ToggleInsertMode
{
 my ($w)=@_;
 $w->OverstrikeMode(!$w->OverstrikeMode);
}

########################################################################
sub InsertKeypress
{
 my ($w,$char)=@_;
 return unless length($char);
 #print STDERR "InsertKey\n";
 if ($w->OverstrikeMode)
  {
   my $current=$w->get('insert');
   $w->delete('insert') unless($current eq "\n");
  }
 $w->Insert($char);
}

########################################################################
sub GotoLineNumber
{
 my ($w,$line_number) = @_;
 $line_number=~ s/^\s+|\s+$//g;
 return if $line_number =~ m/\D/;
 my ($last_line,$junk)  = split(/\./, $w->index('end'));
 if ($line_number > $last_line) {$line_number = $last_line; }
 $w->{'LAST_GOTO_LINE'} = $line_number;
 $w->markSet('insert', $line_number.'.0');
 $w->see('insert');
}

########################################################################
sub GotoLineNumberPopUp
{
 my ($w)=@_;
 my $popup = $w->{'GOTO_LINE_NUMBER_POPUP'};

 unless (defined($w->{'LAST_GOTO_LINE'}))
  {
   my ($line,$col) =  split(/\./, $w->index('insert'));
   $w->{'LAST_GOTO_LINE'} = $line;
  }

 ## if anything is selected when bring up the pop-up, put it in entry window.
 my $selected;
 eval { $selected = $w->SelectionGet(-selection => "PRIMARY"); };
 unless ($@)
  {
   if (defined($selected) and length($selected))
    {
     unless ($selected =~ /\D/)
      {
       $w->{'LAST_GOTO_LINE'} = $selected;
      }
    }
  }
 unless (defined($popup))
  {
   require Tcl::pTk::DialogBox;
   $popup = $w->DialogBox(-buttons => [qw[Ok Cancel]],-title => "Goto Line Number", -popover => $w,
                          -command => sub { $w->GotoLineNumber($w->{'LAST_GOTO_LINE'}) if $_[0] eq 'Ok'});
   $w->{'GOTO_LINE_NUMBER_POPUP'}=$popup;
   $popup->resizable('no','no');
   my $frame = $popup->Frame->pack(-fill => 'x');
   $frame->Label(-text=>'Enter line number: ')->pack(-side => 'left');
   my $entry = $frame->Entry(-background=>'white', -width=>25,
                             -textvariable => \$w->{'LAST_GOTO_LINE'})->pack(-side =>'left',-fill => 'x');
   $popup->Advertise(entry => $entry);
  }
 $popup->Popup;
 $popup->Subwidget('entry')->focus;
 $popup->Wait;
}


sub getSelected
{
 shift->GetTextTaggedWith('sel');
}

sub deleteSelected
{
 shift->DeleteTextTaggedWith('sel');
}

sub GetTextTaggedWith
{
 my ($w,$tag) = @_;

 my @ranges = $w->tagRanges($tag);
 my $range_total = @ranges;
 my $return_text='';

 # if nothing selected, then ignore
 if ($range_total == 0) {return $return_text;}

 # for every range-pair, get selected text
 while(@ranges)
  {
  my $first = shift(@ranges);
  my $last = shift(@ranges);
  my $text = $w->get($first , $last);
  if(defined($text))
   {$return_text = $return_text . $text;}
  # if there is more tagged text, separate with an end of line  character
  if(@ranges)
   {$return_text = $return_text . "\n";}
  }
 return $return_text;
}

########################################################################
sub DeleteTextTaggedWith
{
 my ($w,$tag) = @_;
 my @ranges = $w->tagRanges($tag);
 my $range_total = @ranges;

 # if nothing tagged with that tag, then ignore
 if ($range_total == 0) {return;}

 # insert marks where selections are located
 # marks will move with text even as text is inserted and deleted
 # in a previous selection.
 for (my $i=0; $i<$range_total; $i++)
  { $w->markSet('mark_tag_'.$i => $ranges[$i]); }

 # for every selected mark pair, insert new text and delete old text
 for (my $i=0; $i<$range_total; $i=$i+2)
  {
  my $first = $w->index('mark_tag_'.$i);
  my $last = $w->index('mark_tag_'.($i+1));

  my $text = $w->delete($first , $last);
  }

 # delete the marks
 for (my $i=0; $i<$range_total; $i++)
  { $w->markUnset('mark_tag_'.$i); }
}

########################################################################
sub ReplaceSelectionsWith
{
 my ($w,$new_text ) = @_;

 my @ranges = $w->tagRanges('sel');
 my $range_total = @ranges;

 # if nothing selected, then ignore
 if ($range_total == 0) {return};

 # insert marks where selections are located
 # marks will move with text even as text is inserted and deleted
 # in a previous selection.
 for (my $i=0; $i<$range_total; $i++)
  {$w->markSet('mark_sel_'.$i => $ranges[$i]); }

 # for every selected mark pair, insert new text and delete old text
 my ($first, $last);
 for (my $i=0; $i<$range_total; $i=$i+2)
  {
  $first = $w->index('mark_sel_'.$i);
  $last = $w->index('mark_sel_'.($i+1));

  ##########################################################################
  # eventually, want to be able to get selected text,
  # support regular expression matching, determine replace_text
  # $replace_text = $selected_text=~m/$new_text/  (or whatever would work)
  # will have to pass in mode and case flags.
  # this would allow a regular expression search and replace to be performed
  # example, look for "line (\d+):" and replace with "$1 >" or similar
  ##########################################################################

  $w->insert($last, $new_text);
  $w->delete($first, $last);

  }
 ############################################################
 # set the insert cursor to the end of the last insertion mark
 $w->markSet('insert',$w->index('mark_sel_'.($range_total-1)));

 # delete the marks
 for (my $i=0; $i<$range_total; $i++)
  { $w->markUnset('mark_sel_'.$i); }
}
########################################################################
sub FindAndReplacePopUp
{
 my ($w)=@_;
 $w->findandreplacepopup(0);
}

########################################################################
sub FindPopUp
{
 my ($w)=@_;
 $w->findandreplacepopup(1);
}

########################################################################

sub findandreplacepopup
{
 my ($w,$find_only)=@_;

 my $pop = $w->Toplevel;
 $pop->transient($w->toplevel);
 if ($find_only)
  { $pop->title("Find"); }
 else
  { $pop->title("Find and/or Replace"); }
 my $frame =  $pop->Frame->pack(-anchor=>'nw');

 $frame->Label(-text=>"Direction:")
  ->grid(-row=> 1, -column=>1, -padx=> 20, -sticky => 'nw');
 my $direction = '-forward';
 $frame->Radiobutton(
  -variable => \$direction,
  -text => 'forward',-value => '-forward' )
  ->grid(-row=> 2, -column=>1, -padx=> 20, -sticky => 'nw');
 $frame->Radiobutton(
  -variable => \$direction,
  -text => 'backward',-value => '-backward' )
  ->grid(-row=> 3, -column=>1, -padx=> 20, -sticky => 'nw');

 $frame->Label(-text=>"Mode:")
  ->grid(-row=> 1, -column=>2, -padx=> 20, -sticky => 'nw');
 my $mode = '-exact';
 $frame->Radiobutton(
  -variable => \$mode, -text => 'exact',-value => '-exact' )
  ->grid(-row=> 2, -column=>2, -padx=> 20, -sticky => 'nw');
 $frame->Radiobutton(
  -variable => \$mode, -text => 'regexp',-value => '-regexp' )
  ->grid(-row=> 3, -column=>2, -padx=> 20, -sticky => 'nw');

 $frame->Label(-text=>"Case:")
  ->grid(-row=> 1, -column=>3, -padx=> 20, -sticky => 'nw');
 my $case = '-case';
 $frame->Radiobutton(
  -variable => \$case, -text => 'case',-value => '-case' )
  ->grid(-row=> 2, -column=>3, -padx=> 20, -sticky => 'nw');
 $frame->Radiobutton(
  -variable => \$case, -text => 'nocase',-value => '-nocase' )
  ->grid(-row=> 3, -column=>3, -padx=> 20, -sticky => 'nw');

 ######################################################
 my $find_entry = $pop->Entry(-width=>25);
 $find_entry->focus;

 my $donext = sub {$w->FindNext ($direction,$mode,$case,$find_entry->get())};

 $find_entry -> pack(-anchor=>'nw', '-expand' => 'yes' , -fill => 'x'); # autosizing

 ######  if any $w text is selected, put it in the find entry
 ######  could be more than one text block selected, get first selection
 my @ranges = $w->tagRanges('sel');
 if (@ranges)
  {
  my $first = shift(@ranges);
  my $last = shift(@ranges);

  # limit to one line
  my ($first_line, $first_col) = split(/\./,$first);
  my ($last_line, $last_col) = split(/\./,$last);
  unless($first_line == $last_line)
   {$last = $first. ' lineend';}

  $find_entry->insert('insert', $w->get($first , $last));
  }
 else
  {
  my $selected;
  eval {$selected=$w->SelectionGet(-selection => "PRIMARY"); };
  if($@) {}
  elsif (defined($selected))
   {$find_entry->insert('insert', $selected);}
  }

 $find_entry->icursor(0);

 my ($replace_entry,$button_replace,$button_replace_all);
 unless ($find_only)
  {
   $replace_entry = $pop->Entry(-width=>25);

  $replace_entry -> pack(-anchor=>'nw', '-expand' => 'yes' , -fill => 'x');
  }


 my $button_find = $pop->Button(-text=>'Find', -command => $donext, -default => 'active')
  -> pack(-side => 'left');

 my $button_find_all = $pop->Button(-text=>'Find All',
  -command => sub {$w->FindAll($mode,$case,$find_entry->get());} )
  ->pack(-side => 'left');

 unless ($find_only)
  {
   $button_replace = $pop->Button(-text=>'Replace', -default => 'normal',
   -command => sub {$w->ReplaceSelectionsWith($replace_entry->get());} )
   -> pack(-side =>'left');
   $button_replace_all = $pop->Button(-text=>'Replace All',
   -command => sub {$w->FindAndReplaceAll
    ($mode,$case,$find_entry->get(),$replace_entry->get());} )
   ->pack(-side => 'left');
  }


  my $button_cancel = $pop->Button(-text=>'Cancel',
  -command => sub {$pop->destroy()} )
  ->pack(-side => 'left');

  $find_entry->bind("<Return>" => [$button_find, 'invoke']);
  $find_entry->bind("<Escape>" => [$button_cancel, 'invoke']);

 $find_entry->bind("<Return>" => [$button_find, 'invoke']);
 $find_entry->bind("<Escape>" => [$button_cancel, 'invoke']);

 $pop->resizable('yes','no');
 return $pop;
}

########################################################################
# Insert --
# Insert a string into a text at the point of the insertion cursor.
# If there is a selection in the text, and it covers the point of the
# insertion cursor, then delete the selection before inserting.
#
# Arguments:
# w - The text window in which to insert the string
# string - The string to insert (usually just a single character)
sub Insert
{
 my ($w,$string) = @_;
 return unless (defined $string && $string ne '');
 #figure out if cursor is inside a selection
 my @ranges = $w->tagRanges('sel');
 if (@ranges)
  {
   while (@ranges)
    {
     my ($first,$last) = splice(@ranges,0,2);
     if ($w->compare($first,'<=','insert') && $w->compare($last,'>=','insert'))
      {
       $w->ReplaceSelectionsWith($string);
       return;
      }
    }
  }
 # paste it at the current cursor location
 $w->insert('insert',$string);
 $w->see('insert');
}

sub Contents
{
 my $w = shift;
 if (@_)
  {
   $w->delete('1.0','end');
   $w->insert('end',shift) while (@_);
  }
 else
  {
   return $w->get('1.0','end');
  }
}

sub WhatLineNumberPopUp
{
 my ($w)=@_;
 my ($line,$col) = split(/\./,$w->index('insert'));
 $w->messageBox(-type => 'Ok', -title => "What Line Number",
                -message => "The cursor is on line $line (column is $col)");
}

########################################################################
sub clipboardColumnCopy
{
 my ($w) = @_;
 $w->Column_Copy_or_Cut(0);
}

sub clipboardColumnCut
{
 my ($w) = @_;
 $w->Column_Copy_or_Cut(1);
}

########################################################################
sub Column_Copy_or_Cut
{
 my ($w, $cut) = @_;
 my @ranges = $w->tagRanges('sel');
 my $range_total = @ranges;
 # this only makes sense if there is one selected block
 unless ($range_total==2)
  {
  $w->bell;
  return;
  }

 my $selection_start_index = shift(@ranges);
 my $selection_end_index = shift(@ranges);

 my ($start_line, $start_column) = split(/\./, $selection_start_index);
 my ($end_line,   $end_column)   = split(/\./, $selection_end_index);

 # correct indices for tabs
 my $string;
 $string = $w->get($start_line.'.0', $start_line.'.0 lineend');
 $string = substr($string, 0, $start_column);
 $string = expand($string);
 my $tab_start_column = length($string);

 $string = $w->get($end_line.'.0', $end_line.'.0 lineend');
 $string = substr($string, 0, $end_column);
 $string = expand($string);
 my $tab_end_column = length($string);

 my $length = $tab_end_column - $tab_start_column;

 $selection_start_index = $start_line . '.' . $tab_start_column;
 $selection_end_index   = $end_line   . '.' . $tab_end_column;

 # clear the clipboard
 $w->clipboardClear;
 my ($clipstring, $startstring, $endstring);
 my $padded_string = ' 'x$tab_end_column;
 for(my $line = $start_line; $line <= $end_line; $line++)
  {
  $string = $w->get($line.'.0', $line.'.0 lineend');
  $string = expand($string) . $padded_string;
  $clipstring = substr($string, $tab_start_column, $length);
  #$clipstring = unexpand($clipstring);
  $w->clipboardAppend($clipstring."\n");

  if ($cut)
   {
   $startstring = substr($string, 0, $tab_start_column);
   $startstring = unexpand($startstring);
   $start_column = length($startstring);

   $endstring = substr($string, 0, $tab_end_column );
   $endstring = unexpand($endstring);
   $end_column = length($endstring);

   $w->delete($line.'.'.$start_column,  $line.'.'.$end_column);
   }
  }
}

########################################################################

sub clipboardColumnPaste
{
 my ($w) = @_;
 my @ranges = $w->tagRanges('sel');
 my $range_total = @ranges;
 if ($range_total)
  {
  warn " there cannot be any selections during clipboardColumnPaste. \n";
  $w->bell;
  return;
  }

 my $clipboard_text;
 eval
  {
  $clipboard_text = $w->SelectionGet(-selection => "CLIPBOARD");
  };

 return unless (defined($clipboard_text));
 return unless (length($clipboard_text));
 my $string;

 my $current_index = $w->index('insert');
 my ($current_line, $current_column) = split(/\./,$current_index);
 $string = $w->get($current_line.'.0', $current_line.'.'.$current_column);
 $string = expand($string);
 $current_column = length($string);

 my @clipboard_lines = split(/\n/,$clipboard_text);
 my $length;
 my $end_index;
 my ($delete_start_column, $delete_end_column, $insert_column_index);
 foreach my $line (@clipboard_lines)
  {
  if ($w->OverstrikeMode)
   {
   #figure out start and end indexes to delete, compensating for tabs.
   $string = $w->get($current_line.'.0', $current_line.'.0 lineend');
   $string = expand($string);
   $string = substr($string, 0, $current_column);
   $string = unexpand($string);
   $delete_start_column = length($string);

   $string = $w->get($current_line.'.0', $current_line.'.0 lineend');
   $string = expand($string);
   $string = substr($string, 0, $current_column + length($line));
   chomp($string);  # don't delete a "\n" on end of line.
   $string = unexpand($string);
   $delete_end_column = length($string);



   $w->delete(
              $current_line.'.'.$delete_start_column ,
              $current_line.'.'.$delete_end_column
             );
   }

  $string = $w->get($current_line.'.0', $current_line.'.0 lineend');
  $string = expand($string);
  $string = substr($string, 0, $current_column);
  $string = unexpand($string);
  $insert_column_index = length($string);

  $w->insert($current_line.'.'.$insert_column_index, unexpand($line));
  $current_line++;
  }

}

# ResetAnchor --
# Set the selection anchor to whichever end is farthest from the
# index argument. One special trick: if the selection has two or
# fewer characters, just leave the anchor where it is. In this
# case it does not matter which point gets chosen for the anchor,
# and for the things like Shift-Left and Shift-Right this produces
# better behavior when the cursor moves back and forth across the
# anchor.
#
# Arguments:
# w - The text widget.
# index - Position at which mouse button was pressed, which determines
# which end of selection should be used as anchor point.
sub ResetAnchor
{
 my ($w,$index) = @_;
 if (!defined $w->tag('ranges','sel'))
  {
   $w->markSet('anchor',$index);
   return;
  }
 my $a = $w->index($index);
 my $b = $w->index('sel.first');
 my $c = $w->index('sel.last');
 if ($w->compare($a,'<',$b))
  {
   $w->markSet('anchor','sel.last');
   return;
  }
 if ($w->compare($a,'>',$c))
  {
   $w->markSet('anchor','sel.first');
   return;
  }
 my ($lineA,$chA) = split(/\./,$a);
 my ($lineB,$chB) = split(/\./,$b);
 my ($lineC,$chC) = split(/\./,$c);
 if ($lineB < $lineC+2)
  {
   my $total = length($w->get($b,$c));
   if ($total <= 2)
    {
     return;
    }
   if (length($w->get($b,$a)) < $total/2)
    {
     $w->markSet('anchor','sel.last')
    }
   else
    {
     $w->markSet('anchor','sel.first')
    }
   return;
  }
 if ($lineA-$lineB < $lineC-$lineA)
  {
   $w->markSet('anchor','sel.last')
  }
 else
  {
   $w->markSet('anchor','sel.first')
  }
}



# Front-End for tagBind
sub tagBind{
        
	    my $self = shift;
            
            # Getting Bindings:
            if( $#_ == 0){ # Usage: my @bindings = $text->tagBind($tag) 
                my $tag = $_[0];
                return $self->interp->call($self->bind_path,'tag', 'bind', $tag);
            }
            elsif( $#_ == 1){ # Usage: my $binding = $text->tagBind($tag, $sequence)
                my ($tag, $sequence) = @_;
               $sequence = $self->expandSeq($sequence); # get un-abbreviated version of sequence

               my $widget_data = $self->interp->widget_data($tag); # Get callback stored with widget data
               return $widget_data->{$sequence};
            }
            # Setting Bindings
	    elsif ($#_==2) {  # Usage: $text->tagBind($tag, $seq, $sub)
		my ($tag, $seq, $sub) = @_;

                $seq = $self->expandSeq($seq); # get un-abbreviated version of sequence
		$sub = $self->_bind_widget_helper($sub, $tag, $seq);
 
                # Make a subref that will execute the callback, supplying $self as the event source
                my $cbRef = $sub->createTclBindRef($self);

		$self->interp->call($self->bind_path,'tag', 'bind', $tag,$seq,$cbRef);
	    }
	    else {
		$self->interp->call($self->bind_path, 'tag', 'bind',@_);
	    }
}

# Front-end for tag
#   If called as $text->tag('bind', ...) then tagBind is called, else it passes thru
#   the args
sub tag{
        my $self = shift;
        if( $#_ > 0 && $_[0] eq 'bind'){
                shift; # get rid of bind arg
                $self->tagBind(@_);
        }
        else{
                $self->call($self->bind_path, 'tag',@_);
        }
}

                
########################################################################
sub FindAll
{
 my ($w,$mode, $case, $pattern ) = @_;
 $mode = _expandModeFlag($mode);
 ### 'sel' tags accumulate, need to remove any previous existing
 $w->unselectAll;

 my $match_length=0;
 my $start_index;
 my $end_index = '1.0';

 while(defined($end_index))
  {
  if ($case eq '-nocase')
   {
   $start_index = $w->search(
    $mode,
    $case,
    -count => \$match_length,
    "--",
    $pattern ,
    $end_index,
    'end');
   }
  else
   {
   $start_index = $w->search(
    $mode,
    -count => \$match_length,
    "--",
    $pattern ,
    $end_index,
    'end');
   }

  unless(defined($start_index) && $start_index) {last;}

  my ($line,$col) = split(/\./, $start_index);
  $col = $col + $match_length;
  $end_index = $line.'.'.$col;
  $w->tagAdd('sel', $start_index, $end_index);
  }
}

########################################################################
# get current selected text and search for the next occurrence
sub FindSelectionNext
{
 my ($w) = @_;
 my $selected;
 eval {$selected = $w->SelectionGet(-selection => "PRIMARY"); };
 return if($@);
 return unless (defined($selected) and length($selected));

 $w->FindNext('-forward', '-exact', '-case', $selected);
}

########################################################################
# get current selected text and search for the previous occurrence
sub FindSelectionPrevious
{
 my ($w) = @_;
 my $selected;
 eval {$selected = $w->SelectionGet(-selection => "PRIMARY"); };
 return if($@);
 return unless (defined($selected) and length($selected));

 $w->FindNext('-backward', '-exact', '-case', $selected);
}



########################################################################
sub FindNext
{
 my ($w,$direction, $mode, $case, $pattern ) = @_;
 $mode = _expandModeFlag($mode);
 
 ## if searching forward, start search at end of selected block
 ## if backward, start search from start of selected block.
 ## don't want search to find currently selected text.
 ## tag 'sel' may not be defined, use eval loop to trap error
 my $is_forward = $direction =~ m{^-f} && $direction eq substr("-forwards", 0, length($direction));
 eval {
  if ($is_forward)
   {
   $w->markSet('insert', 'sel.last');
   $w->markSet('current', 'sel.last');
   }
  else
   {
   $w->markSet('insert', 'sel.first');
   $w->markSet('current', 'sel.first');
   }
 };

 my $saved_index=$w->index('insert');

 # remove any previous existing tags
 $w->unselectAll;

 my $match_length=0;
 my $start_index;

 if ($case eq '-nocase')
  {
  $start_index = $w->search(
   $direction,
   $mode,
   $case,
   -count => \$match_length,
   "--",
   $pattern ,
   'insert');
  }
 else
  {
  $start_index = $w->search(
   $direction,
   $mode,
   -count => \$match_length,
   "--",
   $pattern ,
   'insert');
  }

 unless(defined($start_index)) { return 0; }
 if(length($start_index) == 0) { return 0; }

 my ($line,$col) = split(/\./, $start_index);
 $col = $col + $match_length;
 my $end_index = $line.'.'.$col;
 $w->tagAdd('sel', $start_index, $end_index);

 $w->see($start_index);

 if ($is_forward)
  {
  $w->markSet('insert', $end_index);
  $w->markSet('current', $end_index);
  }
 else
  {
  $w->markSet('insert', $start_index);
  $w->markSet('current', $start_index);
  }

 my $compared_index = $w->index('insert');

 my $ret_val;
 if ($compared_index eq $saved_index)
  {$ret_val=0;}
 else
  {$ret_val=1;}
 return $ret_val;
}

########################################################################
sub FindAndReplaceAll
{
 my ($w,$mode, $case, $find, $replace ) = @_;
 $w->markSet('insert', '1.0');
 $w->unselectAll;
 while($w->FindNext('-forward', $mode, $case, $find))
  {
  $w->ReplaceSelectionsWith($replace);
  }
}



##################### Menu Functions ##############
## Originally in Tk::Text ###
sub MenuLabels
{
 return qw[~File ~Edit ~Search ~View];
}

sub SearchMenuItems
{
 my ($w) = @_;
 return [
    ['command'=>'~Find',          -command => [$w => 'FindPopUp']],
    ['command'=>'Find ~Next',     -command => [$w => 'FindSelectionNext']],
    ['command'=>'Find ~Previous', -command => [$w => 'FindSelectionPrevious']],
    ['command'=>'~Replace',       -command => [$w => 'FindAndReplacePopUp']]
   ];
}

sub EditMenuItems
{
 my ($w) = @_;
 my @items = ();
 foreach my $op ($w->clipEvents)
  {
   push(@items,['command' => "~$op", -command => [ $w => "clipboard$op"]]);
  }
 push(@items,
    '-',
    ['command'=>'Select All', -command   => [$w => 'selectAll']],
    ['command'=>'Unselect All', -command => [$w => 'unselectAll']],
  );
 return \@items;
}

sub ViewMenuItems
{
 my ($w) = @_;
 my $v;
# tie $v,'Tk::Configure',$w,'-wrap';
 return  [
    ['command'=>'Goto ~Line...', -command => [$w => 'GotoLineNumberPopUp']],
    ['command'=>'~Which Line?',  -command =>  [$w => 'WhatLineNumberPopUp']],
    ['cascade'=> 'Wrap', -tearoff => 0, -menuitems => [
      [radiobutton => 'Word', -variable => \$v, -value => 'word'],
      [radiobutton => 'Character', -variable => \$v, -value => 'char'],
      [radiobutton => 'None', -variable => \$v, -value => 'none'],
    ]],
  ];
}

# Workaround for compatibility with Perl/Tk search()
# (used by Tk::Text Find methods), which accepts
# abbreviated flags, whereas Tcl/Tk search() does not
#
# TODO: should this be rewritten as _expandSearchFlags
# and process e.g. $direction or $case as well?
sub _expandModeFlag {
  my $mode = shift;
  if (($mode =~ m{^-e}) &&
      ($mode eq substr("-exact", 0, length($mode)))) {
    $mode = '-exact';
  } elsif (($mode =~ m{^-r}) &&
      ($mode eq substr("-regex", 0, length($mode)))) {
    $mode = '-regex';
  }
  return $mode;
}


1;

