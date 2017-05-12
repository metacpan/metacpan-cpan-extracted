
// vim: set filetype=pp2html:

=X

\X{mode=index_only}<Tag \\X>
The \B<\\X> tag marks text to be included in an index.


\B<Syntax>

\\X<body>

\\X{mode=index_only}<body>


\B<Options>

:\B<mode>: The only allowed value for this option is \I<index_only>. This has the effect
           that the indexed text is inlucded only in the index an not in the
           current output text.

\B<Body>

The body is the string to be included in the index.


\B<Examples>

  \\X<Fortran> is an old programming language which ist
  mostly used for \\X{mode=index_only}<computations, numerical>
  numerical computations.

produces

  \X<Fortran> is an old programming language which ist
  mostly used for \X{mode=index_only}<computations, numerical>
  numerical computations.

Look at the index of this document to see, that
\I<Fortran> and \I<computations, numerical> appears in
the index.

\B<See also>

\B<\\XREF>

