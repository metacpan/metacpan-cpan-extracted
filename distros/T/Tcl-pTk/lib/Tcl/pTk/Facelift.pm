use Tcl::pTk;
use Tcl::pTk::BrowseEntry;
use Tcl::pTk::ttkBrowseEntry;
use Tcl::pTk::ttkTixNoteBook;

package Tcl::pTk::Facelift;

our ($VERSION) = ('1.02');

=head1 NAME

Tcl::pTk::Facelift -  Update the look of older Tk scripts using the new tile widgets


=head1 SYNOPSIS

        # Run a existing tcl/tk script 'tcltkscript.pl' with an updated look
        perl -MTcl::pTk::Facelift tcltkscript.pl
        
        # Alternatively, you can just put 'use Tcl::pTk::Facelift' at the
        #  top of the 'tcltkscript.pl' file and just run it like normal

        # You can also do this in combination with Tcl::pTk::TkHijack to run
        #  an existing perl/tk script using Tcl::pTk and with an updated look
        #  
        perl -MTcl::pTk::TkHijack -MTcl::pTk::Facelift tkscript.pl

=head1 DESCRIPTION

I<Tcl::pTk::Facelift> is an experimental module that gives existing tcl/tk scripts an updated look by substituting
some the widgets (button, entry, label, etc) with their new "Tile" widget equivalents.
        
Note that this replacement/substitution is not complete. The new "Tile" widgets aren't 100% compatible with the
older widgets. To take full advantage of the new Tcl/Tk "Tile" widgets, 
you should re-code your application to specifically take advantage of them.

This package only replaces some of the basic widgets (e.g. button, label, entry, etc) with their tile-widget equivalents.

=head1 How It Works

New widgets are created that override the creation-methods for the old widgets. These new methods create the new "Tile"
widgets, instead of the old widgets.
        
For Example, this code snippet would create a top-level window, and a Label and Button widget 
 
 use Tcl::pTk;
 my $mw     = MainWindow->new();
 my $label  = $mw->Label();
 my $button = $mw->Button();
 
Now, with the addition of the C<use Tcl::pTk::Facelift> package, the I<Label> and <Button> creation-methods
get over-ridden to build "Tile" widgets.
        
 use Tcl::pTk;
 use Tcl::pTk::Facelift;
 my $mw     = MainWindow->new();
 my $label  = $mw->Label();
 my $button = $mw->Button();

B<Note:> The new widgets created in this package have the same options as the old widget, but where there is no
equivalent option in the new "Tile" widget, the option is ignored.
        
For example, most appearance-related options that are present in the old widgets don't exist in the new "Tile" widgets,
because Tile-widgets appearances are controlled using "Themes". So the -bg (background color) option that exists for an old "button" widget
doesn't exist in the new "ttkButton" widget. For better compatibility with existing scripts, the Tile-substitution
widgets (e.g. the Button, Entry, etc widgets) created in this package will have
a appearance options (e.g. -bg, -fg, etc) option, but they will be ignored. 

=head1 Examples

There are some examples of using Facelift (along with TkHijack) with a simple perl/tk script, and a perl/tk mega-widget. See
C<t/Facelift_simple.t> and C<t/Facelift_mega.t> in the source distribution.

=head1 LIMITATIONS

=over 1

=item *

Substitutes for all the old widgets aren't provided

=item *

Options in the old widgets that aren't present the new Tile widgets are simply ignored.

=back

=cut

############# Substitution Package for oldwidget "Radiobutton" to tile widget "ttkRadiobutton" ####################

package Tcl::pTk::RadiobuttonttkSubs;


@Tcl::pTk::RadiobuttonttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Widget/);


Construct Tcl::pTk::Widget 'Radiobutton';



sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -activebackground,
     -activeforeground,
     -anchor,
     -background,
     -bd,
     -bg,
     -bitmap,
     -borderwidth,
     -disabledforeground,
     -fg,
     -font,
     -foreground,
     -height,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -indicatoron,
     -justify,
     -offrelief,
     -overrelief,
     -padx,
     -pady,
     -relief,
     -selectcolor,
     -selectimage,
     -tristateimage,
     -tristatevalue,
     -wraplength

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['SELF']
    );



}



sub containerName{
        return 'ttkRadiobutton';
}



1;

############################################################


############# Substitution Package for oldwidget "Button" to tile widget "ttkButton" ####################

package Tcl::pTk::ButtonttkSubs;


@Tcl::pTk::ButtonttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Widget/);


Construct Tcl::pTk::Widget 'Button';


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -activebackground,
     -activeforeground,
     -anchor,
     -background,
     -bd,
     -bg,
     -bitmap,
     -borderwidth,
     -disabledforeground,
     -fg,
     -font,
     -foreground,
     -height,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -justify,
     -overrelief,
     -padx,
     -pady,
     -relief,
     -repeatdelay,
     -repeatinterval,
     -wraplength

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['SELF']
    );



}



sub containerName{
        return 'ttkButton';
}



1;

############################################################


############# Substitution Package for oldwidget "Entry" to tile widget "ttkEntry" ####################

package Tcl::pTk::EntryttkSubs;


@Tcl::pTk::EntryttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Widget/);


Construct Tcl::pTk::Widget 'Entry';


sub Populate {
    my( $cw, $args ) = @_;
    
    # Set foreground and background options to undef, unless defined during widget creation
    #   This keeps Tcl::pTk::Derived from setting these options from the options database, which is
    #    not needed for ttk widgets, and also makes -state => 'disabled' not look right
    foreach my $option( qw/ -foreground -background /){
            $args->{$option} = undef unless( defined($args->{$option} ));
    }


    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -bd,
     -bg,
     -borderwidth,
     -disabledbackground,
     -disabledforeground,
     -fg,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -insertbackground,
     -insertborderwidth,
     -insertofftime,
     -insertontime,
     -insertwidth,
     -invcmd,
     -readonlybackground,
     -relief,
     -selectbackground,
     -selectborderwidth,
     -selectforeground,
     -vcmd

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['SELF']
    );



}



sub containerName{
        return 'ttkEntry';
}



1;

############################################################


############# Substitution Package for oldwidget "Frame" to tile widget "ttkFrame" ####################

package Tcl::pTk::FramettkSubs;


@Tcl::pTk::FramettkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Frame/);


Construct Tcl::pTk::Widget 'Frame';


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -background,
     -bd,
     -colormap,
     -container,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -padx,
     -pady,
     -visual

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['SELF']
    );



}


sub containerName{
        return 'ttkFrame';
}


#Add -class to the list of options that will (if present) be fed to the base widget at creation
sub CreateOptions{
        my $self = shift;
        return ($self->SUPER::CreateOptions, "-class");
}



# Wrapper sub so frame-based mega-widgets still work with the facelift
sub Tcl::pTk::Frame{
        my $self = shift;
        my $obj = $self->Tcl::pTk::ttkFrame(@_);
        bless $obj, "Tcl::pTk::FramettkSubs";
        return $obj;
}


1;

############################################################


############# Substitution Package for oldwidget "Checkbutton" to tile widget "ttkCheckbutton" ####################

package Tcl::pTk::CheckbuttonttkSubs;


@Tcl::pTk::CheckbuttonttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Widget/);


Construct Tcl::pTk::Widget 'Checkbutton';


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -activebackground,
     -activeforeground,
     -anchor,
     -background,
     -bd,
     -bg,
     -bitmap,
     -borderwidth,
     -disabledforeground,
     -fg,
     -font,
     -foreground,
     -height,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -indicatoron,
     -justify,
     -offrelief,
     -overrelief,
     -padx,
     -pady,
     -relief,
     -selectcolor,
     -selectimage,
     -tristateimage,
     -tristatevalue,
     -wraplength

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['SELF']
    );



}



sub containerName{
        return 'ttkCheckbutton';
}



1;

############################################################


############# Substitution Package for oldwidget "Label" to tile widget "ttkLabel" ####################

package Tcl::pTk::LabelttkSubs;


@Tcl::pTk::LabelttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::Widget/);


Construct Tcl::pTk::Widget 'Label';


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );


    #### Setup options ###
    
    
    # Setup options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = (
     -activebackground,
     -activeforeground,
     -bd,
     -bitmap,
     -disabledforeground,
     -height,
     -highlightbackground,
     -highlightcolor,
     -highlightthickness,
     -padx,
     -pady

    );
    
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
	# Set default values for -justify and -anchor. This is needed for facelifted LabEntry to 
	#  work with -labelJustify, etc options
        -justify => ['SELF', 'justify', 'Justify', 'center'],
        -anchor  => ['SELF', 'justify', 'Justify', 'center'],
        'DEFAULT' => ['SELF']
    );



}



sub containerName{
        return 'ttkLabel';
}


# Wrapper sub so mega-widgets still work with the facelift
sub Tcl::pTk::Label{
        my $self = shift;
        my $obj = $self->Tcl::pTk::ttkLabel(@_);
        bless $obj, "Tcl::pTk::LabelttkSubs";
        return $obj;
}


1;

############################################################

############# Substitution Package for oldwidget "BrowseEntry" to tile widget "ttkBrowseEntry" ####################

package Tcl::pTk::BrowseEntryttkSubs;


@Tcl::pTk::BrowseEntryttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::ttkBrowseEntry/);

{
        local $^W = 0; # To avoid subroutine redefined warning messages
        Construct Tcl::pTk::Widget 'BrowseEntry';
}


# If we are being used in conjunction with TkHijack, we don't need a mapping for Tk::BrowseEntry
if( defined $Tcl::pTk::TkHijack::translateList){
        #print STDERR "undoing translatelist\n";
        $Tcl::pTk::TkHijack::translateList->{'Tk/BrowseEntry.pm'}    =  '';
}


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );

    # Create LabEntry subwidget (won't be visible/packed)
    my $be = $cw->LabEntry();
    $cw->Advertise('entry' => $be);
    
    my %ignoreConfigSpecs = ();
    $cw->ConfigSpecs(
        %ignoreConfigSpecs,
        'DEFAULT' => ['combobox']
    );



}

# Alias the entire BrowseEntry namespace to ttkBrowseEntry, so Browse-Entry subclasses widgets
#   work correctly
*Tcl::pTk::BrowseEntry:: = *Tcl::pTk::ttkBrowseEntry::;

# Redefine the BrowseEntry Mapping if TkHijack loaded, so BrowseEntry subclasses will still work
*Tk::BrowseEntry:: = *Tcl::pTk::BrowseEntry:: if( defined $Tcl::pTk::TkHijack::packageAliases );


# Wrapper sub so mega-widgets still work with the facelift
sub Tcl::pTk::BrowseEntry{
        my $self = shift;
        my $obj = $self->Tcl::pTk::ttkBrowseEntry(@_);
        bless $obj, "Tcl::pTk::BrowseEntryttkSubs";
        return $obj;
}

############# Substitution Package for oldwidget "NoteBook" to tile widget "ttkTixNoteBook" ####################

package Tcl::pTk::NoteBookttkSubs;


@Tcl::pTk::NoteBookttkSubs::ISA = (qw / Tcl::pTk::Derived Tcl::pTk::ttkTixNoteBook/);

{
        local $^W = 0; # To avoid subroutine redefined warning messages
        Construct Tcl::pTk::Widget 'NoteBook';
}


# If we are being used in conjunction with TkHijack, we don't need a mapping for Tk::NoteBook
if( defined $Tcl::pTk::TkHijack::translateList){
        #print STDERR "undoing translatelist\n";
        $Tcl::pTk::TkHijack::translateList->{'Tk/NoteBook.pm'}    =  '';
}



# Alias the entire NoteBook namespace to ttkTixNoteBook, so NoteBook subclasses widgets
#   work correctly
*Tcl::pTk::NoteBook:: = *Tcl::pTk::ttkTixNoteBook::;

# Redefine the NoteBook Mapping if TkHijack loaded, so NoteBook subclasses will still work
*Tk::NoteBook:: = *Tcl::pTk::NoteBook:: if( defined $Tcl::pTk::TkHijack::packageAliases );


# Wrapper sub so mega-widgets still work with the facelift
sub Tcl::pTk::NoteBook{
        my $self = shift;
        my $obj = $self->Tcl::pTk::ttkTixNoteBook(@_);
        bless $obj, "Tcl::pTk::NoteBookttkSubs";
        return $obj;
}

################ New Tcl::pTk::Widget::Contruct Method used for Facelift #########
##
##  This has the same function as Tcl::pTk::Widget::Construct defined in MegaWidget.pm
##   but also has code to alter the inheritance of derived widgets so that they are
##   properly face-lifted.
##   For example, 
# This "Constructs" a creation method for megawidgets and derived widgets

{

        
        # Mapping of superclass inheritance. e.g Tk::Frame inheritance should be mapped to FramettkSubs inheritance
        my %hijackInheritance = (
                'Tk::Frame'                    => 'Tcl::pTk::FramettkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Frame'       => 'Tcl::pTk::FramettkSubs', # For normal Tcl::pTk widgets
                'Tk::Radiobutton'              => 'Tcl::pTk::RadiobuttonettkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Radiobutton' => 'Tcl::pTk::RadiobuttonettkSubs', # For normal Tcl::pTk widgets
                'Tk::Button'                   => 'Tcl::pTk::ButtonttkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Button'      => 'Tcl::pTk::ButtonttkSubs', # For normal Tcl::pTk widgets
                'Tk::Entry'                    => 'Tcl::pTk::EntryttkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Entry'       => 'Tcl::pTk::EntryttkSubs', # For normal Tcl::pTk widgets
                'Tk::Checkbutton'              => 'Tcl::pTk::CheckbuttonttkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Checkbutton' => 'Tcl::pTk::CheckbuttonttkSubs', # For normal Tcl::pTk widgets
                'Tk::Label'                    => 'Tcl::pTk::LabelbuttonttkSubs', # For Hijack Tk Widgets
                'Tcl::pTk::Label'       => 'Tcl::pTk::LabelbuttonttkSubs', # For normal Tcl::pTk widgets
                'Tk::BrowseEntry'              => 'Tcl::pTk::BrowseEntry', # For Hijack Tk Widgets
                'Tcl::pTk::BrowseEntry' => 'Tcl::pTk::BrowseEntryttkSubs', # For normal Tcl::pTk widgets
                'Tk::NoteBook'              => 'Tcl::pTk::NoteBook',       # For Hijack Tk Widgets
                'Tcl::pTk::NoteBook'    => 'Tcl::pTk::NoteBookttkSubs',    # For normal Tcl::pTk widgets
                );
        
        # Save the existing Construct method. We will chain to that at the end of our routine 
        BEGIN{
        *Tcl::pTk::Widget::Construct2 = \&Tcl::pTk::Widget::Construct;
        }
        
        no warnings;
        
        sub Tcl::pTk::Widget::Construct
        {
         my ($base,$name) = @_;
         my $class = (caller(0))[0];
         no strict 'refs';
        
         
         my @parents = @{"$class\::ISA"};
         #print "Hijacked Construct: $class = $class, ISA = ".join(", ", @parents)."\n";
         foreach my $parent(@{"$class\::ISA"}){
                 if( defined($hijackInheritance{$parent}) && $class ne $hijackInheritance{$parent}){
                         #print "setting ISA element $parent to ".$hijackInheritance{$parent}."\n";
                         $parent = $hijackInheritance{$parent};
                 }
         }
         
         # Go to the normal Construct
         goto \&Tcl::pTk::Widget::Construct2;
         
        }
        
        }

1;

