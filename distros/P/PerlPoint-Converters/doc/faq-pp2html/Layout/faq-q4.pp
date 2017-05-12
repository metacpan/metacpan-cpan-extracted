
// vim: set filetype=PerlPoint:


=Navigation Bars

\QST

How can I use \X<navigation bars>?

\ANS

Navigation bars are realized by template files. Normally they contain an
HTML table with hyperlinks to the previous and next page and to the table
of contents.  The text of the hyperlinks and the targets of the HREF tags
should be replaced with special keywords:

* URL_NEXT, TXT_NEXT

* URL_PREV, TXT_PREV

* URL_CONTENTS, TXT_CONTENTS

\B<Example:>

<<EOT
<TABLE> 
<TR>
  <TD colspan=3 >
    Next:  <a href="URL_NEXT">TXT_NEXT</a>
    &nbsp;&nbsp;Previous:  <a href="URL_PREV">TXT_PREV</a>
     &nbsp;&nbsp;Contents: <a href="URL_CONTENTS">TXT_CONTENTS</a>
  </td>
</TR>
</TABLE>
<!-- ---- Navigation Bar -------------------------------- END -->
EOT

\DSC

The navigation template file is includced in each slide on top and at the bottom
according to the following options:

* --nav_template (top and bnottom)

* --nav_top_template (top only)

* --nav_bottom_template (bottom only)

The keywords are replaced with the filenames and headers of the corresponding HTML
files.

