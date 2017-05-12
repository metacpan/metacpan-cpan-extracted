
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=TABLE and END_TABLE

\X{mode=index_only}<Tag \\TABLE, \\END_TABLE>
\B<\\TABLE> \I<opens> a table, \B<\\END_TABLE> closes it.


\B<Syntax>

\\TABLE{options}...\\END_TABLE


\B<Options>

There are several options of \I<two categories>. All options in the following table are
supported by \I<all> converters. Additionally, there can be \I<converter specific> options
only recognized by certain converters.

@|
option           | description
\C<separator>    | a string separating the table \I<columns> (can contain more than one character)
\C<rowseparator> | a string separating the table \I<rows> (can contain more than one character)
\C<gracecr>      | usually set correctly by default, this specifies the number of row separators to be ignored before they are treated as separators - which usually allows to start the table contents in a subsequent line \I<after> the line containing the \C<\\TABLE> tag


\B<Body>

Both tags have no bodies. Used bodies will not be recognized as tag bodies but as plain
text following a tag.

Different to most other tags, \C<\\TABLE> only \I<opens> a new document part. The table
has to be closed by \C<\\END_TABLE> \I<explicitly>.


\B<Discussion>

These tags are sligthly more powerfull than the table \I<paragraph> syntax: you can set
up several table features like the border width yourself, and you can format the headlines as you like.

The usual usage is 

<<EOE

  \TABLE{separator="|"}

  \B<column 1>  |  \B<column 2>  | \B<column 3>
     aaaa       |     bbbb       |  cccc
     uuuu       |     vvvv       |  wwww

  \END_TABLE

EOE

The \C<separator> option is even optional because columns are separated by "|" \I<by default>.
So you could write

  \\TABLE

  \\B<column 1> |  \\B<column 2> | \\B<column 3>
     aaaa       |     bbbb       |  cccc
     uuuu       |     vvvv       |  wwww

  \\END_TABLE

as well.


\I<Inlining>

By default, all enclosed lines are evaluated as table rows, which means that
each source line between \C<\\TABLE> and \C<\\END_TABLE> is treated as a table
row. Alternatively, PerlPoint allows you to separate rows by a string of your
\I<own> choice using option \C<rowseparator>. This allows to specify a table
\I<inlined> into a paragraph.

<<EOE

  \TABLE{bg=blue separator="|" border=2 rowseparator="+++"}
  \B<column 1> | \B<column 2> | \B<column 3> +++ aaaa
  | bbbb | cccc +++ uuuu | vvvv|  wwww \END_TABLE

EOE

This is exactly the same table as in the example section above.


\I<Nesting>

Inlining tables enables us to \I<nest> them as well. In fact, it depends on the
converter features if this feature is enabled, it is \I<blocked> \I<by default>
because there might be target languages which do \I<not> support table nesting.

Nested tables look like this:

  \\TABLE{rowseparator="+++"} column 1 | column 2 |
  \B<\\TABLE{rowseparator="%%%"} n1 | n2 %%% n3 | n4 \\END_TABLE>
  +++ xxxx | yyyy | zzzzz +++ uuuu | vvvv | wwwww \\END_TABLE


\I<Trimming>

Similar to table paragraphs, leading and trailing whitespaces of a cell are
automatically removed, so you can use as many of them as you want to
improve the readability of your source.


\I<Normalization>

Tables are \I<normalized> automatically, which means that all table rows will
be provided with the same number of columns as the first table row (or "table headline").


\B<Notes>

\B<\\TABLE> is supported by \I<all> PerlPoint translators.


\B<Examples>

See \I<discussion> above.


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=TABLE}.

