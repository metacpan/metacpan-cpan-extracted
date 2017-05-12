
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=READY

\X{mode=index_only}<Tag \\READY>
The \B<\\READY> tag instructs PerlPoint to ignore remaining parts of a document.


\B<Syntax>

\\READY


\B<Options>

No options are allowed. Used options will not be recognized as belonging to this tag.

\B<Body>

No body is allowed. A used body will not be recognized as a body of this tag.


\B<Notes>

\B<\\READY> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.


\B<Example>

In this example, \B<\\READY> is used to process just a small portion of a source,
e.g. to build an overview:

 ? flagSet(overviewMode)

 \\B<Short Overview>

 This document will give you an impression.

 // ready in overview mode
 \B<\\READY>

 ? 1

 // usual document


\B<Notes>

The behaviour of this tag is still subject to changes. Currently, not even the
current paragraph will become part of the result. That's why it s recommended
to use it in a line of its own (as demonstrated by the example).


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=TABLE}.

