
// vim: set filetype=pp2html:

=PAGEREF

\X{mode=index_only}<Tag \\PAGEREF>
The \B<\\PAGEREF> tag is used to make a reference to another page of the same document.
The text used for this reference is the chapter number of this page.


\B<Syntax>

\\PAGEREF{name="page-header"}


\B<Options>

:\B<name>: The value of this parameter must be a page header as used in the = paragraphs.\BR
    \B<Note:> The page number is the chapter number which reflects the hierarchical position of the
    page within the document, e. g. \B<2.5.4.3>


\B<Body>

No body is allowed.


\B<Example>

  The C tag is explaned in chapter \\PAGEREF{name="C"}.

produces

  The \C<\\C> tag is explained in chapter \PAGEREF{name="C"}.

\B<See also>

\B<\\SECTIONREF>, \B<\\XREF>, \B<\\L>

