
use Tcl::pTk ( qw/ MainLoop DoOneEvent tkinit update Ev Exists /); # Don't import MainLoop, we create our own later

package Tcl::pTk::TkHijack;

our ($VERSION) = ('1.00');

=head1 NAME

Tcl::pTk::TkHijack -  Run Existing Perl/tk Scripts with Tcl::pTk


=head1 SYNOPSIS

        # Run a existing perl/tk script 'tkscript.pl' with Tcl::pTk
        perl -MTcl::pTk::TkHijack tkscript.pl
        
        # Alternatively, you can just put 'use Tcl::pTk::TkHijack' at the
        #  top of the 'tkscript.pl' file and just run it like normal

=head1 DESCRIPTION

I<Tcl::pTk::TkHijack> is an experimental module that makes existing perl/tk use L<Tcl::pTk> to run.
It 'Hijacks' any 'use Tk' and related calls in a perl/tk script to use Tcl::pTk.

=head1 How It Works

A sub ref (tkHijack) is pushed onto perl's global @INC array. This sub intercepts any 'use Tk'
or related calls and substitutes them with their Tcl::pTk equivalents. Additionally, some package aliases are setup between the Tk and the Tcl::pTk namespace

=head1 Examples

There are some examples of using TkHijack with a simple perl/tk script, and a perl/tk mega-widget. See
C<t/tkHijack_simple.t> and C<t/tkHijack_mega.t> in the source distribution.

=head1 LIMITATIONS

=over 1

=item *

XEvent calls are not translated, because there is no equivalent in Tcl::pTk (XEvent was a perl/tk specific addition to Tk, and doesn't exists in Tcl/Tk)

=item *

Perl/Tk widgets that use XS code can't be handled with this package.

=back

=cut

our($debug, $translateList, $packageAliases, $aliasesMade);

unshift @INC, \&TkHijack;


######### Package Globals ####    
$debug = 1;


# Mapping of Tk Packages that have equivalence in Tcl::pTk.
#   If a Tk package is mapped to undef, then that means its functionality is already included
#   in the main Tcl::pTk package.
#  This list is used for mapping "use" statements, for example if
#    "use Tk::Tree" is encountered, the file "Tcl/pTk/Tree.pm" is loaded instead
$translateList = { 
        'Tk.pm'         =>  '',
        'Tk/Tree.pm'    =>  'Tcl/pTk/Tree.pm',
        'Tk/Balloon.pm'    =>  '',
        'Tk/Bitmap.pm'    =>  '',
        'Tk/BrowseEntry.pm'    =>  'Tcl/pTk/BrowseEntry.pm',
        'Tk/Canvas.pm'    =>  'Tcl/pTk/Canvas.pm',
        'Tk/Clipboard.pm'    =>  'Tcl/pTk/Clipboard.pm',
        'Tk/Dialog.pm'    =>  '',
        'Tk/DialogBox.pm'    =>  '',
        'Tk/DirTree.pm'    =>  'Tcl/pTk/DirTree.pm',
        'Tk/DragDrop.pm'    =>  'Tcl/pTk/DragDrop.pm',
        'Tk/DropSite.pm'    =>  'Tcl/pTk/DropSite.pm',
        'Tk/Frame.pm'       =>  '',
        'Tk/Font.pm'       =>  '',
        'Tk/HList.pm'    =>  'Tcl/pTk/HList.pm',
        'Tk/Image.pm'    =>  'Tcl/pTk/Image.pm',
        'Tk/ItemStyle.pm'    =>  'Tcl/pTk/ItemStyle.pm',
        'Tk/LabEntry.pm'    =>  '',
        'Tk/Listbox.pm'    =>  'Tcl/pTk/Listbox.pm',
        'Tk/MainWindow.pm'    =>  'Tcl/pTk/MainWindow.pm',
        'Tk/Photo.pm'    =>  'Tcl/pTk/Photo.pm',
        'Tk/ProgressBar.pm'    =>  'Tcl/pTk/ProgressBar.pm',
        'Tk/ROText.pm'    =>  'Tcl/pTk/ROText.pm',
        'Tk/Table.pm'    =>  'Tcl/pTk/Table.pm',
        'Tk/Text.pm'    =>  'Tcl/pTk/Text.pm',
        'Tk/TextEdit.pm'    =>  'Tcl/pTk/TextEdit.pm',
        'Tk/TextUndo.pm'    =>  'Tcl/pTk/TextUndo.pm',
        'Tk/Toplevel.pm'    =>  '',
        'Tk/Tiler.pm'    =>  'Tcl/pTk/Tiler.pm',
        'Tk/widgets.pm' =>  'Tcl/pTk/widgets.pm',
        'Tk/LabFrame.pm' => '',
        'Tk/Submethods.pm' => 'Tcl/pTk/Submethods.pm',
        'Tk/Menu.pm'       => '',
        'Tk/Wm.pm'            => 'Tcl/pTk/Wm.pm',
        'Tk/Widget.pm'      => '',
        'Tk/FileSelect.pm'      => '',
        'Tk/After.pm'       => '',
        'Tk/Derived.pm'     => '',
        'Tk/NoteBook.pm'     => '',
        'Tk/NBFrame.pm'     => '',
        'Tk/Pane.pm'     => 'Tcl/pTk/Pane.pm',
        'Tk/Adjuster.pm'     => 'Tcl/pTk/Adjuster.pm',
        'Tk/TableMatrix.pm'     => 'Tcl/pTk/TableMatrix.pm',
        'Tk/TableMatrix/Spreadsheet.pm'     => 'Tcl/pTk/TableMatrix/Spreadsheet.pm',
        'Tk/TableMatrix/SpreadsheetHideRows.pm'     => 'Tcl/pTk/TableMatrix/SpreadsheetHideRows.pm',
        'Tk/ErrorDialog.pm'     => 'Tcl/pTk/ErrorDialog.pm',
};


# List of alias that will be created for Tk packages to Tcl::pTk packages
#   This is to make megawidgets created in Tk work. For example,
#     if a Tk mega widget has the following code:
#       use base(qw/ Tk::Frame /);
#       Construct Tk::Widget 'SlideSwitch'
#     The aliases below will essentially translate to code to mean:
#       use base(qw/ Tcl::pTk::Frame /);
#       Construct Tcl::pTk::Widget 'SlideSwitch'
#       
$packageAliases = {
        'Tk::Frame' => 'Tcl::pTk::Frame',
        'Tk::Toplevel' => 'Tcl::pTk::Toplevel',
        'Tk::MainWindow' => 'Tcl::pTk::MainWindow',
        'Tk::Widget'=> 'Tcl::pTk::Widget',
        'Tk::Derived'=> 'Tcl::pTk::Derived',
        'Tk::DropSite'    =>  'Tcl::pTk::DropSite',
        'Tk::Canvas'    =>  'Tcl::pTk::Canvas',
        'Tk::Menu'=> 'Tcl::pTk::Menu',
        'Tk::TextUndo'=> 'Tcl::pTk::TextUndo',
        'Tk::Text'=> 'Tcl::pTk::Text',
        'Tk::Tree'=> 'Tcl::pTk::Tree',
        'Tk::Clipboard'=> 'Tcl::pTk::Clipboard',
        'Tk::Configure'=> 'Tcl::pTk::Configure',
        'Tk::BrowseEntry'=> 'Tcl::pTk::BrowseEntry',
        'Tk::Callback'=> 'Tcl::pTk::Callback',
        'Tk::TableMatrix'=> 'Tcl::pTk::TableMatrix',
        'Tk::Table'=> 'Tcl::pTk::Table',
        'Tk::TableMatrix::Spreadsheet'=> 'Tcl::pTk::TableMatrix::Spreadsheet',
        'Tk::TableMatrix::SpreadsheetHideRows'=> 'Tcl::pTk::TableMatrix::SpreadsheetHideRows',
};
  
######### End of Package Globals ###########
# Alias Packages
aliasPackages($packageAliases);





sub TkHijack {
    # When placed first on the INC path, this will allow us to hijack
    # any requests for 'use Tk' and any Tk::* modules and replace them
    # with our own stuff.
    my ($coderef, $module) = @_;  # $coderef is to myself
    #print "TkHijack encoutering $module\n";
    return undef unless $module =~ m!^Tk(/|\.pm$)!;
    
    #print "TkHijack $module\n";

    my ($package, $callerfile, $callerline) = caller;
    #print "TkHijack package/callerFile/callerline = $package $callerfile $callerline\n";
    
    my $mapped = $translateList->{$module};
    
    if( defined($mapped) && !$mapped){ # Module exists in translateList, but no mapped file
            my $fakefile;
            open(my $fh, '<', \$fakefile) || die "oops"; # open a file "in-memory"
        
            $module =~ s!/!::!g;
            $module =~ s/\.pm$//;
        
            # Make Version if importing Tk (needed for some scripts to work right)
            my $versionText = "\n";
            my $requireText = "\n"; #  if Tk module, set export of Ev subs
            if( $module eq 'Tk' ){
                    
                    $requireText = "use Exporter 'import';\n";
                    $requireText .= '@EXPORT_OK = (qw/ Ev catch/);'."\n";
                    
                    $versionText = '$Tk::VERSION = 805.001;'."\n";
                    
                    # Redefine common Tk subs/variables to Tcl::pTk equivalents
                    no warnings;
                    *Tk::MainLoop = \&Tcl::pTk::MainLoop;
                    *Tk::findINC = \&Tcl::pTk::findINC;
                    *Tk::after = \&Tcl::pTk::after;
                    *Tk::DoOneEvent = \&Tcl::pTk::DoOneEvent;
                    *Tk::Ev = \&Tcl::pTk::Ev;
                    *Tk::Exists = \&Tcl::pTk::Exists;
                    *Tk::break = \&Tcl::pTk::break;
                    *Tk::platform = \$Tcl::pTk::platform;
                    *Tk::timeofday = \&Tcl::pTk::timeofday;
                    *Tk::fileevent = \&Tcl::pTk::fileevent;
                    *Tk::bind = \&Tcl::pTk::Widget::bind;
                    *Tk::ACTIVE_BG = \&Tcl::pTk::ACTIVE_BG;
                    *Tk::NORMAL_BG = \&Tcl::pTk::NORMAL_BG;
                    *Tk::SELECT_BG = \&Tcl::pTk::SELECT_BG;
                    
                    
            }
        
        
            $fakefile = <<EOS;
        package $module;
        $requireText
        $versionText
        #warn "### $callerfile:$callerline not really loading $module ###" if($Tcl::pTk::TkHijack::debug);
        sub foo { 1; }
        1;
EOS
        return $fh;
    }
    elsif( defined($mapped) ){ # Module exists in translateList with a mapped file

            # Turn mapped file into name suitable for a 'use' statement
            my $usefile = $mapped;
            $usefile =~ s!/!::!g;
            $usefile =~ s/\.pm$//;

            #warn "### $callerfile:$callerline loading Tcl Tk $usefile to substitute for $module ###" if($Tcl::pTk::TkHijack::debug);
            # Turn mapped file into use statement
            my $fakefile;
            open(my $fh, '<', \$fakefile) || die "oops"; # open a file "in-memory"
             $fakefile = <<EOS;
        use $usefile;
        1;
EOS
             return $fh;       
    }
    else{
            #warn("Warning No Tcl::pTk Equivalent to $module from $callerfile line $callerline, loading anyway...\n") if $debug;
    }
            
}

############## Sub To Alias Packages ########
sub aliasPackages{
        my $aliases = shift;
        my $aliasTo;
        foreach my $aliasFrom ( keys %$aliases){
            $aliasTo = $packageAliases->{$aliasFrom};
            *{$aliasFrom.'::'} = *{$aliasTo.'::'};
        }
}


################### MainWindow package #################3
## Created so the lines like the following work
##   my $mw = new MainWindow;
package MainWindow;

sub new{
        Tcl::pTk::MainWindow();
}

1;
