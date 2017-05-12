
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=SEQ

\X{mode=index_only}<Tag \\SEQ>
Inserts the next value of a certain numerical sequence.
Numerical sequences are all over there in typical documents,
think of table numbers, image numbers and so on.

Optionally, the generated number can be made an \I<anchor>
to reference it at another place.


\B<Syntax>

\\SEQ{options}


\B<Options>

This tag supports various options. Several of them are optional
and default to values mentioned in their descriptions.

:\B<type>: This specifies the sequence the number shall
           belong to. If the specified string is not already
           registered as a sequence, a new sequence is opened.
           The first number in a new sequence is \C<1>. If
           the sequence is already known, the next number in
           it will be supplied.


:\B<name>: If passed, this option sets an anchor name. This
           makes it easy to reference the generated number
           at another place (by \C<\REF{occasion=1 name=REF
           type=linked}<\\REF>> or another referencing tag).
           The value of such a link is the sequence number.
           By default, no anchor is generated.


\B<Body>

No body is accepted. A used body will not be recognized as a tag body.


\B<Notes>

\B<\\SEQ> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.
The results may vary depening on the target format capabilities.

\B<Example>

Say "1, 2, 3":

  \\SEQ{type=example}, \\SEQ{type=example}, \\SEQ{type=example}

Number an image and make the number referencable:

  \\SEQ{type=images name="Blue sea"}


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=SEQ}.

