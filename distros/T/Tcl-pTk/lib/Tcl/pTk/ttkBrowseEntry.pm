package Tcl::pTk::ttkBrowseEntry;

our ($VERSION) = ('1.02');

=head1 NAME 

Tcl::pTk::ttkBrowseEntry - BrowseEntry compatible wrapper for ttkCombobox

=head1 SYNOPSIS

 use Tcl::pTk;
 use Tcl::pTk::ttkBrowseEntry;

 $b = $frame->ttkBrowseEntry(-label => "Label", -variable => \$var, 
          -labelPack => [-side => 'left']);
 $b->insert("end", "opt1");
 $b->insert("end", "opt2");
 $b->insert("end", "opt3");
  ...
 $b->pack;

=head1 DESCRIPTION

L<Tcl::pTk::ttkBrowseEntry> is a wrapper around the Tile widget I<ttkCombobox> that is compatible with L<Tcl::pTk::BrowseEntry>.
It is provided for a quick upgrade of existing code to use the newer Combobox widget.

=head1 OPTIONS

In addition to the options of the parent widget, this widget recognizes the following options:

=over 1

=item B<-label>

Optional name of a label to include for the browseEntry.

=item B<-labelPack>

Optional Array-ref of information used to pack the optional label.

=item B<-autolimitheight>

This option is provided for compatibility with BrowseEntry, but is ignored.

=item B<-arrowimage>

This option is provided for compatibility with BrowseEntry, but is ignored.

=item B<-autolimitheight>

This option is provided for compatibility with BrowseEntry, but is ignored.

=item B<-autolistwidth>

This option is provided for compatibility with BrowseEntry, but is ignored. (The Combobox
widget always sets its listwidth the same as the width of the entry)

=item B<-browsecmd>

Specifies a function to call when a selection is made in the
popped up listbox. It is passed the widget and the text of the
entry selected. This function is called after the entry variable
has been assigned the value.

=item B<-browse2cmd>

Like C<-browsecmd>, but the callback is called with the listbox index
instead of the selected value.

=item B<-buttontakefocus>

Set the C<-takefocus> option of the button subwidget. This option is mapped to the C<-takefocus>
option of the comboBox widget.

=item B<-choices>

Specifies the list of choices to pop up.  This is a reference to an
array of strings specifying the choices.

=item B<-colorstate>

This option is provided for compatibility with BrowseEntry, but is ignored.

=item B<-label*>

Any options that start with 'label' (e.g. -labelBackground, -labelFont) are provided for compatibility with BrowseEntry, but are ignored.

=item B<-listcmd>

Specifies the function to call when the button next to the entry
is pressed to popup the choices in the listbox. This is called before
popping up the listbox, so can be used to populate the entries in
the listbox.

=item B<-listheight>

Set the height of the listbox. This option is mapped to the C<-height> option
of the Combobox.

=item B<-listwidth>

This option is provided for compatibility with BrowseEntry, but is ignored. (The Combobox
widget always sets its listwidth the same as the width of the entry)

=item B<-state>

Specifies one of three states for the widget: normal, readonly, or
disabled.

=item B<-style>

This option is provided for compatibility with BrowseEntry, but is ignored.

=item B<-variable>

Specifies the variable in which the entered value is to be stored.

=back

=head1 METHODS

=over 4

=item B<insert(>I<index>, I<string>B<)>

Inserts the text of I<string> at the specified I<index>. This string
then becomes available as one of the choices.

=item B<delete(>I<index1>, I<index2>B<)>

Deletes items from I<index1> to I<index2>.

=item B<get(>I<index1>, I<index2>B<)>

gets items from I<index1> to I<index2>. This is there for compatibility with BrowseEntry.
 
=item B<choiceget>

Get the current selected choice. This directly maps to the I<get> method of the combobox

        
=back


=cut



use Tcl::pTk qw(Ev);
use Carp;
use strict;


use base qw(Tcl::pTk::Frame);
Construct Tcl::pTk::Widget 'ttkBrowseEntry';

sub Populate {
    my ($cw, $args) = @_;
     
    # Set foreground and background options to undef, unless defined during widget creation
    #   This keeps Tcl::pTk::Derived from setting these options from the options database, which is
    #    not needed for ttk widgets, and also makes -state => 'disabled' not look right
    foreach my $option( qw/ -foreground -background /){
            $args->{$option} = undef unless( defined($args->{$option} ));
    }
    
    # combobox widget
    my $lpack = delete $args->{-labelPack};
    if (not defined $lpack) {
	$lpack = [-side => 'left', -anchor => 'e'];
    }

    $cw->SUPER::Populate($args);


    my $label;
    if (exists $args->{-label}) {
	$label = $cw->ttkLabel(
			   -text => delete $args->{-label},
			  );
        $cw->Advertise('label' => $label );
        $label->pack(@$lpack);
    }
    
    # Setup label options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = ( qw/ 
    -label -labelActivebackground -labelActiveforeground -labelAnchor -labelBackground
    -labelBitmap -labelBorderwidth -labelCompound -labelCursor -labelDisabledforeground
    -labelFont -labelForeground -labelHeight -labelHighlightbackground -labelHighlightcolor 
    -labelHighlightthickness -labelImage -labelJustify -labelPack -labelPadx -labelPady 
    -labelRelief -labelState -labelTakefocus -labelUnderline -labelVariable -labelWidth -labelWraplength 
    /);
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);

    my $cb = $cw->ttkCombobox();
    $cb->pack( -side => 'right', -fill => 'x', -expand => 1); 
    $cw->Advertise('combobox' => $cb);

    $cw->Delegates(DEFAULT => $cb); # methods are handled by the combobox
    $cw->ConfigSpecs( 
		      DEFAULT => [ 'combobox' ],  # Default options go to ttkCombobox
                      -arrowimage      => ['PASSIVE', 'arrowimage', 'arrowimage', undef], # ignored for compatibility with BrowseEntry
                      -autolimitheight => ['PASSIVE', 'autolimitheight', 'autolimitheight', undef], # ignored for compatibility with BrowseEntry
                      -autolistwidth  => ['PASSIVE', 'autolimitwidth', 'autolimitwidth', undef],    # ignored for compatibility with BrowseEntry
                      -browsecmd       => ['CALLBACK', 'browsecmd',  'browsecmd',  undef], 
                      -browse2cmd      => ['CALLBACK', 'browse2cmd', 'browse2cmd', undef], 
                      -buttontakefocus => [ {-takefocus => $cb}, qw/takefocus takefocus/, undef],
                      -choices         => [ {-values => $cb}, qw/choices choices/, undef],
                      -colorstate      => ['PASSIVE', 'colorstate', 'colorstate', undef], # ignored for compatibility with BrowseEntry
                      -listcmd         => ['CALLBACK', 'listcmd',  'listcmd',  undef], 
                      -listheight      => [ {-height => $cb}, qw/listheight listheight/, undef],
                      -listwidth       => ['PASSIVE', 'listwidth', 'listwidth', undef], # ignored for compatibility with BrowseEntry 
                                                                                        # (combobox listbox is always the same as -width, 
                                                                                        #   so not needed)
                      -variable        => [ {-textvariable => $cb}, qw/textvariable textvariable/, undef],
                      
                      -command     => '-browsecmd',
                      -options     => '-choices',
		      %ignoreConfigSpecs, 
                      
    );
    
    # Create callback to emulate -browsecmd and -browsecmd2 options
    $cw->bind('<<ComboboxSelected>>', [$cw, '_ComboboxSelected']);

    # Create callback to emulate -listcmd options
    $cw->configure(-postcommand => [$cw, '_postcommandCallback']);
    
      
}



#########################################################################
# Sub called when choice selected. This fires off any browsecmd callbacks that have been
#   stored
#
#
sub _ComboboxSelected{
        my $self = shift;
        my $path = shift;
        
        # Check for browsecmd or browsecmd2 being set
        my $browsecmd = $self->cget(-browsecmd);
        my $browsecmd2 = $self->cget(-browse2cmd);
        if( defined($browsecmd) && $browsecmd->isa('Tcl::pTk::Callback')){
                my $sel = $self->choiceget(); # Get current selection
                $self->Callback(-browsecmd, $self, $sel );
        }
        elsif( defined($browsecmd2) && $browsecmd2->isa('Tcl::pTk::Callback')){
                my $index = $self->current(); # Get current index
                $self->Callback(-browse2cmd, $self, $index );
        }
       
}

#########################################################################
# Sub called when selection box pops up. This fires off any listcmd callbacks that have been
#   stored
#
#
sub _postcommandCallback{
        my $self = shift;
        
        # Check for listcmd callbacks being set
        my $listcmd = $self->cget(-listcmd);
        if( defined($listcmd) && $listcmd->isa('Tcl::pTk::Callback')){
                $self->Callback(-listcmd, $self);
        }
       
}

###########################################
# Wrapper for the insert method. For compatibility with BrowseEntry, insert works on the choices, and not just
#  what is in the entry widget
sub insert {
    my $w = shift;
    my $index = shift;
    my @insertValues = @_;
    my @choices = $w->cget('-choices');
    
    $index = 0 unless(@choices); # If choices is empty, insert starting at the beginning
    
    $index = $#choices if( $index eq 'end' ); # get the last index if insert is 'end';
    # Add insertvalues to choices and update widget
    splice @choices, $index, 0, @insertValues;
    
    $w->configure('-choices' => \@choices);
    
}

# Wrapper for the delete method. For compatibility with BrowseEntry, delete works on the choices, and not just
#  what is in the entry widget
sub delete {
    my $w = shift;
    my ($start, $stop) = @_;
    my @choices = $w->cget('-choices'); 
    
    $stop = $start if( !defined($start)); # Take care of case where $stop not supplied
    
    # Change any 'end' in the indexes to actual number
    foreach my $entry($start, $stop){
            $entry = $#choices if($entry eq 'end');
    }
    
    my $count = $stop - $start + 1;
    
    # Update Choices
    splice @choices, $start, $count;
    
    $w->configure('-choices' => \@choices);

}

# Wrapper for the get method. For compatibility with BrowseEntry, get works on the choices, and not just
#  what is in the entry widget
sub get {
    my $w = shift;
    my ($start, $stop) = @_;
    my @choices = $w->cget('-choices'); 
    
    $stop = $start if( !defined($start)); # Take care of case where $stop not supplied
    
    # Change any 'end' in the indexes to actual number
    foreach my $entry($start, $stop){
            $entry = $#choices if($entry eq 'end');
    }
    
    my $count = $stop - $start + 1;
    
    return @choices[$start..$stop];

}

# Wrapper for choiceget. This calls 'get' on the combobox subwidget, which just gets the
# currently selected value
sub choiceget{
        my $w = shift;
        my $sb = $w->Subwidget('combobox');
        $sb->get(@_);
}

# Wrapper for labelpack. This is provided for compatibility with perl/tk, but doesn't nothing
#
sub labelPack{
        my $w = shift;

}

1;
