
// vim: set filetype=PerlPoint:


=Target in Top Level Window

\QST

How can I achieve that a hyperlink presents the new page or frame set in the
\X<top level window> ?

\ANS

You can use the \I<target> option of the \C<\\L> tag:

 \\L{url="../FAQ-pp2html-slides/frame_set.html" \B<target=_top>}<pp2html FAQ>

\DSC

If you use an \C<\\L> tag in a page which is part of a frame set, then the target page
is noramlly displayed in the same frame where the hyperlink was located. If you want
the target to be displayed in the top level window of the browser, you should use
\C<target=_top>. The \C<target=_blank> option presents the new page in a \X<new browser
window>.
