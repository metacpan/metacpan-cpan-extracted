
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=HIDE

\X{mode=index_only}<Tag \\HIDE>
erases everything within its body. This is intended to help in writing
documents parts which shall be used in various contexts. With hide and
\I<tag conditions> it becomes very easy to let \I<parts> of a paragraph
disappear (while condition paragraphs do the same for complete document
sections of multiple paragraphs).


\B<Syntax>

\\HIDE{options}<body>


\B<Options>

This tag supports \I<no> options of its own. It just accepts
options to allow users to make the tag conditional (by a tag
condition specified with option \C<_cnd_>).



\B<Body>

The paragraph parts to be hidden.



\B<Notes>

\B<\\HIDE> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.

\B<\\HIDE> is intended to make \I<parts> of a paragraph conditional. To make the integration
of complete sections of a document depending on conditions, use \I<condition paragraphs>.

While a hidden tag body disappears in the result, \I<Active Content> in the body
\I<is> evaluated during parsing (due to the used parsing method). This means that
if hidden Active Contents has side effects these effects \I<will> happen.



\B<Example>

Hide something unless is is explicitly allowed.

  Last years efforts were a great success.
  \B<\\HIDE{_cnd_=internalConference}<But we
  exceeded the limits of our budget.\>>


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=HIDE}.

