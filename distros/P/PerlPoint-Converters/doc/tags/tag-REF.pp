
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=REF

\X{mode=index_only}<Tag \\REF>
This is a very general and highly configurable reference.
It can be used both to make linked and unlinked references,
it can fallback to alternative references if necessary,
and it can finally be that optional that the specified
reference does not even has to exist.


\B<Syntax>

\\REF{options}

\\REF{options}<body>


\B<Options>

This tag supports various options. Several of them are optional
and default to values mentioned in their descriptions.


:\B<name>: specifies the name of the target anchor.
           A missing link is an error unless \C<occasion>
           is set to a true value or an \C<alt>ternative
           address can be found.

:\B<type>: configures which way the result should be produced.

>

* \I<\C<linked>:> The result is made a link to the referenced object.

* \I<\C<plain>:>  This is the default formatting and means that
                  the result is supplied as plain text.

<

:\B<alt>: If the anchor specified by \C<name> cannot be found,
          the tag will try all entries of a comma separated list
          specified by this options value. (For readability,
          commata may be surrounded by whitespaces.) Trials
          follow the listed link order, the first valid address
          found will be used.

:\B<occasion>: If the tag cannot find a valid address (either
               by \C<name> or by trying \<alt>), usually an
               error occurs. By setting this option to a true
               value a missing link will be ignored. The result
               is equal to a \I<non specified> \C<\\REF> tag.


\B<Body>

If there's a body, the resulting text will be built by the body content,
otherwise by the \I<value> of the referenced object. The value of a
referenced object highly depends on its construction method. Please
refer to the specific elements documentation for details or just
find it out be a trial.

  Headline anchors made by the parser have an value
  of the "headline string", which means the pure title
  without any included tags.

  Sequence numers made by \C<\\SEQ> are evaluated
  with the respective numbers.

The body is optional as long as formatting is not set to \C<plain>
because in this case there would be two concurrencing result texts
- the reference value \I<and> the body content. That's why a body
is \I<forbidden> if option \C<type> is set to \C<plain>.


\B<Notes>

\B<\\REF> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.
The results may vary depening on the target format capabilities.

\B<Example>

Here are several sequence numbers, partially declared in a conditional
document part:

  ? $slides and $longShow

  \\SEQ{type=image name=mountains}

  ? $slides

  \\SEQ{type=image name=hills}

The numbers produced may be \C<1> and \C<2>.
And here are various ways to reference one of them:

@|
use                                                                       | result
\C<\\REF{name=mountains}>                                                 | \C<1>, plain text
\C<\\REF{name=mountains type=plain}>                                      | \C<1>, plain text
\C<\\REF{name=mountains type=linked}>                                     | \C<1>, a link to the "mountains" number
\C<\\REF{name=mountains type=linked}<Mountains\>>                         | \C<Mountains>, a link to the "mountains" number
\C<\\REF{name=mountains alt="hills"}>                                     | \C<1>, plain text, in any case
\C<\\REF{name=mountains alt="hills" type=linked}<Mountains\>>             | \C<Mountains>, a link to the "mountains" number if $slides and $longShow are set, a link to the "hills" number if only $slides is set, and an error otherwise
\C<\\REF{name=mountains alt="hills" type=linked occasion=1}<Mountains\>> | \C<Mountains>, a link to the "mountains" number if $slides and $longShow are set, a link to the "hills" number if only $slides is set, and just \C<Mountains> otherwise



\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=REF}.

