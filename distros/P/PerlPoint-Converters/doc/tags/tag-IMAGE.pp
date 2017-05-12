
// vim: set filetype=pp2html:

\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}


=IMAGE

\X{mode=index_only}<Tag \\IMAGE>
The \B<\\IMAGE> tag includes an image.


\B<Syntax>

\\IMAGE{options}


\B<Options>

This tag supports various options. Unless explicitly noted, all options are optional.

\I<Basic options>

These options are supported by all translators.

:\B<src>:This is the most important and therefore \B<mandatory> option, setting up
         the pathname of the image file.
         The path can be \I<relative> or \I<absolute>. Relative pathes are relative to the
         document \I<containing the tag>. (This means if documents are nested and the
         nested source contains this tag, relative pathes will still be relative to
         the path of this nested source. This way it is possible to bundle partial
         documents with their images.)
         The image file is checked for existence when the tag is parsed. A missed
         file causes a semantic error.

  // an absolute image path
  \\IMAGE{src="\B</images/>image.gif"}

  // relative image pathes
  \\IMAGE{src="image.gif"}
  \\IMAGE{src="../image.gif"}
  \\IMAGE{src="images/image.gif"}


\I<Additional options>

Several translators may extend the set of supported options.
\B<pp2html> allows also the following options which are passed to the corresponding
parameters of the HTML <IMG> tag:

:\B<alt>: Specify a textual alternative for the image.

:\B<height>: Specify the height of the image

:\B<width>: Specify the width of the image

:\B<border>: Specify border width. A useful value is "0" to suppress the border.

:\B<align>: Specify justification.



\B<Body>

No body is allowed. A used body will not be recognized as a body of this tag.


\B<Notes>

\B<\\IMAGE> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.


\B<Example>

This simple example

  Look at this \\IMAGE{src="image.gif"}.

produces something like

  Look at this \IMAGE{src="image.gif"}.


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=IMAGE}.

