
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}



=STOP

\X{mode=index_only}<Tag \\STOP>
raises an syntactical error and thereby terminates document processing
immediately. This is especially useful when used in conjunction with
\I<tag conditions>, to express that a document should be processed in
certain circumstances only.


\B<Syntax>

\\STOP{options}


\B<Options>

This tag supports \I<no> options of its own. It just accepts
options to allow users to make the tag conditional (by a tag
condition specified with option \C<_cnd_>).



\B<Notes>

\B<\\STOP> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.



\B<Example>

Check parser version for meeting special needs:

  \\STOP{_cnd_="\$_PARSER_VERSION<0.36"}


\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=STOP}.

