
// vim: set filetype=pp2html:

=A

\X{mode=index_only}<Tag \\A>
The \B<\\A> tag is used to set an \I<\X<anchor>> or an invislible \I<mark> within the input text.
This can then be used in \C<\\XREF> tags to create cross references.

\B<Syntax>

\\A{name="some name for this anchor"}

\B<Options>

:\B<name>:The \I<name> option is mandatory and specifies a name for this anchor. All anchor names within a
          document must be unique.\BR
           \B<Note:> For each page header there is an anchor tag created autmatically which
           uses the page header as name.

\B<Body>

No body is allowed.

\B<Example>

  This text contains an \\A{name="a-name"}invisible anchor.

produces

  This text contains an \A{name="a-name"}invisible anchor.

This anchor can be used in a cross reference like:

  See also the \\XREF{name="a-name"}<anchor example>.

which produces:

  See also the \XREF{name="a-name"}<anchor example>.

\B<See also>

\B<\\XREF>

