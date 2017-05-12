# Test Case for Fileevent reading

# fileevent example
# (reading the output of an external command into a text widget)
# no luxuries (like scrollbars)

use Tcl::pTk;
use IO::File;

use Test;
plan tests => 2;

my $closed = 0;  # Flag = 1 when fileevent pipe from the child process closes
                 #  We check to see if this happens on non-windows platforms. 
                 #   This doesn't work on win32 because of issues detecting an eof on the pipe on 
                 #   win32 (without messing up buffering). This is ok for Tcl::pTk compatibility with perl/tk
                 #   because fileevent on pipes didn't work on win32 for perl/tk anyway.
 
my $mw = MainWindow->new(-title => "fileevent Test");

my $command = "perl -w t/fileeventSubProcesses";

my $lineFromFile; # Last line read from the file 

$| = 1;  # Pipes hot

my $cmd = new IO::Handle;
open($cmd, "$command|") or die("Can't open $command");

my $text = $mw->Text(qw/ -bd 3 -relief sunken -width 80 -height 30 /)->pack;

$mw->fileevent($cmd, 'readable', sub{ handleInput($cmd, $text)});

$mw->after( 6000, sub{ $mw->fileevent($cmd, 'readable', undef); close $cmd; }); # Cancel the fileevent

$mw->after( 7000, sub{ $mw->destroy}); # close everything


MainLoop();

chomp $lineFromFile;
ok($lineFromFile, 'Sleep 5', "fileevent");

# Check for pipe closed non-win32
skip(
   $^O !~ m/MSWin/ ? 0 : "Fileevent Pipe Close Test Skipped if MSWin",    # whether to skip
   $closed, 1, "Fileevent Pipe Closed Test"  # arguments just like for ok(...)
 );


sub handleInput{
        my $handle       = shift;
        my $textWidget   = shift;
        
        if( $handle->eof() ){ # Close if at the end
                $handle->close;
                print "Closed\n";
                $closed = 1;
                return
        }
        
        my $data = <$handle>;
        #print "data = '$data'\n";
        
        $lineFromFile = $data;  # Save line from data for test case.
        $textWidget->insert('end', $data);
        $textWidget->update;
                
}



