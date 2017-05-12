
// declare helpful macros
+BC:\B<\C<__body__>>

// include macro definitions of basic tag docs (to gt an up to date list of basic macros)
\INCLUDE{type=pp file="tags/basic-tag-macros.pp" smart=1}


=Tags in general

Tags are \I<directives> embedded into the text stream, commanding how certain
parts of the text should be interpreted. The general syntax is
\B<<name\>[{<options\>}][<body\>]>. Whether a part is optional or not depends
on the tag (at least a tag name is required ;-).

A \B<tag name> is made of a backslash and a number of alphanumeric characters
(capitals):

  \\TAG

B<Tag options> can be optional (see the specific tags documentation). They follow
the tag name immediately, enclosed by a pair of corresponding curly braces. Each
option is a simple string assignment. The value should be quoted if \C</^\\w+$/> does
not match it. Option settings are separated by whitespace(s).

  \\TAG\B<{par1=value1 par2="www.perl.com" par3="words and blanks"}>

If a tag accepts options, it can be made \I<conditional> which means it can be
activated depending on the result of passed Perl code, which is evaluated as
\REF{occasion=1 name="Active contents" type=linked}<Active Content>. This code
is passed by option \C<_cnd_>.

  \\IMAGE{\B<_cnd_="$illustrate"> src="piegraph.gif"}

If Active Contents is disabled, the condition defaults to be false.


The \I<tag body> may be optional. If used, it is anything you want to make the tag
valid for. It immediately follows the optional parameters, enclosed by angle brackets:

  \\TAG\B<<body\>>
  Tag bodies \\TAG<can
  be multilined>.
  \\TAG{par=value}\B<<body\>>

Tags can be \I<nested>.

  \\TAG1<\\TAG2<body>>

\I<Every PerlPoint translator defines its own tags>, but usually all of them support
\OTHER_BASIC_TAGS{current=showAll} as a base set. Additionally,
there are a few reserved tags which are implemented by \I<every> translator. See the
next section for details.



=Special purpose tags

* provide additional source control and

* allow target format specific source parts and

* implement structured formatting;

* can be used whereever tags in general are valid;

* currently are \C<\\INCLUDE>, \C<\\EMBED> and \C<\\END_EMBED>, \C<\\TABLE> and \C<\\END_TABLE>;

==File inclusion

It is possible to include another file by \B<\\INCLUDE{file=\<filename\> type=\<type\>}>.

The mandatory base options are

@|
option | description
file   | names the source to be included (should exist)
type   | determines how the file is handled

All types different from \C<"pp"> or \C<"perl"> make the included file be read but not evaluated.
The read contents is usually passed to the generated output file directly, with exception of type
\C<"example">. This is useful to include target language specific, preformatted parts.

  \\INCLUDE<type=html file=homepage>

A certain translator typically supports the file types of its target language, see the
translator specific documentation for details.


===Including nested PerlPoint sources

If the type of an included file is specified as \C<"PP">, the file contents is
made part of the presentation source.

  // include PerlPoint
  \\INCLUDE{\B<type=pp> file="nested.pp"}

The nesting level is umlimited, but every
file \I<in a nesting hierarchy> is \I<read only once> (to avoid confusion by
circular nesting). (Including the same file multiply in different nesting
hierarchies is possible without problems.)

A PerlPoint file can be included wherever a tag is allowed, but sometimes
it has to be arranged slightly: if you place the inclusion directive at
the beginning of a new paragraph \I<and> your included PerlPoint starts by
a paragraph of another type than text, you should begin the included file
by an empty line to let the parser detect the correct paragraph type. Here
is an example: if the inclusion directive is placed like

  // include PerlPoint
  \\INCLUDE{type=pp file="file.pp"}

and \C<file.pp> immediately starts with a verbatim block like

  <<VERBATIM
      verbatim
  VERBATIM

, \I<the inclusion directive already opens a new paragraph> which is detected to
be \I<text> (because there is no special startup character). Now in the included
file, from the parsers point of view the included PerlPoint is simply a
continuation of this text, because a paragraph ends with an empty line. This
trouble can be avoided by beginning such an included file by an empty line,
so that its first paragraph can be detected correctly.

====Special option: headlinebase

When including nested PerlPoint, a special tag option \C<"headlinebase"> can be
specified to define a headline base level used as an offset to all headlines in
the included document.

<<EOE
 If "\INCLUDE{type=PP file=file headlinebase=20}" is
 specified and "file" contains a one level headline
 like "=Main topic of special explanations"
 this headline is detected with a level of 21.
EOE

Pass the special keyword \BC<CURRENT_LEVEL> to this tag option if you want to
set just the \I<current> headline level as an offset. This results in
"subchapters".

<<EOE
 If "\INCLUDE{type=PP file=file headlinebase=CURRENT_LEVEL}"
 is specified in a chapter of level 4 and "file" contains a
 one level headline like "=Main topic of special explanations"
 this headline is detected with a level of 5.
EOE

Similar to \C<CURRENT_LEVEL>, \BC<BASE_LEVEL> sets the current \I<base>
headline level as an offset. The "base level" is the level above
the current one. Using \C<BASE_LEVEL> results in parallel chapters.

<<EOE
 If "\INCLUDE{type=PP file=file headlinebase=BASE_LEVEL}"
 is specified in a chapter of level 4 and "file" contains a
 one level headline like "=Main topic of special explanations"
 this headline is detected with a level of 4 - similar to the
 level the nested source was included on.
EOE

A given offset is reset when the included document is parsed completely.

The \C<"headlinebase"> feature makes it easier to share partial documents with others,
or to build complex documents by including seperately maintained parts, or to include
one and the same part at different headline levels.


====Special option: smart

Option \BC<smart> commands the parser to include the file
only unless this was already done before. This is intended for inclusion
of pure alias/macro definition or variable assignment files.

 \\INCLUDE{type=PP file="common-macros.pp" \B<smart=1>}


====Special option: localize

Nested sources may declare variables of their own, possibly overwriting
already assigned values. Option \BC<localize> works like Perls \C<local()>:
such changes will be reversed after the nested source will have been
completely processed - so the original values will be restored. You can
specify a comma separated list of variable names or the special string
\C<__ALL__> which flags that the current settings shall be restored
\I<completely>.

 \\INCLUDE{type=PP file="nested.pp" \B<localize=\I<myVar>>}

 \\INCLUDE{type=PP file="nested.pp" \B<localize=\I<"var1, var2, var3>>"}

 \\INCLUDE{type=PP file="nested.pp" \B<localize=\I<__ALL__>>}




===Including Perl

The second special case of inclusion is a file type of \C<"Perl">.

  // include PerlPoint
  \\INCLUDE{\B<type=perl> file="dynamicPP.pl"}

\B<Inluded Perl is \I<active contents> - see the special chapter about it.>

\I<If> active contents is enabled, included Perl code is evaluated. The code is
expected to produce a PerlPoint string which then replaces the inclusion tag and
is read like static PerlPoint.

If the included code fails, an error message is displayed and the result is
ignored.


===Including Examples

Included files can be declared to be examples. This makes the file placed into
the source as a \I<verbatim block>, without need to copy its contents into the source.

  // include an external script as an example
  \\INCLUDE{\B<type=example> file=script}

So, an example script of

  #!perl -w

  print "Geetings from outside!\\n";

is made part of the source as if one would have written

<<EOE
  <<EOE
  #!perl -w

  print "Greetings from outside!\n";
  EOE
EOE

All lines of the example file are included unchanged. On request, they can be indented.
To do so, just set the special option \C<"indent"> to a positive numerical value equal to
the number of spaces to be inserted before each line.

  // external example source, indented by 3 spaces
  \\INCLUDE{type=example file=script \B<indent=3>}

Including external scripts can accelerate PerlPoint authoring significantly,
especially if the included files are still subject to changes.



==Embedded code

Target format code does not necessarily need to be imported by file - it can be
directly \I<embedded> as well. This means that one can write target language
code within the input stream using \C<\\EMBED>, maybe because you miss a certain
feature in the current translator version:

<<EOE

  \EMBED{lang=HTML}
  This is <i><b>embedded</b> HTML</i>. The parser detects <i>no</i>
  Perl Point tag here, except of <b>END_EMBED</b>.
  \END_EMBED

EOE

The mandatory \I<lang> option specifies which language the embedded code is of.
Usually a translator only supports its own target format to be embedded.
(You will not be surprised that language values of \C<"perl"> and \C<"pp"> are special
cases - see the related subsections.)

Please note that the \C<\\EMBED> tag does not accept a tag body to avoid
ambiguities. Use \C<\\END_EMBED> to flag where the embedded code is completed.
\I<It is the only recognized tag therein.>

Because embedding is not implemented by a paragraph but by a \I<tag>, \\EMBED
can be placed \I<directly> in a text like this:

<<EOE
  These \EMBED{lang=HTML}<i>italics</i>\END_EMBED are formatted
  by HTML code.
EOE

===Embedding PerlPoint into PerlPoint

This is just for fun. Set the \C<"lang"> option to \C<"pp"> to try it:

<<EOE
  Perl Point \EMBED{lang=pp}can \EMBED{lang=pp}be
  \EMBED{lang=pp}nested\END_EMBED\END_EMBED\END_EMBED.
EOE

===Embedding Perl

This feature offers dynamic PerlPoint generation at \I<translation time>.

  \\EMBED{lang=perl}hello\\END_EMBED

\B<Embedded Perl is \I<active contents> - see the special chapter about it.>

\I<If> active contents is enabled, embedded Perl code is evaluated. The code is
expected to produce a PerlPoint string which then replaces the inclusion tag and
is read like static PerlPoint.

If the included code fails, an error message is displayed and the result is
ignored.

Here's another example:

<<EOE

  \EMBED{lang=PERL}

  # build a message
  my $msg="Perl may be embedded as well.";

  # and supply it
  $msg;

  \END_EMBED

EOE

The feature is of course more powerful. You may generate images at translation
time and include them, scan the disk and include a formatted listing, download
data from a webserver and make it part of your presentation, autoformat complex
data, include formatted source code, keep your presentation up to date in any
way and so on.


==Tables by tag

It was mentioned in the \I<paragraph> chapter that tables can be built by table
paragraphs. Well, there is a tag variant of this:

<<EOE

  \TABLE{bg=blue separator="|" border=2}

  \B<column 1>  |  \B<column 2>  | \B<column 3>
     aaaa       |     bbbb       |  cccc
     uuuu       |     vvvv       |  wwww

  \END_TABLE

EOE

\C<\\TABLE> opens the table, while \C<\\END_TABLE> closes it.

These tags are sligthly more powerfull than the paragraph syntax: you can set
up several table features like the border width yourself, and you can
format the headlines as you like.

All enclosed lines are evaluated as table rows by default, which means that
each source line between \C<\\TABLE> and \C<\\END_TABLE> is treated as a table
row. PerlPoint as well allows you to specify a string of your own choice to
separate rows by option \C<rowseparator>. This allows to specify a table
\I<inlined> into a paragraph.

<<EOE

  \TABLE{bg=blue separator="|" border=2 rowseparator="+++"}
  \B<column 1> | \B<column 2> | \B<column 3> +++ aaaa
  | bbbb | cccc +++ uuuu | vvvv|  wwww \END_TABLE

EOE

This is exactly the same table as above.

As in all tables, leading and trailing whitespaces of a cell are
automatically removed, so you can use as many of them as you want to
improve the readability of your source.

Tables built by tag are normalized the same way as table paragraphs are.

Here is a list of basically supported tag options (by table):

@|
option           | description
\C<separator>    | a string separating the table \I<columns> (can contain more than one character)
\C<rowseparator> | a string separating the table \I<rows> (can contain more than one character)
\C<gracecr>      | usually set correctly by default, this specifies the number of row separators to be ignored before they are treated as separators - which usually allows to start the table contents in a subsequent line \I<after> the line containing the \C<\\TABLE> tag

More options may be supported by your PerlPoint translator software.

