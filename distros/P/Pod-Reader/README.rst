podreader - A curses TUI to read Perl POD from.

podreader is a curses TUI that displays a list of Perl modules. When a module is
selected, the perldoc(1) command is called to display its documentation.

********
SYNOPSIS
********


podreader [-hm] [/dir1 /dir2 ...]


.. code-block:: perl

   -m|--man          display man page
   -h|--help         display help
 
   [directory list]  search .pm files in given directories (optional)
 
   podreader looks for .pm files in @INC by default.



**********
KEYSTROKES
**********


Use the following keystrokes to navigate around the UI.


- Up/Down/j/k
 
 Move the cursor up or down.
 


- Enter/Space/l
 
 Confirm selection.
 


- Ctrl+q
 
 Quit the UI.
 


- /
 
 Small search box to look for a module in the list. Type a string and hit enter.
 


- n or N
 
 Go to the next/previous result in the list (if any).
 



*****
MOUSE
*****


Mouse support is enabled and should work. Click on a file in the list to
display its documentation (if it exists of course).


********
SEE ALSO
********


perldoc(1)


******
AUTHOR
******


Patrice Clement <monsieurp at cpan.org>


*********************
LICENSE AND COPYRIGHT
*********************


This software is copyright (c) 2021 by Patrice Clement.

This is free software, licensed under the (three-clause) BSD License.

See the LICENSE file.

