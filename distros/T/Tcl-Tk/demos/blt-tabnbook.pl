use strict;
use Tcl::Tk qw(:perlTk);

my $mw = tkinit;

# declare tabnotebook widgets rules to Tcl::Tk  
$mw->Declare('BLTNoteBook','blt::tabnotebook',-require=>'BLT',-prefix=>'bltnbook');

# Create a tabnotebook widget.  
my $tab = $mw->BLTNoteBook->pack(-fill=>'both');

# The notebook is initially empty.  Insert tabs (pages) into the notebook.  
for my $label (qw{ First Second Third Fourth }) {
    $tab->insert('end', -text=>$label);
}

$tab->tabConfigure($_, -window=>$tab->Label(-text=>"text of label $_")) for 0..3;

$tab->configure(-tearoff=>'yes');
$tab->focus;

MainLoop;

