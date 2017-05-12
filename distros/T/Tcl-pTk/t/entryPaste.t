
use strict;
use Test;
use Tcl::pTk; 

# Test to make sure entry copy/paste works correctly. 
#  This was originally made to check for the double-paste problem for Entry widgets, where the
#    text would get pasted twice into the entry.

plan tests => 1;

my $TOP = MainWindow->new();



    my(@relief) = qw/-relief sunken/;
    my(@pl) = qw/-side top -padx 10 -pady 5 -fill x -expand 1/;
    my $e1 = $TOP->Entry(@relief)->pack(@pl);
    my $e2 = $TOP->Entry(@relief)->pack(@pl);

    $e1->insert('end', 'Entry1');

    # Give e1 the focus and select, then copy
    $e1->focus;
    $e1->selectionRange('0', 'end');
    $e1->eventGenerate('<<Copy>>');
    
    # Now give e2 the focus, select, then paste
    $e2->focus();
    $e2->selectionRange('0', 'end');
    $e2->eventGenerate('<<Paste>>');
    
    my $e2Text = $e2->get();
    
    ok( $e2Text, 'Entry1', "Entry Paste Successfull");
    

MainLoop if( @ARGV); 
