
// vim: set filetype=pp2html:

=F

\X{mode=index_only}<Tag \\F>
The \B<\\F> tag allows to change parameters of the font, e. g. color or size.


\B<Syntax>

\\F{color=\I<colorvalue> size=\I<sizevalue> face=\I<typeface>}<body>


\B<Options>

:\B<color>:This option changes the text color. Values can be symbolic names like
           \I<red>, \I<blue>, \I<yellow> or RGB specifications like \C<"#CC0000">.

:\B<size>: Use "+2", "-1", "4" etc. as values for this option. The values are passed
           to the corresponding parameter of the HTML <FONT> tag.

:\B<face>: Use a valid type face name as value for this option. The value is passed
           to the corresponding parameter of the HTML <FONT> tag.

\B<Body>

The body is the string to be formatted.


\B<Example>

  This text is \\F{color=red face="Times"}<colored>.

produces

  This text is \F{color=red face="Times"}<colored>.


\B<See also>

\B<\\SUP>, \B<\\SUB>, \B<\\U>

