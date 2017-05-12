
// include macro definitions shared by all basic tag docs
\INCLUDE{type=pp file="basic-tag-macros.pp" smart=1}


=LOCALTOC

\X{mode=index_only}<Tag \\LOCALTOC>
inserts a list of current subchapters, which means a list of the plain
subchapter titles. This is especially useful at the beginning of a
fine structured document section, or on an introduction page where you
want to preview what the audience can expect in the following talk section.

Using this tag relieves you from writing and maintaining such a list manually.


\B<Syntax>

\\LOCALTOC{options}


\B<Options>

This tag supports various options. All options are optional and default to
values mentioned in their descriptions.

:\B<depth>: Subchapters may have subchapters as well. By default,
            the whole tree is displayed, but this can be limited
            by this option. Pass the \I<number> of sublevels that
            shall be included. The lowest possible value is \C<1>.
            Invalid option values will cause syntax errors.

             Consider you are in a \I<level 1> headline
             with these subchapters:

             ==Details 1

             ==Details 2

             ===Details 2 explained

             ===Details 2 furtherly explained

             ==Conclusion

             Depth \C<1> will result in listing "Details 1",
             "Details 2" and "Conclusion". Depth \C<2> or
             greater will add the explanation subchapters
             of level 3.

Note that the option expects an \I<offset> value. The list depth is
independend of the \I<absolute> levels of subchapters. This way,
your settings will remain valid even if absolute levels change (which
might happen when the document is included, for example).

:\B<format>: This setting configures what kind of list will be generated.
             The following values are specified:

@|
setting        | result
\B<bullets>    | produces an \I<unordered> list
\B<enumerated> | produces an \I<ordered> list
\B<numbers>    | produces a list where each chapter is preceeded by its chapter number, according to the documents hierarchy (\C<1.1.5>, \C<2.3.> etc.)

If this option is omitted, the setting defaults to \C<bullets>.


\B<type>: \B<\I<linked>> makes each listed subchapter title a link to the
          related chapter. \I<Note that this feature depends on the target
          formats link support, so results may vary.>

By default, titles are displayed as \I<plain text> - \B<\I<plain>>
can be used to specify this explicitly.



\B<Body>

No body is allowed. A used body will not be recognized as a body of this tag.


\B<Notes>

\B<\\LOCALTOC> is part of the \I<basic tag set> supported by \I<all> PerlPoint translators.
The results may vary depening on the target format capabilities.

\B<Example>

When this tag is used in

  =Parent chapter

  In this chapter:

  \B<\\LOCALTOC{depth=1}>

  ==Subchapter 1

  ===Subchapter 1.1

  ==Subchapter 2

, a converter will produce results according to \I<this> source:

  =Parent chapter

  In this chapter:

  \B<* Subchapter 1>

  \B<* Subchapter 2>

  ==Subchapter 1

  ==Subchapter 2



\B<See also>

More basic set tags: \OTHER_BASIC_TAGS{current=LOCALTOC}.

