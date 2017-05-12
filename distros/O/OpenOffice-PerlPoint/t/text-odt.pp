
// document description, packed into a condition for readability
? 0

 Description: A short remark.

 Format:      This file is written in PerlPoint (www.sf.net/projects/perlpoint).
              It can be translated into several documents and formats, see the
              PerlPoint documentation for details.

              The original source of this document was stored by
              OpenOffice.org/1.9.109$Win32 OpenOffice.org_project/680m109$Build-8921.

              It was converted into PerlPoint by OpenOffice::PerlPoint.

 Source:      t/text.odt.

 Author:      unknown

 Copyright:   unknown

 Version:     unknown

// start document
? 1


// ------------------------------------------------------------

// set document data
$docTitle=A first test.

$docSubtitle=Open Office docs transformed.

$docDescription=A short remark.

// ------------------------------------------------------------



.This is a first document. It starts with a text paragraph that contains so
many words that it occupies several lines. This makes it possible to see the
transformation effect in an exported format. Well, at least this is our
intention.

=A headline

.\U<And> \I<t>\B<\I<e>>\I<xt> \B<a>\B<\I<g>>\B<ain>.

.List:

*   \B<B\I<u>\I<\U<l>>let 1>

*   \I<Bul>\B<\I<l>>\I<et 2>

*   \U<Bullet 3>

==Sublevel-Chapter

.\F{color="#0000ff"}<List 2:>

*   \F{color="#ff0000"}<P 1>

*   P 2

*   \B<\I<\U<P>>> 3

.Now for some code, both \C<inline> and in a separate section.

       This stands for \I<code in an own paragraph>.
       It needs to be assigned to a named style ?Code?.
       Continued ?code?.

       We are still in the example,
       there was just a newline.

       Real code: 3\>5 ? 10 : \\\$var;

.Usual font again.

===A table

@||
Cell 1 || Cell 2
Cell 3 || Cell 4-1
Cell 5 || Cell 6
Cell 7 || Cell 8
Cell 9-1 || Cell 10
Cell 11 || Cell 12
Cell 13 || Cell 14-1
 || Cell 16
 || Cell 18
 || 

=Images

.\IMAGE{alt="Grafik1" src="t/ibd2/10000000000000640000004B8DCCCFBD.gif"}

