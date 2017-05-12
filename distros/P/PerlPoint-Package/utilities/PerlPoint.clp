= V5 MultiLine NoSorting TabWidth=30

H=";Headlines"

H="Headline 1"
=

H="Headline 2"
==

H="Headline 3"
===

H="Headline 4"
====

H="Headline 5"
=====


H=";Lists"

H="unordered point"
* 

H="ordered point"
# 

H="continuing ordered point"
## 

H="definition"
:^&: 

H="shift right"
>^&

H="shift left"
<^&

H=";Tables"

H="simple table (paragraph)"
@^&

H="complex table (tag)"
\TABLE{separator="^&"}\n\TABLE

H=";Other paragraphs"

H="Comment"
// 

H="Verbatim block (begin)"
<<VERBATIM

H="Verbatim block (finish)"
VERBATIM

H="Variable assignment"
$ =^&

H="Macro definition"
+^&:


H=";Tags"
PerlPoint tags

H="italics"
\I<^&>

H="bold"
\B<^&>

H="code"
\C<^&>

H="figure"
\IMAGE{file="^&"}


H=";Active contents"

H="condition"
? ^&

H="embedded PerlPoint"
\EMBED{type=pp}^&\END_EMBED

H="embedded Perl"
\EMBED{type=perl}^&\END_EMBED

H="embedded ..."
\EMBED{type="..."}^&\END_EMBED

H="included PerlPoint"
\INCLUDE{lang=pp file="^&"}

H="included Perl"
\INCLUDE{lang=perl file="^&"}

H="included ..."
\INCLUDE{lang="" file="^&"}









H=";About"


H="Author"
^!INFO PerlPoint Clip Library 0.01 scripted by Jochen Stenzel (perl@jochen-stenzel.de), 2000. This script is part of the PerlPoint parser package (PerlPoint::Package) and provided under the license described therein.



