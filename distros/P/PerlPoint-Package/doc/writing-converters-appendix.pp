
=Appendix A: Stream directives

\I<\B<This apendix is only of interest if you plan to implement a converter with the \REF{name="The traditional approach" occasion=1 type=linked}<traditional approach>.>>

The following table describes the backends callback interfaces. The very first parameters
passed are a directive constant describing the detected items type, and a state constant
expressing the item either begins (\C<DIRECTIVE_START>) or is completed (\C<DIRECTIVE_COMPLETE>).

Although in the first design it was intended to make everything being enclosed by a start
\I<and> a completion directive, it turned out to be more pragmatic to let several very simple
tokens (and therefore stream elements) being represented by a \C<DIRECTIVE_START> flag only.
The table mentions all used flags.

If start \I<and> completion are flagged, tokens of various other types may be embedded. A
headline, for example, starts by a startup directive, embeds plain string tokens and possibly
flags, and is finally closed by  completion directive. On the other hand, tokens that only
provide a startup flag are \I<completely> represented by the token element containing the flag.
That means that plain string directives, for example, contain the string as well - nothing more
will follow. (That's easier to understand than to describe, hm.)

All parameters beginning with the third one are absolutely type specific.

If there are beginning and completing elements, all parameters will be provided at both places except where noted.

\INCLUDE{type=pp file="writing-converters-entityinterfaces.pp"}

For internal tag options (C<__option__>) passed by the parser, please refer to the parser docs.

And here is how these directives correspond to the \PP source elements. To make reading
(and writing ;-) simpler, the string \C<DIRECTIVE_> and the type specific parameters passed
to appropriate callbacks are omitted. See the table above fo those details. A directive is
illustrated by enclosing brackets.

\B<Block:>

  [BLOCK, START]

    block contents

  [BLOCK, COMPLETED]


\B<Comment:>

  [COMMENT, START]

    comment text

  [COMMENT, COMPLETED]


\B<Description list:> The "description point item" is the described thing, marked in \PP
by enclosing colons.

  [DLIST, START]
    
    [DPOINT, START]
    
       [DPOINT_ITEM, START]

         item elements (text, tags, ...)

       [DPOINT_ITEM, COMPLETED]

       [DPOINT_TEXT, START]

         description elements (text, tags, ...)
    
       [DPOINT_TEXT, COMPLETED]

    [DPOINT, COMPLETED]
    
    \I<there may be more points>

  [DLIST, COMPLETED]


\B<Document:>

  [DOCUMENT, START]

    main stream

  [DOCUMENT, COMPLETED]


\B<Document stream entry point:> This directive is extremely simple, so there
                                 is no completion directive.

  [DSTREAM_ENTRYPOINT, START]


\B<Headline:>

  [HEADLINE, START]

    headline text, tags etc.

  [HEADLINE, COMPLETED]


\B<List shifts:> Because these directives are extremely simple, there
                 are no completion directives.

  [LIST_LSHIFT, START]

-

  [LIST_RSHIFT, START]



\B<Ordered list:>

  [OLIST, START]
    
    [OPOINT, START]
    
      point contents
    
    [OPOINT, COMPLETED]
    
    \I<there may be more points>

  [OLIST, COMPLETED]



\B<Plain text:> the parser tries to provide as much text together as possible. Nevertheless,
there's no guarantee that a certain string sequence will be provided by a certain stream
sequence of simple token directives. Whatever way a simple token sequence \I<is> provided,
joining their contents by empty strings will result in the original string sequence.

  [SIMPLE, START]



\B<Tag:>

  [TAG, START]

    tagged things

  [TAG, COMPLETED]


\B<Text:>

  [TEXT, START]

    text

  [TEXT, COMPLETED]


\B<Unordered list:>

  [ULIST, START]
    
    [UPOINT, START]
    
      point contents
    
    [UPOINT, COMPLETED]
    
    \I<there may be more points>

  [ULIST, COMPLETED]



\B<Verbatim block:>

  [VERBATIM, START]

    block contents

  [VERBATIM, COMPLETED]


