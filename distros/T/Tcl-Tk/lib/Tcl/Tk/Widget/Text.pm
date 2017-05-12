use strict;

package Tcl::Tk::Widget::Text;
# borrowed from Tk/Text.pm without any modifications

sub unselectAll
{
 my ($w) = @_;
 $w->tagRemove('sel','1.0','end');
}
sub SelectionGet
{
 my ($w) = @_;
 $w->selectionGet(@_);
}

########################################################################
sub FindAll
{
 my ($w,$mode, $case, $pattern ) = @_;
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

 ## if searching forward, start search at end of selected block
 ## if backward, start search from start of selected block.
 ## dont want search to find currently selected text.
 ## tag 'sel' may not be defined, use eval loop to trap error
 eval {
  if ($direction eq '-forward')
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

 if ($direction eq '-forward')
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



Tcl::Tk::Widget::create_method_in_widget_package (
    'ROText',
    unselectAll => \&unselectAll,
    SelectionGet => \&SelectionGet,
    FindAll => \&FindAll,
    FindSelectionNext       => \&FindSelectionNext,
    FindSelectionPrevious   => \&FindSelectionPrevious,
    FindNext                => \&FindNext,
    FindAndReplaceAll       => \&FindAndReplaceAll,
    ReplaceSelectionsWith   => \&ReplaceSelectionsWith,
    FindAndReplacePopUp     => \&FindAndReplacePopUp,
    FindPopUp               => \&FindPopUp,
    findandreplacepopup     => \&findandreplacepopup,
);

1;

