
// vim: set filetype=PerlPoint:


=Creating a New Frameset

\QST

How can I set up a frameset with only two frames?

\ANS

If you want to have a \X<frameset> which is different from the
predefined framesets in the \I<p2htm_styles> directory, you must
create a new frameset template together with some templates for
top and/or bottom frame.

After testing your new frameset you could make it into a new
\I<style> which could then easily be used for future documents.

\DSC

There must be one frame which displays the contents of the
slides. This is the \I<Data> frame. It \B<must> have this name. 
Other frames may be used to display a company logo or a permanent 
navigation bar. There are two other names which are reserved:
\I<Top> and \I<Bottom>.

Creating a new style is described in more detail in 
\SECTIONREF{name="Creating a New Style"}.

