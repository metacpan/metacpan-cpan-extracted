
@|
1: type directive                 | 2: used flags (modes)                        | 3...: more parameters
\BC<DIRECTIVE_BLOCK>              | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_COMMENT>            | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_DLIST>              | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | a reserved parameter, two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_DOCUMENT>           | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | (base)name of source file
\BC<DIRECTIVE_DPOINT>             | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | a reserved parameter, two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_DPOINT_ITEM>        | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_DSTREAM_ENTRYPOINT> | \C<DIRECTIVE_START>                          | stream name
\BC<DIRECTIVE_HEADLINE>           | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | Headline level. The full headline title (tags stripped off), a short version of the title and a reference to an array of docstreams used in this chapter are provided additionally in the startup directive \I<only>. (If no short title version (or "shortcut") was specified, an empty string is provided.)
\BC<DIRECTIVE_LIST_LSHIFT>        | \C<DIRECTIVE_START>                          | number of levels to shift
\BC<DIRECTIVE_LIST_RSHIFT>        | \C<DIRECTIVE_START>                          | number of levels to shift
\BC<DIRECTIVE_NEW_LINE>           | \C<DIRECTIVE_START>                          | a hash reference: key "file" provides the current source file name, key "line" the new line number
\BC<DIRECTIVE_OLIST>              | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | A prefered startup number (defaults to 1). Two parameters describing type and level of a preceeding list shift if any (0 otherwise, only provided in \I<start> directives), two parameters describing type and level of a following list shift if any (0 otherwise, only provided in \I<completion> directives)
\BC<DIRECTIVE_OPOINT>             | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_SIMPLE>             | \C<DIRECTIVE_START>                          | a list of strings
\BC<DIRECTIVE_TAG>                | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | First, the tag name, then a reference to a hash of tag options taken from the source, then the number of stream parts following for the body (0 means: no tag body). \I<Tag options in the open directive might have been modified by a tag finish hook and therefore differ from the options provided in the closing directive, which reflects the original options (before finish hook invokation).>
\BC<DIRECTIVE_TEXT>               | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_ULIST>              | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_UPOINT>             | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
\BC<DIRECTIVE_VARRESET>           | \C<DIRECTIVE_START>                          | -
\BC<DIRECTIVE_VARSET>             | \C<DIRECTIVE_START>                          | a hash reference: key "var" provides the variables name, key "value" the new value
\BC<DIRECTIVE_VERBATIM>           | \C<DIRECTIVE_START>, \C<DIRECTIVE_COMPLETE>  | -
