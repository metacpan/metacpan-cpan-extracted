# This is a test of the BrowseEntry widget, a standard perl/tk megawidget


use Tcl::pTk;
use strict;
use Test;
use Tcl::pTk::ttkBrowseEntry;

#use Tk;
#use Tk::BrowseEntry;


$| = 1;

my $top = MainWindow->new();

# This will skip if Tile widgets not available
my $tclVersion = $top->tclVersion;
unless( $tclVersion > 8.4 ){
        plan tests => 1;
        skip("Tile Tests on Tcl version < 8.5", 1);
        exit;
}

plan tests => 10;

my @choices = (1..50);

#my @choices = (qw/ on11111111111111111111111111e two2222222222222222222 three333333333333 four444444444444444/);

my $ttkoption;
my $cb = $top->ttkBrowseEntry(-variable => \$ttkoption, -choices => 
   \@choices, 

   # For testing, add BrowseEntry compatibility options that will be ignored
   -labelForeground=>'blue',        -labelBackground=>'white',

  #-height => 20
  #-width => 2
  );
$cb->pack(-side => 'top'); #, -fill => 'x', -expand => 1);

# Create another one with a label
my $cb2 = $top->ttkBrowseEntry(-variable => \$ttkoption, -choices => 
   \@choices, 
   -label => "Label:",

   # For testing, add BrowseEntry compatibility options that will be ignored
   -labelForeground=>'blue',        -labelBackground=>'white',

  #-height => 20
  #-width => 2
  );
$cb2->pack(-side => 'top'); #, -fill => 'x', -expand => 1);


# Create a -listcmd and simulate a call
my $listCmdArg;
my @listCmdArgs;
$cb->configure(-listcmd => [sub{
                my @args = @_;
                #print "listcmd Args = ".join(", ",@args)."\n";
                my $w = pop @args;
                @listCmdArgs = @args;
                #$w->configure(-choices => [1..5]);
                $listCmdArg = $w;
        },
        'ExtraArg1',
        'ExtraArg2']);

$cb->_postcommandCallback();

ok(ref($listCmdArg), 'Tcl::pTk::ttkBrowseEntry', '-listcmd callback');
ok(join(", ", @listCmdArgs), "ExtraArg1, ExtraArg2", '-listcmd callback args');

#$cb->set("10");

# check delete method
$cb->delete(0, 'end');


my @choices2 = $cb->cget(-choices);
ok(@choices2, 0, "Empty Choices after delete");

$cb->insert(0, @choices);
@choices2 = $cb->cget(-choices);
ok(@choices2, 50, "Choices populated after insert");

# Check the get command
my @choices3 = $cb->get(10, 'end');
#print "Choices3 = ".join(", ", @choices3)."\n";
ok($choices3[0], 11, "Get value return 1");
ok($choices3[-1], 50, "Get value return 2");
ok(scalar(@choices3), 40, "Get value return 3");

#print "Combobox width  = ".$cb->cget(-width)."\n";
#print "Combobox height = ".$cb->cget(-height)."\n";


# $cb->bind('<<ComboboxSelected>>', 
#         sub{ 
#                 print "Selected args = ".join(', ', @_)."\n";
#                 print "get returns ".$cb->get()."\n";
#                 print "Variable is $ttkoption\n";
#                 });

# Check browsecmd operation
$top->after(1000, 
        sub{
        # Check browsecmd by sending virtual events
        my $selection;
        $cb->configure(-browsecmd => 
               [ sub{ 
                        my ($extraArg, $w, $value) = @_;
                        #print "browsecmd args ".join(", ", @_)."\n";
                        $selection = $value;
                        
                        ok($extraArg, 'extraArg', "browsecmd arg order check");
                        
                }, 'extraArg']
                );
        
        $cb->set(3); # Make a selection
        # generate event that would happen if we actually made the selection in the GUI
        $cb->Subwidget('combobox')->eventGenerate('<<ComboboxSelected>>');

        # check for browsecmd being called
        ok($selection, 3, "browsecmd check");

        $selection = undef;
        
        # Now check browse2cmd
        $cb->configure(-browsecmd => undef);
        

        $cb->configure(-browse2cmd => 
                sub{ 
                        my ($w, $value) = @_;
                        #print STDERR "browse2cmd args ".join(", ", @_)."\n";
                        $selection = $value;
                        
                });
                
        $cb->set(21); # Make a selection
        # generate event that would happen if we actually made the selection in the GUI
        $cb->Subwidget('combobox')->eventGenerate('<<ComboboxSelected>>');

        ok($selection, 20, "browse2cmd check");
        });



$top->after(2000, sub{ $top->destroy() }) unless (@ARGV); # for debugging, don't go away if something on the command line
MainLoop;

#print "options = $ttkoption\n";





