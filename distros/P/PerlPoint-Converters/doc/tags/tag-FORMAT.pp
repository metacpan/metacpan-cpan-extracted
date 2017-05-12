
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=FORMAT

\X{mode=index_only}<Tag \\FORMAT>
is a container tag to configure result formatting. Configuration
settings are received via tag options and are intended to remain
valid until another modification. For example, one may set the
default text color of examples to green. This would remain valid
until the next text color setting.

Please note that this tag is very general. Accepted options and
their meaning are defined by the \I<converters>. Nevertheless,
certain settings are commonly used by convention, these are the
options documented here.


\B<Syntax>

\\FORMAT{options}


\B<Options>

As mentioned before, accepted options are defined by the converters.
Please refer to a specific converters documentation to find out which
settings it supports.

The following options are commonly used which means they are \I<accepted>
by all converters. \B<This does not necessarily mean that a certain
converter \I<supports> them all.> Again, please see the converters
documentation for details.


:\B<align>:Specifies alignment of text, which means the content of
           text paragraphs and table cells. Valid values are \C<left>,
           \C<center>, \C<justify> and \C<right> (which should be self
           explaining).



\B<Body>

No body is allowed. A used body will not be recognized as a body of this tag.



\B<Notes>

\B<\\FORMAT> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.



\B<Example>

Check parser version for meeting special needs:

  // use block justification
  \B<\\FORMAT{align=justify}>

  ...

  ...

  // back to left justification
  \B<\\FORMAT{align=left}>


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=FORMAT}.

