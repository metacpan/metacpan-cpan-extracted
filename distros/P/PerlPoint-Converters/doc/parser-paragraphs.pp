

==Paragraphs in general

All paragraphs start at the beginning of their first line. The first character
or string in this line determines which paragraph is recognized.

A paragraph is completed by an empty line (which may contain whitespaces).
Exceptions are described.

Carriage returns in paragraphs which are completed by an empty line
are transformed into a whitespace


==Comments

start with \B<"//"> and reach until the end of the line.

  // example comment


==Headlines

start with one or more \B<"="> characters.
The number of "=" characters represents the headline level.

  =First level headline

  ==Second level headline

  ===Multi
    line
   headline
  example


==Texts

begin \I<immediately> without a special startup character:

  This is a simple text.

  In this new text paragraph,
  we demonstrate the multiline feature.


==Blocks

are intended to contain examples or code \I<with> tag recognition.
This means that the parser will discover embedded tags. Blocks
begin with an \I<indentation> and are completed by the next empty line.

  * Look at these examples:

      A block.

      \I<Another> block.
      Escape ">" in tags: \\C<<\B<\\\>>>.

  Examples completed.

Subsequent blocks are joined together automatically: the intermediate empty
lines which would usually complete a block are translated into real empty
lines \I<within> the block. This makes it easier to integrate real code
sequences as one block, regardless of the empty lines included. However,
one may explicitly \I<wish> to separate subsequent blocks and can do so
by delimiting them by a special control paragraph:

  * Separated subsequent blocks:

      The first block.

  -

      The second block.

Note that the control paragraph starts at the left margin.


==Verbatim blocks

are similar to blocks in indentation but \I<deactivate>
pattern recognition. That means the embedded text is not scanned for tags
and empty lines and may therefore remain as it was in its original place,
possibly a script.

These special blocks need a special syntax. They are implemented as \I<here documents>.
Start with a here document clause flagging which string will close the paragraph:

<<EOE
  <<EOC

    # compare (\I<tags> have not to be escaped)
    $rc=3>2?4:5;

  EOC
EOE


==Lists

\B<Unordered lists> start with a \B<"*"> character.

  * This is a first point.

  * And, I forgot,
    there is something more to point out.

There are \B<ordered lists> as well, and \I<they> start with a hash sign (\B<"#">):

  # First, check the number of this.

  # Second, don't forget the first.

The hash signs will be automatically replaced by numbers.

Because PerlPoint works on base of paragraphs, any paragraph different to
an ordered list point \I<closes an ordered list>. If you wish the list to
be continued use a double hash sign in case of the single one in the point
that reopens the list.

  # Here the ordered list begins.

  ? $includeMore

  \B<##> This is point \I<2> of the list that started before.
     Without the second "#" character this point would start
     a new list.

  # In subsequent points, the usual single hash sign works as
    expected again.

List continuation works list level specific (see below for level details).
A list cannot be continued in another chapter. Using \C<##> in the first
point of a new list takes no special effect: the list will begin as usual
(with number 1).

\B<Definition lists> are a third list variant. Each item starts with the
described phrase enclosed by a pair of colons, followed by the definition
text:

  :first things: are usually described first,

  :others:       later then.

Definition items can be formatted as usual:

<<EOE
  :A \I<formatted> item: is an item \I<formatted> by tags.
EOE

All lists can be \I<nested>. A new level is introduced by
a special paragraph called \I<"list indention"> which starts with a \B<"\>">. A list level
can be terminated by a \I<"list indention stop"> paragraph containing of a \B<"\<">
character. (These startup characters symbolize "level shifts".)

  * First level.

  * Still there.

  >

  * A list point of the 2nd level.

  <

  * Back on first level.


You can decide to shift more than one level at once. The number of shifted levels
is passed immediately after the directive character ("<" or ">", respectively):

  * First level.

  >2

  * A list point of the 3rd level.

  <2

  * Back on first level.


Level shifts are accepted between list items \I<only>.


==Tables

are supported in a paragraph form, they start with an \B<"@"> character which is
followed by the column delimiter:

  @|
   column 1   |   column 2   |  column 3
    aaa       |    bbb       |   ccc
    uuu       |    vvvv      |   www

The first line of such a table is automatically formatted as \I<table headline>.

If a table row contains less columns than the table headline, the "missed"
columns are automatically added. This is,

  @|
  A | B | C
  1
  1 |
  1 | 2
  1 | 2 |
  1 | 2 | 3

is streamed exactly as

  @|
  A | B | C
  1 |   |
  1 |   |
  1 | 2 |
  1 | 2 |
  1 | 2 | 3

to make backend handling easier. (Empty HTML table cells, for example, are rendered
slightly obscure by certain browsers unless they are filled with invisible characters,
so a converter to HTML can detect such cells because of normalization and handle them
appropriately.)

Please note that normalization refers to the headline row. If another line contains
\I<more> columns than the headline, normalization does not care.

In all tables, leading and trailing whitespaces of a cell are
automatically removed, so you can use as many of them as you want to
improve the readability of your source. The following table is absolutely
equivalent to the last example:

  @|
  A                |       B         |      C
  1                |                 |
   1               |                 |
    1              | 2               |
     1             |  2              |
      1            | 2               |      3

There is also a more sophisticated way to describe tables, see the \I<tag> section.


==Conditions

start with a  \B<"?"> character. If \I<active contents> is enabled, the paragraph text
is evaluated as \I<Perl code>. The (boolean) evaluation result then determines if
subsequent PerlPoint is read and parsed. If the result is false, all subsequent
paragraphs until the next condition are \I<skipped>.

This feature can be used to maintain various language versions of a presentation
in one source file:

  ? $PerlPoint->{userSettings}{language} eq 'German'

Or you could enable parts of your document by date:

  ? time>$main::dateOfTalk

Please note that the condition code shares its variables with \I<embedded> and \I<included>
code.

To make usage easier and to improve readability, condition code is evaluated with
disabled perl warnings (the language variable in the example above may not even been set).


==Variable assignments

Variables can be used in the PerlPoint text and will be automatically replaced by their string
values (if declared).

  The next paragraph sets a variable.

  $var=var

  This variable is set to $var.

All variables are made available to \I<embedded> and \I<included> Perl code as well as to
\I<conditions> and can be accessed there as package variables of "main::". Because a
variable is already replaced by the parser if possible, you have to use the fully
qualified name or to guard the variables "$" prefix character to do so:

<<EOE
  \EMBED{lang=perl}join(' ', $main::var, \$var)\END_EMBED
EOE

Variable modifications by embedded or included Perl \I<do not> affect the variables
visible to the parser. (This includes condition paragraphs.) This means that

<<EOE
  $var=10
  \EMBED{lang=perl}$main::var*=2;\END_EMBED
EOE

causes \C<\$var> to be different on parser and code side - the parser will still use a
value of 10, while embedded code works on with a value of 20.

Translator software \I<can> make additional use of variables, especially predeclare
certain settings (such variables are usually capitalized). Please see your converters
documentation for details.


==Macro definitions

Sometimes certain text parts are used more than once. It would be a relieve
to have a shortcut instead of having to insert them again and again. The same
is true for tag combinations a user may prefer to use. That's what \I<aliases>
(or "macros") are designed for. They allow a presentation author to declare
his own shortcuts and to use them like a tag. The parser will resolve such aliases,
replace them by the defined replacement text and work on with this replacement.


===Basic definition

An alias declaration starts with a \B<"+"> character followed \I<immediately> by the
alias \I<name> (without backslash prefix), followed \I<immediately> by a colon.
(No additional spaces here.) \I<All text after this colon up to the paragraph
closing empty line is stored as the replacement text.> So, whereever you will
use the new macro, the parser will replace it by this text and \I<reparse> the result.
This means that your macro text can contain any valid constructions like tags or
other macros.

The replacement text may contain strings embedded into doubled underscores like
\C<__this__>. This is a special syntax to mark that the macro takes parameters
of these names (e.g. \C<this>). If a tag is used and these parameters are set,
their values will replace the mentioned placeholders. The special placeholder
\C<__body__> is used to mark the place where the macro body is to place.

Here are a few examples:

<<EOE

  +RED:\FONT{color=red}<__body__>

  +F:\FONT{color=__c__}<__body__>

  +IB:\B<\I<__body__>>

  This \IB<text> is \RED<colored>.

  +TEXT:Macros can be used to abbreviate longer
  texts as well as other tags
  or tag combinations.

  +HTML:\EMBED{lang=html}

  Tags can be \RED<\I<nested>> into macros. And \I<\F{c=blue}<vice versa>>.
  \IB<\RED<This>> is formatted by nested macros.
  \HTML This is <i>embedded HTML</i>\END_EMBED.

  Please note: \TEXT

EOE


===Option defaults

If an option is declared but unused, it defaults to an empty string unless
the definition declared a default value itself by using an assignment list
after the macro name.

  +MACRO\B<{\I<value>="default value"}>:value is \B<__value__>

Please note that the default assignment uses the \I<real> option name, no
placeholder.

As long as the option is set in the macro call, the passed value will be used:

  Now I'm using the macro the usual way, \MACRO{value=passed}.

But if the option is omitted, PerlPoint falls back to the stored default value:

  Using this macro the convenient way: \MACRO.

Default assignment lists are syntactically similar to the ones used in tag and
macro \I<calls>, so it is possible to make various settings.

  +MACRO{\B<a=1 b=2 c=3>}:sum(__a__, __b__, __c__)
  
Setting a default value for an option not declared in the macros replacement
text takes no effect and is silently ignored.


===Recognition

\I<If no parameter is defined in the macro definition, options will not be recognized.>
The same is true for the body part. \I<Unless \C<"__body__"> is used in the macro
definition, macro bodies will not be recognized.> This means that with the definition

  +OPTIONLESS:\\B<__body__>

the construction

  \\OPTIONLESS{something=this}<more>

is evaluated as a usage of \C<\\OPTIONLESS> without body, followed by the \I<string>
\C<"{something=here}">. Likewise, the definition

  +BODYLESS:found __something__

causes

  \\BODYLESS{something=this}<more>

to be recognized as a usage of \C<\\BODYLESS> with option \C<something>, followed
by the \I<string> \C<"<more\>">. So this will be resolved as \C<"found this">. Finally,

  +JUSTTHENAME:Text phrase.

enforces these constructions

  ... \\JUSTTHENAME, ...
  ... \\JUSTTHENAME{name=Name}, ...
  ... \\JUSTTHENAME<text>, ...
  ... \\JUSTTHENAME{name=Name}<text> ...

to be translated into

  ... Text phrase. ...
  ... Text phrase.{name=Name} ...
  ... Text phrase.<text>, ...
  ... Text phrase.{name=Name}<text> ...

The principle behind all this is to make macro usage \I<easier> and intuative:
why think of options or a body or of special characters possibly treated as
option/body part openers unless the macro makes use of an option or body?


===Deleting a macro

An \I<empty> macro text \I<undefines> the macro (if it was already known).

  // undeclare the IB alias
  +IB:

An alias can be used everywhere a tag can be. Tags and macros are indeed that
interchangable that macros can be used to overwrite existing tags. The paragraph

  +B:\\I<__body__>

transforms all occurences of \\B tags into \\I ones.

