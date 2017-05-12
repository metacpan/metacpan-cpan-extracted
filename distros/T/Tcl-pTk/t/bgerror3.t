# Test to check error reporting for a background error
#   that occurs due to a undefined sub 
#  This version handles the error using ErrorDialog
use Test;
BEGIN {plan tests=>1}
use Tcl::pTk;
use Tcl::pTk::ErrorDialog;

print STDERR "Error Dialog Should Show. This is expected\n";

my $mw = MainWindow->new;

$mw->after(2000, 
        sub{ 
             # Simulate pressing the ok button on the error dialog
             $Tcl::pTk::ErrorDialog::ED_OBJECT->Subwidget('error_dialog')->{'default_button'}->invoke; 
        }
        );
        

# Setup label with a scroll command that is not defined
#   This will create a backgound error.
my $lb = $mw->Listbox->pack;
$lb->configure(-yscrollcommand =>  \&bogus);
$lb->insert(qw/0 foo/);
$lb->update;

ok(1);
exit;



