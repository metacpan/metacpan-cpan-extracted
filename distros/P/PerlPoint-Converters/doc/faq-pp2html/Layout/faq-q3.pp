
// vim: set filetype=PerlPoint:


=Center Paragraphs and Images

\QST

How can I \X<center> a paragraph or an image?

\ANS

Define macros which use embeded HTML to do the job:

 +CENTER_ON:\\EMBED{lang=HTML}<CENTER>\\END_EMBED

 +CENTER_OFF:\\EMBED{lang=HTML}</CENTER>\\END_EMBED

\DSC


Define the macros in a spceial file which can be included with the
\\INCLUDE tag or define them just at the beginning of your main PerlPoint
file. Then you can use them in the following way:

 \\CENTER_ON

 some text

 \\IMAGE{src="cool_img.gif"}

 \\CENTER_OFF

+CENTER_ON:\EMBED{lang=HTML}<CENTER>\END_EMBED

+CENTER_OFF:\EMBED{lang=HTML}</CENTER>\END_EMBED

\CENTER_ON

This text should be centered ...

\CENTER_OFF

