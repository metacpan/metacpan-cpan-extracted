
// vim: set filetype=pp2html:

=XREF

\X{mode=index_only}<Tag \\XREF>
The \B<\\XREF> tag is used to make a cross reference to another page of the same document.
The text used for this reference is the body of this tag whereas the target is
specified by the \I<name> option.


\B<Syntax>

\\XREF{name="page-header"}<reference text>


\B<Options>

:\B<name>: The value of this parameter must be a valid anchor name.
           \B<Note:> For each page header there is an anchor tag created autmatically which
           uses the page header as name.


\B<Body>

The body is the text which is used as hyperlink text for this cross reference.


\B<Example>

  See the chapter \\XREF{name="C"}<about the \\C tag>.

produces

  See the chapter \XREF{name="C"}<about the \\C tag>.

\B<See also>

\B<\\A>, \B<\\SECTIONREF>, \B<\\PAGEREF>, \B<\\L>

