
// vim: set filetype=pp2html:

=SECTIONREF

\X{mode=index_only}<Tag \\SECTIONREF>
The \B<\\SECTIONREF> tag is used to make a reference to another page of the same document.
The text used for this reference is the page header of this page.


\B<Syntax>

\\SECTIONREF{name="page-header"}


\B<Options>

:\B<name>: The value of this parameter must be a page header as used in the = paragraphs.


\B<Body>

No body is allowed.


\B<Example>

  The C tag is explaned in chapter \\SECTIONREF{name="C"}.

produces

  The \C<\\C> tag is explained in chapter \SECTIONREF{name="C"}.

\B<See also>

\B<\\PAGEREF>, \B<\\XREF>, \B<\\L>

