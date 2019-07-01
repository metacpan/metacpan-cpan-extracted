use strict;


package Tcl::pTk::Entry;

our ($VERSION) = ('1.02');

# Entry widget is all auto-wrapped. 
# This File primarily needed to keep from getting the double-paste problem seen, where pasting into an
#  Entry will paste the text twice, due to the standard class initialization calling the Clipboard classinit, 
#   which sets up bindings using the class name (i.e. Tcl::pTk::Entry), where Tcl/Tk has already setup bindings using the 
#   Tcl/Tk name (i.e. Entry). 
#  This removes clipboard from the inheritance, so its initialization doesn't get called

use base  qw(Tcl::pTk::Widget);



1;

