# Test Case for Fileevent reading
#  This is different from fileevent.t, in that it uses the Tcl::pTk->fileevent method of calling

# fileevent example
# (reading the output of an external command into a text widget)
# no luxuries (like scrollbars)

use Tcl::pTk;
use IO::File;

use Test;
plan tests => 1;

my $mw = MainWindow->new(-title => "fileevent Test");

my $command = "perl -w t/fileeventSubProcesses";

my $lineFromFile; # Last line read from the file 

$| = 1;  # Pipes hot

my $cmd = new IO::Handle;
open($cmd, "$command|") or die("Can't open $command");

my $text = $mw->Text(qw/ -bd 3 -relief sunken -width 80 -height 30 /)->pack;

Tcl::pTk->fileevent($cmd, 'readable', sub{ handleInput($cmd, $text)});

$mw->after( 6000, sub{ Tcl::pTk->fileevent($cmd, 'readable', undef); close $cmd; }); # Cancel the fileevent

$mw->after( 7000, sub{ $mw->destroy}); # close everything


MainLoop();

chomp $lineFromFile;
ok($lineFromFile, 'Sleep 5', "fileevent");

sub handleInput{
        my $handle       = shift;
        my $textWidget   = shift;
        
        if( $handle->eof() ){ # Close if at the end
                $handle->close;
                print "Closed\n";
                return
        }
        
        my $data = <$handle>;
        #print "data = '$data'\n";
        
        $lineFromFile = $data;  # Save line from data for test case.
        $textWidget->insert('end', $data);
        $textWidget->update;
                
}



