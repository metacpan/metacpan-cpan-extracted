
//
// PerlPoint tutorial. An intro for users.
//
// This is the frame file. It might depend on included docs.
//
// Author: (c) J. Stenzel 2003-2005.
//

// document data
$docAuthor=Jochen Stenzel

$docAuthorMail=perl@jochen-stenzel.de

$docDate=2005-04-30

$docVersion=0.02



// macro definitions
+OREF:\REF{name="__n__" type=linked occasion=1}<__body__>

+BCX:\B<\C<\X<__body__>>>

+IX:\I<\X<__body__>>

+CX:\C<\X<__body__>>

+UB:\U<\B<__body__>>

+CPAN:\C<\X<__body__>>

+RED:\F{color=red}<__body__>

+BLUE:\F{color=blue}<__body__>

+GREEN:\F{color=green}<__body__>

+ILLT:\LOCALTOC{type=linked depth=2}

+FNR:\SUP<\F{size="-2"}<\REF{type=linked name="__n__"}>>

+FN:\F{size="-2"}<\SEQ{type=footnotes name="__n__"}: __body__>

+HR:\EMBED{lang=html}<HR/>\END_EMBED


=Start

.\I<Note: this tutorial is still incomplete, so several sections might be empty. Nevertheless,
the basic parts are there and should allow you to start working with PerlPoint. Enjoy!>

// TOC
\ILLT


// intro
==What is PerlPoint?

When it comes to documentation, there are two base approaches: the WYSIWYG concept that allows
to compose things an interactive way, and the description language concept which "describes"
documents in a special format, which finally is transformed into the visual result. Think of
office applications as examples for the first approach, and HTML, XML or LaTeX for the second
one.

For one or the other reason, people prefer one or the other approach. It depends on their needs
(and preferences) which solution suits them most.

PerlPoint is a "descriptive" toolset. To build a document, it is described in a text file in the
PerlPoint format. As with all descriptive approaches, using a text format makes those sources
very portable.

But PerlPoint is portable in a second way, too: as it is written in pure Perl, the toolset runs
on a wide range of platforms. Whereever Perl runs, PerlPoint runs as well.

So well, but what will this toolset produce? Will the \I<results> be portable, too?
- This depends on what you produce, because there is no special PerlPoint output. Instead,
PerlPoint can produce \I<various> formats. So it is \I<flexible> as well. Produce HTML if you want
to publish via Web or make presentations. Produce PDF if you want to make brochures or handouts
or presentations in this format, or if you are in need for a document that cannot be modified.
Produce LaTeX if you want to print in superb quality,
or to integrate your docs in some sort of LaTeX postprocessing. Or choose SDF as your
intermediate format, to go for POD, PostScript or manpages. Or join the XML community. All these
target formats are at hand right now. And if none of them suits your needs, you can write new
converters.

Besides portability and flexibility, PerlPoint is easy to start with. Basically, docs are
very much like simple text documents, divided into paragraphs. We will see this in a minute.
Nobody needs to be a programming expert to begin, people can start quickly. On the other hand,
\I<if> you are in need of more sophisticated solutions, PerlPoint will support you as well
and offer tags, macros, embedded programming, filters, conditions and more.

==Basics of the document format ~ Format basics

Writing a PerlPoint document is simple. Here is a first document:

 =Documents are simple text files

 Writing PerlPoint can be as easy as writing notes
 to a file. Just open a text editor and start.

 Of course there are more sophisticated features.
 But like Perl, PerlPoint allows you to do easy
 things with ease.

These are two text paragraphs and a headline. The rules for text are simple:

* Text paragraphs start at the left margin.

* Optionally, they can be started with a \IX<dot> (with \C<PerlPoint::Package> 0.40 and better).

 \RED<.>This is a text as well.

* They can be wrapped in any way.

* A line of whitespaces (or the end of the document) completes the paragraph.

As for the headline, there is a special thing: the prefix \C<=> at the beginning. This prefix
marks this paragraph as a headline. There can be more than one \C<=> characters: their number
shows the headline level.

 Here is the outline of a document, in traditional
 form.

   1. Formats

   1.1. Input Formats

   2.2. Output Formats

   2.2.1. HTML

   2.2.2. XML

   3. Conclusion

 In PerlPoint, it would be written this way:

   =Formats

   ==Input Formats

   ==Output Formats

   ===HTML

   ===XML

   =Conclusion

 The \C<=> characters are just placeholders, the
 final numbering will be made when the document
 will be processed.

Like paragraphs, headlines can be wrapped, and likewise they end with a line of whitespaces.

 =Usually headlines are short,
  but in case you need a very long headline,
  it is no problem to write it down in
  PerlPoint, wrapped to as many lines as
  you like to keep it readable

\I<This paragraph concept is essential.> All basic elements of a PerlPoint document are
paragraphs. And as with the headline, \I<a special prefix marks the paragraphs type>.

If you want to start quickly, this is almost all you need to know about the format. Here is the
one thing that is missed: backslashes (\C<\X<\\>>) are special characters. To write a literal
backslash, just write two of them: \C<\\\\>.

 Backslashes ("\\\\") are special.

Now, if you are in a hurry, you can directly proceed with the \OREF{n="Produce a
document"}<converter call>. But if you have a few minutes more, the following sections of this
chapter will teach you how to write lists, examples, tables and comments, and this isn't more
difficult than what we had till.

\ILLT




===Bullet lists

Those lists are often used in presentations, or just to make a point. Here is how we write
them in PerlPoint:

 Paragraphs seen that far:

 * texts,

 * headlines.

 And now we go for bullet lists.

You note the prefix: \C<*>. Start a paragraph with that, and it becomes a list point. The
list starts and ends instantly, there is no need to mark its beginning or end.

Besides the prefix, the usual rules apply: wrap as you want, and complete with an empty line.

 * It does not matter
   how
   a list point is
   wrapped.


===Numbered lists

Want to see numbers instead of bullets in your list? Well, that's easy, just use another
prefix: the number placeholder (and paragraph prefix) is a \C<#>.

 Three paragraph parts:

 \RED<#> Prefix.

 \RED<#> Body.

 \RED<#> Empty line.

As with bullet lists before, lists are instantly opened and closed. PerlPoint finds points
of the same type and automatically combines them to a list.

And there's yet another list type.


===Definition lists

This list type is borrowed from HTML. A definition describes an item, and therefore consists
of two parts: the item and the description.

As an item can be more than just one word, we need more than a simple prefix here: we need to
mark where the description part starts. A colon seems appropriate - that's what one would
usually use in a written text:

 Computer\RED<:> a system to automate stupid jobs.

In PerlPoint, it's the same, and to make things consistent the colon is used to \I<start> a
definition point as well:

 \RED<:>Computer\RED<:> a system to atomate stupid jobs.

Isn't that easy?

As with the other list types, the point can be wrapped in any way. Additionally, there
can be any number of whitespaces between the item and the explanation part. This allows to
structure the source for readability:

 :Writer:      a creative person
               producing books.

 :Illustrator: an artist visualizing stories.

 
===Examples

Sometimes things need to be illustrated by examples, which in PerlPoint are paragraphs starting
with an indentation.

 So, for example:

   Business people could present statistical
   data in an example, emphasizing their point.

   Programmers like to show source code in
   examples.

The number of whitespaces used as a paragraph prefix is up to you. It does not matter for
the example to be recognized.

All whitespace used \I<within> an example block is preserved, which means it will be reproduced
in the result, including the original wrapping.

Examples are paragraphs as usual - they end with a line of whitespace. Nevertheless, as such
lines might be part of the example text, PerlPoint automatically combines subsequent example
paragraphs. As a result, \I<in fact an example block is completed by the first subsequent
non-example paragraph>. All intermediate newlines will be made part of the generated example
block.

In other words: everything between the start of an example block and the next non-example
paragraph will become part of this example, including whitespace lines.

 A piece of code, including whitespace lines:

  # use an intermediate scope
  {
   # scopy
   my $value;

   # calculate
   $value=20*$start;

   # print result
   print "Result: $value.\n";
  }

 Now we will analyze this code ...

But you \I<want> to separate subsequent examples? Ok, in this case, use the special "-"
paragraph:

  The first example.

  With its second part.

 \RED<->

  The second examples
  first line.

Note: there's a second paragraph type for examples, in order to handle special cases.
      If you aren't a programmer, chances are that you will not need this second type.


===Tables

At this point I think you are familiar with the paragraph concept, so it will not surprise
you that even tables are paragraphs. And quickly you'll ask: what's the special prefix?

Well, the special prefix for table paragraphs is a line describing the string that is used
to delimit columns. This is done by starting with \C<@>, followed by the delimiter string.

The most intuitive delimiter string is "|". So here's an example of a table using this
delimiter:

 @\RED<|>
 given name \RED<|> name    \RED<|> playing
 Peter      \RED<|> Paul    \RED<|> Guitar
 Paul       \RED<|> Newby
 Mary Ann   \RED<|> Shuttle \RED<|> Chess

That's intuitive and suggested for all cases without \C<|> in the field entries, but one
could use another (and longer) string as well:

 @\RED<OOPS>
 given name \RED<OOPS> name    \RED<OOPS> playing
 Peter      \RED<OOPS> Paul    \RED<OOPS> Guitar
 Paul       \RED<OOPS> Newby
 Mary Ann   \RED<OOPS> Shuttle \RED<OOPS> Chess

Please have a look at the whitespaces in the table fields - in order to make the source
as readable as possible, you can add as many as you want.

OK. Another point is that the rows in this example have different numbers of columns. Will this
cause a problem? No - PerlPoint will add columns automatically, according to the headline row.
This is the very first row in the table.


// comments
===Comments

Well, we are almost done with the basics. The final paragraph type in this collection is
a \I<comment>. Comments are annotations made to your \I<source>, they will not show up in
the target format.

The special prefix of comment paragraphs is a \IX<double slash>.

 \RED<//> this is a comment

Although comments are paragraphs, they are treated a little bit different, just for reasons
of convenience. As they should be placed near to what they remark, the usual whitespace line
behind would be contra productive. So, each comment line is a paragraph by itself. Which in
turn means that subsequent comment lines need their double slash prefix \I<each>.

 // this is
 // a comment
 Here we go with the next text paragraph.


==Produce a document

\ILLT

===Intro to converters

The transformation from a PerlPoint source into a document is done by programs called
"PerlPoint converters". A number of these scripts is available on CPAN and at the projects
site at Sourceforge:

* \BCX<pp2html> is the traditional main converter. It produces fancy HTML pages
  and is highly configurable. This converter is part of the CPAN distribution
  \CPAN<PerlPoint::Converters>.

* \BCX<pp2latex> produces LaTeX. This is claimed to be in alpha state but is fairly
  stable. It comes as part of \CPAN<PerlPoint::Converters> as well.

* \BCX<pp2sdf> generates SDF, a document format superseeding POD, by Ian Clathworthy.
  SDF is out of development, but it's very stable. The SDF processor \CPAN<sdf> can produce
  a \I<lot> of other formats, namely PDF, PostScript, POD and manpages. So SDF is
  typically used as an intermediate format. \C<pp2sdf> is part of \CPAN<PerlPoint::Package>.

As you can see, typically there is one converter for every target format. This was our
approach up to \C<PerlPoint::Package> 0.39, and these tools are furtherly provided and
fully supported. Additionally, \C<PerlPoint::Package> 0.40 introduced an extended design which
makes it easy to have \I<one> converter for \I<many> target formats. In this design,
format capabilities are added by \I<formatter plugins>, which from a users point of view
come in the form of Perl module distributions.

In the extended design, the all in one converter is called \BCX<perlpoint>. Currently the
following formatters are available:

* \BCX<PerlPoint::Generator::SDF::Default>, generating SDF. In fact the default converter
  for SDF reproduces all the capabilities of \C<pp2sdf>. It comes with
  \CPAN<PerlPoint::Package>.

* \BCX<PerlPoint::Generator::XML::Default>. The base XML formatter transformes the PerlPoint
  source document into XML according to an own DTD. Tag names can be adapted, and the resulting
  DTD can be produced as well. Part of \CPAN<PerlPoint::Generator::XML>.

* \BCX<PerlPoint::Generator::XML::AxPoint>. Generates XML for the \CPAN<AxPoint> presenter
  by Matt Seargeant. Part of \CPAN<PerlPoint::Generator::AxPoint>.

* \BCX<PerlPoint::Generator::XML::XHTML>. Produces an XHTML document, supporting CSS. The
  document is written to a single page. Part of \CPAN<PerlPoint::Generator::XHTML>.

* \BCX<PerlPoint::Generator::XML::XHTML::Paged>. Produces XHTML documents supporting CSS,
  one page per chapter. Part of \CPAN<PerlPoint::Generator::XHTML>.

The list of formatters will hopefully grow. A formatter to the Open Office Presenter software
("Impress") may follow, as it uses XML as well.

Please note that nobody is limited to the converters in this list. In both concepts, anyone in
need of another converter can write it on his own, as there is an open framework provided. In
the formatter concept, is is even possible to modify just a certain part of an existing
converter, to get the behaviour you prefer. We will talk about that in the advanced sections.

For now, we will have a look how to use these programs to get a document from our source. The
following sections describe both the established and stable "one format, one converter" concept,
and the new formatter concept which is still in beta state. Feel free to use the concept of
your choice.

===Using target specific converters ~ Target specific converters

As listed in the intro \OREF{n="Intro to converters"}<above>, there are various converters of
this type.

First, find a converter for your target format. Let's assume HTML should be written. HTML
can be produced from SDF, so one way could be to use \C<pp2sdf> and \C<sdf> in a sequence. But
this would require several steps and results in one (and possibly long) single page. Another
converter is \C<pp2html>, the well featured and stable converter by Lorenz Domke, which
writes multi paged HTML in one step. Let's focus on that.

Now find out the calling conventions of the chosen converter. For \C<pp2html>, a basic call
looks like this:

  pp2html source.pp

This call produces one page per chapter, right where you are. The slides are named
\C<slide0001.htm> etc. Each page is reported by the run. The pages written are very
straightforward in design, but well written and usable. A link filled contents page
(\C<slide0000.htm>) and an index (\C<slide_idx.html>) are added automatically.

Lots of options are available to adapt this design. Many aspects can be fine tuned,
including the target directory. To write into \C<test>, just add option \C<-targetdir>:

  pp2html \RED<-targetdir test> source.pp

, and all the new files will be written to \C<test/> which is made if required.

The filenames can be changed as well. Use the \C<-slide_prefix> and \C<-slide_suffix>
options to do this:

  pp2html \RED<-slide_prefix page -slide_suffix html> source.pp

With these changes, now the generated files are named \C<\RED<page>0000.\RED<html>> etc.

Likewise, colors can be adapted. As a simple example let's change the background and
example boxes:

  pp2html \RED<-bgcolor cyan -boxcolor magenta> source.pp

.- and our pages are looking wild ;-)

There are \I<lots> of color options. All of them take the values that are accepted by the
color options of HTML tags, so one can use hexadecimal codes with a preceeding \C<#> as
well:

  pp2html \RED<-bgcolor '#0e0000'> test source.pp

Ok, but there are more things to tune. \C<-center_headers> centers headlines, while
\C<-nonum_headers> switches off headline numbers:

  pp2html \RED<-center_headers -nonum_headers> test source.pp

This is just an intro. Please refer to the docs of \C<pp2html> for a complete option list.
The feature set is really rich.

But you do not have to remember and retype all necessary options again and again. The quickest
way of option reuse is to store them in a file and let \C<pp2html> process this file instead
of direct options:

  \GREEN<# This could be your option file.>

  \GREEN<# target directory>
  -targetdir test

  \GREEN<# filenames>
  -slide_prefix page
  -slide_suffix html

  \GREEN<# color options>
  -bgcolor cyan -boxcolor magenta

  \GREEN<# header options>
  -center_headers
  -nonum_headers

Now, with a file like this, a call would be reduced to

  pp2html @options source.pp

The options collected in an option file define a certain layout style. As a further level of
abstraction, \C<pp2html> supports option files stored in central places, which are called
"styles". To make such a style, first collect all necessary options in an option file. Then,
make a style directory, e.g. \C<styles>, to hold all your style setups. Store your option file
under this path, in a subdirectory named as you wish to call your style, and name it
\C<<your style\>.cfg>. Here is an example:

  styles
   |
   -- \RED<YourStyle>
       |
       -- \RED<YourStyle>.cfg

Now you can use this style by specifying its name and the base path:

  pp2html \RED<-style_dir styles -style YourStyle> source.pp


Additional files like templates and bullet graphics can be stored in the (specific) style
directory as well. \C<pp2html> will copy them to the target directory automatically.

Note that while various options are shared by various converters, others can be
different as each converter can define options of its own. Please refer to their documentations.


===Using formatter based converters ~ Generators

With this approach, there is only one converter to know: \BCX<perlpoint>. This converter is
installed with \C<PerlPoint::Package>.

\C<perlpoint> is kind of a launcher. It can handle various \C<target languages> by loading related
modules. Likewise, it \I<formats> the results in a specific way, using \I<templates> if
requested. You just have to define the way your output should be built. The setup is performed
by options.

First, you have to choose the target language. At the time of this writing, these languages are
available:

* SDF,

* XML.

To get the most recent list, please have a look at \L{url="http://search.cpan.org"}<CPAN>.
Language generators are implemented as Perl \I<modules>, so you can search for modules named
\C<PerlPoint::Generator::\RED<<LANGUAGE\>>>. Capitals are used intentionally: all language modules
are capitalized by convention.

OK, let's say we want to produce XML, as this is cool and near to HTML. We use the \BCX<-target>
option to let \C<perlpoint> know of this decision.

  perlpoint \RED<-target XML> source.pp

Similar to \REF{type=linked name="Using target specific converters"}<other converters>, the
source files are passed in as parameters.

With this call, we get a list of copyright notes and an error message:

  perlpoint 0.01, (c) J. Stenzel (perl@jochen-stenzel.de), 2003-2005.

  This is a PerlPoint::Generator::XML::Default converter.

  PerlPoint::Generator::XML::Default 0.01 (c) J. Stenzel (perl@jochen-stenzel.de), 2003.
  PerlPoint::Generator::XML 0.01 (c) J. Stenzel (perl@jochen-stenzel.de), 2003-2004.
  PerlPoint::Generator 0.01 (c) J. Stenzel (perl@jochen-stenzel.de), 2003-2005.

  [Fatal] Missing mandatory option -doctitle.

First, the program is reported to be a \I<\C<PerlPoint::Generator::XML::Default>> converter.
Every language is written by a \I<formatter>. Changing the formatter redefines your results.
If no formatter is specified as in our call, \C<perlpoint> falls back to the default converter.
\I<Every language module comes with a related default converter, so it is always available.>

Then, you see all the modules that were loaded automatically. From a users point of view,
these are just internals handled behind the scenes, but you can see that there's a hierarchy.

Finally, we have that error message. Oops - \C<perlpoint> requires a minimum of document and file
data, including the title (\CX<-doctitle>), filename prefix (\CX<-prefix>) and filename suffix
(\C<-suffix>) Different to \C<pp2html>, the \C<-suffix> option requires to specify the
extension dot).

  perlpoint -target XML \RED<-doctitle Example -prefix example -suffix .xml> source.pp

And with this call, the converter generates an XML file \C<example.xml>.

As our option list grows quickly, we switch to an option file now. Option files allow to
read options from a file, written exactly as on the command line, intermixed with comments
and empty lines for readability. At this opportunity we add a target directory:

  \GREEN<# document title>
  -doctitle Example

  \GREEN<# filenames>
  -prefix example
  -suffix .xml

  \GREEN<# target directory>
  -targetdir example

The call now changes to

  perlpoint \RED<@options.cfg> source.pp

In the following we will assume that all necesary options are stored in the option file.
On the command line, we will focus on the options we are talking about.

Well! The XML produced is very general, but of course it follows a DTD. The DTD can be
printed out by using \C<-writedtd> and \C<-xmldtd>.

  perlpoint @options.cfg \RED<-xmldtd example.dtd -writedtd> source.pp

After this call, you not only have the required XML file but also \C<example.dtd> which
describes the general format and can be used to transform the results in whatever you
want. For example, we could produce XHTML using XSLT. But fortunately, there's a formatter
that emits XHTML directly.

Formatters are plugins implemented by Perl modules. For a list of formatters available for
your target language, again \L{url="http://search.cpan.org"}<scan CPAN> for modules named
\C<PerlPoint::Generator::<your target language\>::\RED<<Something\>>>. (The "Something" might
include various module levels.) A search for the XML target currently replies these
formatters:

* PerlPoint::Generator::XML::\RED<XHTML>,

* PerlPoint::Generator::XML::\RED<XHTML::Paged>,

* PerlPoint::Generator::XML::\RED<AxPoint>.

By installing their distributions, these formats become available to \C<perlpoint>. To invoke
a formatter, use the \C<-formatter> option.

  perlpoint @options -target XML \RED<-formatter XHTML> \BLUE<-suffix .html> source.pp

Note that the formatter name is specified in a short form. Only the module levels after
\C<PerlPoint::Generator::<target language\>> are required.

Our latest call produced a single HTML page \C<example.html>. The XHTML is basic but can
be easily improved by using the various options of the new formatter. To find the available
tuning tools, add \C<-help> to your call.

  perlpoint @options.cfg \RED<-help> source.pp

This will display the online help, containing a section "Options". You'll find things like
\C<-css>, \C<-favicon>, \C<-norobots> and more. These were not available before as we
used the default formatter - check it by another help request:

  perlpoint @options.cfg \RED<-formatter Default> -help source.pp

Indeed - now there are no XHTML specific sections. Instead we find XML specific stuff like
\C<-writedtd>. \I<The help adapts to the current call. Always use -help to find out the
options you have.>

Do we get even more options for the \C<XHTML::Paged> converter? Looking at the help it
doesn't seem so at the moment (but this could change in the future, so always check the help
after updates). \I<What> we get with this formatter is a splitted output - each chapter is
on its own page now. These pages are named \C<<prefix\>-<chapter number\><suffix\>>,
e.g. \C<example-10.html>.

  perlpoint @options \RED<-formatter XHTML::Paged> source.pp

The layout is still basic. There are two ways to beautify it. First, we can use the options
provided by the language generator and the formatter, e.g. \C<-css>. Additionally, we can use
the third component of the generator design: \IX<templates>. \C<pp2\RED<tdo>> means "template
driven output", and all you need is typically a \I<style> for your language format. Styles
are special directory structures containing configurations and templates for a certain layout,
and are assigned using the \C<-styledir> and \C<-style> options:

  perlpoint @options \RED<-styledir . -style test> source.pp

For a working style, please have a look at the \C<demo/styles> directory in the
\C<PerlPoint::Package> distribution. To use the style "GPW7-PPGenerator-01", change
your call to this

  perlpoint @options -styledir \RED<.../demo/styles> -style \RED<GPW7-PPGenerator-01> source.pp

And voila - now your pages have a modern, CSS driven layout with navigation, colors, headers,
footers, bullet graphics, JavaScript navigation and more!

Now, you might try the second example style, "FramesAndApplet" ...

  perlpoint @options -style \RED<FramesAndApplet> source.pp

... to get a layout with frames, different colors, detailed navigation bars on each page
and a Java applet navigation tree.

Styles make it very easy to reproduce a layout and to share it with others.

Where to get more styles? We plan to have a download section on the project homepage, but it
is not there yet. For the time being, search the net or write them on your own which is not
as complicated as you might think. There is a \OREF{n="Generator styles"}<special section>
about this later on, but as
a short intro template modules add lots of options to fine tune your results. To get an
impression please request help for a call with option \C<-templatesAccept>:

  perlpoint @options \RED<-templatetype Traditional -templatesAccept XML/XHTML::Paged> \BLUE<-help> source.pp

Don't care of the complicated call as it is usually hidden in a style definition.

Basically these are the basics of using PerlPoint generators. Call \C<perlpoint> for a target
language, specify a formatter to use, add a style if available and use \C<-help> to find
out which options are available for tuning. Everything else is handled behind the scenes.


===Hiding standard options

Both converter approaches support option files. Simplify your life by collecting options
in files, and refer to these files in further calls:

  \GREEN<# option file>
  -target XML -formatter XHTML::Paged

  ...

  \GREEN<# call>
  perlpoint \C<@xhtml.cfg> source.pp


To get a step further, options used in \I<every> call can be stored in default option
files in your home directory. These are loaded automatically and named like the converter
they are called for: \C<.pp2html> is read by \C<pp2html>, while \C<.perlpoint> is evaluated by
\C<perlpoint>. The definition of style directories could be a candidate:

  \GREEN<# style directories>
  -styledir /home/xyz/styles
  -styledir /opt/data/styles

To make things even more general, similar files can be stored in the installation directories
of the converters. This way the options are valid for \I<all> users of the tools, while files
in your home directory are only read if a converter runs under your account.

Options specifed in the call overwrite such in a home directory default file, which overwrites
options in an installationwide configuration.


==Adding markup

Until now we have looked at various paragraph types, but everything within a certain paragraph
was formatted the same way. This can be changed by markup, which is provided in form of
\I<tags> and \I<macros>.

Both tags and macros share the same base syntax, so it is easy to start with tags and to
continue with macros. Indeed, once a macro is defined it can be used like a tag, there is
no difference for a user.

\ILLT

===Tags

As known from many other markup languages, tags are used to categorize text. In its simplest
form a PerlPoint tag embeds a bunch of text in a paragraph, saying "this should be treated
as this or that". So, if we want something to be handled as \I<italic> text, we use the tag
\BCX<\\I> and write

  \\I<italic>

As you can see, a tag is made of capitals and preceeded by a backslash. The embedded text
part is enclosed by angle brackets. This embedded part is called the "tag body".

Similar to \C<\\I>, \BCX<\\B> marks text as \B<bold>, and \BCX<\\C> formats its body as
\C<code>.

  Look at \\B<this> \\C<code>.

You want more control over colors and fonts? Use the \BCX<\\F> tag in the tradition of the
old fashioned HTML tag \C<<F\>>. To specify the colors etc., this tag needs \I<options>. Tag
options are enclosed by braces:

  Color this \\F{color=red}<red>.

The general rule is that options, if required, are written between the tag name and the body.
Option values are assigned via \BCX<=> and can be quoted. Quotes are \I<required> if the
values contain other characters than letters, digits and underscores.

  Color this \\F{color="#abcdef"}<text>.

Use whitespaces to \I<separate> options:

  \\F{color=red size=20}<red and large>.

\BCX<\\X> is another important base tag. It adds its body text to the index, from where a
reference will be provided back to the tag location.

  Index \\X<this>!

All options can be \I<nested>:

  This text is \\I<\\B<\\X<italic, bold and indexed>>>.

Please take care to make \C<\\X> the innermost tag when nesting - otherwise, you would index
enclosed tags as well (and that's why PerlPoint treats this as an error).

  Invalid \\X<\\B<\\I<nesting>>>.

Borrowed from HTML like \C<\\F>, the \BCX<\\IMAGE> tag includes an image. It is that near to
HTML that several options are named as there: \C<src>, \C<alt> and \C<align> all work as
expected.

  \\IMAGE{src="image.png"}

\C<\\IMAGE> is an example of a tag that has \I<no body>. In fact, both option and body parts
can be optional, mandatory or forbidden. If this sounds complicated, rest assured: each tag
"knows" what it requires, and PerlPoint will warn you instantly if it finds a tag used the
wrong way.

Finally, it's easy to add \A{name="REF tag"}<links> to other parts of the document by using
\BCX<\\REF>.

  =This is our target

  bla bla

  =Here we add a reference

  See \RED<\\REF{name="This is our target" type=linked}<this chapter\>>.

\C<\\REF> has lots of options, but basically this is how you will use it most. This example
adds a \I<linked> reference to the chapter which is named by the \C<name> option. As you
can see, we refer to the target chapter by its name.

But targets do not need to be chapters. You can refer to any point in your document that was
marked as an anchor (which happens automatically to chapters). Anchors are set up by option
\BCX<\\A>:

  =Our chapter

  With an \RED<\\A{name="our anchor"}<anchor\>>.

  =Somewhere else

  Hey, go to this \BLUE<\\REF{name="our anchor" type=linked}<anchor\>>!

See the \OREF{n="Advanced linking"}<"Advanced linking"> chapter below for more features
offered by \C<\\REF>. For a complete reference of all basic tags, please refer to
\C<PerlPoint::Tags::Basic>.


===Macros

Some tags tend to be long if used with lots of options. But that's no problem as macros
are there to define shortcuts for them - or anything else you don't want to write again
and again.

A macro is defined in a special paragraph beginning with a \BCX<+>:

  +TEXT:A simple text.

After that definition, you can use it like a tag:

  \\TEXT

... and it will be replaced by the contents that was defined for it.

Of course such context can be more complicated. Here is an example that colorizes red:

  +RED:\\F{color=red}<__body__>

and can be used this way:

  \\RED<Red text!>

To make this work, the macro needs to know where to insert its body (\C<Red text!>) when
translating into the defined text. This is done by the \BCX<__body__> placeholder, so that
our example is equivalent to

  \\F{color=red}<Red text!>

.- but shorter ;-)

The right side of a macro definition can contain anything that is valid within a paragraph,
including other macros. So, with the definition

  +REDTEXT:\\RED<\\TEXT>

the text

  \\REDTEXT

would be translated into

  \\F{color=red}<A simple text.>

Here is an example of combined tags:

  +IBX:\\I<\\B<\\X<__body__>>>

Macros can be used to perform very complex tasks as we will see in the
\REF{name="Advanced features" type=linked}<advanced section>.
For now, in their simple form they offer an easy way to relieve a writer by defining
shortcuts.

As a further example, you might want to abbreviate the very long
\C<\\REF{name="..." type=linked}<...>> tag. The dotted parts are variable, and we instantly
see that this cannot be expressed with what we know now: we can inject the body part but
do not know how to deal with the variable option.

Fortunately, the placeholder syntax is generic. Here is the definition of a shortcut for
this case:

  +LREF:\\REF{name="\RED<__n__>" type=linked}<__body__>>

The \C<__n__> is a placeholder for a macro option \C<n> and will be replaced by its value.
So, we have defined a macro \C<LREF> with a body and an option \C<n> whitch takes the target
name. We can use it like this:

  See \\LREF{\RED<n="our anchor">}<there>.

With the definition above, this will be translated into

  See \\REF{name="our anchor" type=linked}<there>.


==Advanced features

Now that you are familiarized with the base language and converter usage you might want to learn
more about the features of PerlPoint. And there are more, as in this regard it is similar
to Perl: it is easy to start with while having powerful features for the advanced user.

Please note that for didactical reasons there had to be a point to start the "advanced"
section, but not all of the following parts are comparably complex. Just pick the chapters
that sound interesting to you, or read on chapter by chapter.

The general approach of PerlPoint remains the same for advanced topics: it tries to make
usage as intuitive as possible.

\ILLT

===Variables

Variables hold \I<literal> portions of PerlPoint code. This is handy for text that appears
quite often, like a link address:

  $cpan=http://search.cpan.org

Here we meet the typical paragraph approach again. Variables are declared and assigned in
special paragraphs beginning with a dollar character and the variable name, followed by the
assignment. Everything behind the equal sign is treated as the variables new value - old
values will be overwritten.

  \GREEN<// a variable value with whitespaces>
  $whiteVar=variable with whitespaces

To use a variable, we just insert it to the PerlPoint source:

  This paragraph makes use of a variable
  to point to \RED<$cpan>.

It's also possible to use it in a tag or macro option:

  Search \\L{url="\RED<$cpan>"}<CPAN>.

Variables are very handy to maintain a literal information (like a link) at a central place.
In this regard they are similar to \REF{name=Macros type=linked}<macros> but evaluated in
a different way:

* Variables are resolved \I<once> and \I<as literals>. Nested variables will not be resolved,
  nor are any PerlPoint syntax elements that might be included.

* While it is an error to refer to an undefined macro, it is valid to use an undefined
  variable. Undefined variables are treated as literal text.

* Being pure text, variables can be refered in templates.

\I<Similar> to macros, a backslash before a variable guards it from being evaluated.

  This \\$variable is treated as text.

As an example, I use variables to store document informations such as author name and mail
address, document date and version. Making this a convention allows to easily import those
informations into generated pages.

  \GREEN<// document data>
  \$docAuthor=Jochen Stenzel

  \$docAuthorMail=perl@jochen-stenzel.de

  \$docDate=2005-05-30

  \$docVersion=0.02

To reset a variable, just assign nothing:

  $var=


===Verbatim examples

\REF{name=Examples type=linked} are searched for \REF{name="Adding markup"
type=linked}<markup>. This
is very handy to highlight interesting parts, but has its disadvantages: all backslashes that
are not part of a tag or macro have to be escaped by an additional backslash. For large
chunks of code, this can be a nerveracking task, especially if one doesn't need highlightning.

So, verbatim example paragraphs allow to insert code (and anything) "as it is" - it will
neither be interpreted nor modified by PerlPoint.

A verbatim paragraph starts with a \RED<<<STRING> sequence, where \C<STRING> is any
identifier, and ends with the first line beginning with and consisting of only that very
string. Shell and Perl users will know this concept as "here documents". Here is an example:

  \RED<<<EOE>

    # Code here is not interpreted.
    $ref=\\$var.

  \RED<EOE>



===Sequences

Sometimes things need to be enumerated. Say you have a bunch of images and want to add
descriptions for them, as to be found in certain books. You could do this like this:

  \\CENTER<\\IMAGE{...}>

    Image \BLUE<3>.

  ...

  \\CENTER<\\IMAGE{...}>

    Image \BLUE<4>.


Of course this is not applicable for larger documents - and it becomes \I<impossible> if parts
of the document are written by others. Each new image would require to recheck all those
descriptions.

Automatic enumaration can help here. By having a possiblility to insert the next number of
a numerical sequence for a certain category, and by using this generic feature in image
descriptions, one can achieve a maintenance free but ever correct numbering. Such auto numbers
are available with the \RED<\CX<\\SEQ>> tag.

  \\CENTER<\\IMAGE{...}>

    Image \RED<\\SEQ{type=images}>.

  ...

  \\CENTER<\\IMAGE{...}>

    Image \RED<\\SEQ{type=images}>.

The category of a sequence number is assigned by option \CX<type>. The first time \C<\\SEQ>
is used for a certain category it evaluates to \C<1>. Each subsequent use for this same category
will increase the number returned.

  ...

  1: \\SEQ{type=number}

  2: \\SEQ{type=number}

  3: \\SEQ{type=number}

  ...

Sequences are counted throughout the whole document. They are never reset, so all parts can
safely rely on them - even in projects with many authors. Just make it a convention which
category names should be used for images, tables, bookmarks, footnotes or whatever you need.

The number of categories is not limited. By defining different categories you can number
everything you want. 

  ...

  ... image \\SEQ{type=\RED<images>} ...

  ... table \\SEQ{type=\RED<tables>} ...

  ... book \\SEQ{type=\RED<books>} ...

  ...

Further more, by using an additional feature of sequence numbers, each of them can be
individualized by a name. It is assigned by option \CX<name> and can be used to refer to a
certain sequence number item via \OREF{n="REF tag"}<\C<\\REF>>.

  Table \BLUE<\\SEQ{type=tables \RED<name="special table">}>:

  @|
  item | description
  bla  | bla bla

  ...

  ...

  ... please see table \BLUE<\\REF{\RED<name="special table">}> ...

And yes, the reference can be a link.

  ... please see table  \\REF{name="special table" \RED<type=linked>} ...



===Tables of Contents ~ TOCs

There are two types of \X<TOC>s in PerlPoint. One type is a list of subchapters, inserted by
the \BCX<\\LOCALTOC> tag. (See the end of this chapter for the second type.)

  \RED<\\LOCALTOC>

When the document will be processed, this line will be replaced by a table of contents
for all subchapters of the current section.

Why is this tag called \C<\I<LOCAL>TOC>? The "local" shows that you can use it anywhere, not
just at the documents beginning, to show a \I<partial> TOC and not the whole tree. A \I<local
TOC> lists all \I<sub>chapters of the current chapter level.

  =The ons and outs

  ==Three ways to switch the light on

  \RED<\\LOCALTOC>

  ===Use a shout and a noice sensor

  ===Switch it by a MagLight

  ===Traditionalists prefer a fix installation

  ==Switch it out

  ...

The TOC built in this example includes the three subchapters of "Three ways ...". If we would
have placed it a level above, "Three ways ..." and "Switch it out", would have become part of
the TOC as well.

  =The ons and outs

  \RED<\\LOCALTOC>

  ==Three ways to switch the light on

  ===Use a shout and a noice sensor

  ===Switch it by a MagLight

  ===Traditionals prefer a ...

  ==Switch it out

  ...

By the way, it is no error to have local TOCs on nested levels.

  =The ons and outs

  \RED<\\LOCALTOC>

  ==Three ways to switch the light on

  \RED<\\LOCALTOC>

  ===Use a shout and a noice sensor

  ===Switch it by a MagLight

  ===Traditionals prefer a ...

  ==Switch it out

  \RED<\\LOCALTOC>

  ...

In this example, each of the chapters on level 1 has its local TOC, while the subchapters on
level 2 have some as well.

A local TOC is often useful to fill an "empty page", in cases like this:

  =Useful Perl modules to catch options

  ==Getopt::Long

  ... ...

  ==Getopt::Std

  ... ...

  ==Getopt::ArgvFile

  ... ...

Structures like this use a container chapter to form a theme, but often there
is no text provided in the container itself. With a page oriented PerlPoint converter like
\C<pp2html>, this ends up with an empty slide (or page) for the container chapter. Using a
local TOC, it is easy to fill the space:

  =Useful Perl modules to catch options

  \RED<\\LOCALTOC>

  ==Getopt::Long

  ... ...

  ==Getopt::Std

  ... ...

  ==Getopt::ArgvFile

  ... ...

This gives readers an impression of what will follow, and simplifies navigation. Well ... it
could, if only the TOC was built of links. Till now, all we produced was raw text. But this
changes if we use the \BCX<type> option:

  \\LOCALTOC{\RED<type=linked>}

which instantly converts all subchapter entries into links, given that the output format
supports this.

Besides local TOCs, TOCs for the whole document are required. These are not inserted by a tag
but by a \IX<template> function, see below.


====Layout setup

The layout of a TOC is converter specific, which means that every converter can write a TOC
in its very own way. Nevertheless, you can specify what general format shall be used. This
is done by the \BCX<format> option.

By default, \C<format> is set to \CX<bullets>, which means a TOC will be displayed as a list
of bullet points.

  \GREEN<// this>
  \\LOCALTOC

  \GREEN<// is equivalent to>
  \\LOCALTOC{\I<format=\RED<bullets>>}

Here the chapter entries are just text, without chapter numbers. Chapter numbers can be added by
switching the format to \CX<numbers>:

  \\LOCALTOC{\I<format=\RED<numbers>>}

which produces a bullet list with numbered entries. The numbers are hierarchical, contain
sublevels and reflect the chapter numbers in the \I<document>. So, this example

  =Headline 1

  =Headline 2

  ==Headline 2.1

  \\LOCALTOC{\I<format=\RED<numbers>>}

  ===Headline 2.1.1.

  ===Headline 2.1.2.

would produce a bullet TOC with entries numbered \C<2.1.1.> and \C<2.1.2.>      

Different to this, the format \BCX<enumerated> uses simple \I<numbered lists>, which for the
example above produces a TOC like this:

  \RED<1.> Headline 2.1.1.
  \RED<2.> Headline 2.1.2.

An enumerated TOC list starts with number 1. Usually it contains no hierarchy. Every sublevel
starts with 1 again.

====How deep to go?

Remember what we said about "container chapters": local TOCs can be used to give an impression
of what will follow. This can help readers to get an overview, but is contra productive if the
subchapters have lots of sublevels.

  =Container

  \RED<\\LOCALTOC>

  ==Theme 1

  ===Subtheme 1.1

  ====Just more details

  ====Other details

  ===Subtheme 2.1

  ====Has details as well

  ====Even on a deeper level

  =====And deeper level ...

  ======...

From the containers point of view, often it's sufficient to
know what comes on the next level, without hints to all the hidden treasures and details.

The \BCX<depth> option advices \C<\\LOCALTOC> how much levels shall be included.

  \\LOCALTOC{\RED<depth=1>}

Here the \C<depth> setting limits the TOC to one subchapter level. Regardless of how deep
the hierarchy grows ... the TOC will remain general.


===Headline shortcuts

Many layouts include navigation links to previous and next pages, some of them using the
full title of those pages. That's good for users as they get an impression what will follow,
but can result in rather ugly pages if those titles are very long.

To work around this, PerlPoint allows to add \I<shortcuts> to a headline. Shortcuts are
short versions of the longer title and will be used in navigation links if available.
Problem solved!

Adding a shortcut to a headline is very easy - just enter the short title after the long
original, and separate them by a tilde (\BCX<~>).

  =A rather long headline title \RED<\B<~> Shortcut title>


===Advanced linking

In the \OREF{n=Tags}<tags chapter>, we already talked about \CX<\\REF> for linking. By passing
the title of a chapter or the name of a link via option \CX<name>, we can refer to that target.
By setting option \C<type> to \C<linked>, the tag body is made a link to there.

  ...
  
  \\U<\BLUE<\\A{\RED<name=Examples>}<Examples\>>>

  ...

  =Somewhere else

  Have a look at the \BLUE<\\REF{\RED<name=Examples type=linked>}<examples>>

Here we link to a document section with a special name, and the tag body (\C<examples>) is made
a link to the anchor \C<Examples>.

Ok, these are the basics, now let's have a look at the details.

// TOC
\ILLT


====Reference without label ~ Bodyless references

The concept of links we looked at so far was to make a piece of our text pointing to a chapter
or anchor. For this, we made this piece of text a \C<\\REF> tag body, and specified the link
target by the tags \C<name> option.

  \\REF{\BLUE<name=There>}<\RED<piece of text>>

With this concept, the \I<piece of text> was always displayed. Now thinking of typical documents
we quickly find cases where the text displayed should be something that is determined by the
thing we reference, not something we know when writing the link: the number of a chapter or the
title of a page that contains an anchor. And this becomes possible by \I<omitting the tag body>
- which is obvious as we just said we don't need a text that we know of at link time.

Here is an example:

  Chapter "\\REF{type=linked name="That chapter"}" told us ...

The tag has no body, and so the chapters name ("That chapter") is made the link text, which
relieves us from typing in it's title twice as in the long form

  Chapter "\\REF{type=linked name="\RED<That chapter>"}<\RED<That chapter>>" told us ...

And how to achieve display of the page number? A new option comes in for this, called
\CX<valueformat>. Its default value \CX<pure> makes appear the \I<value> of the referenced thing,
which in case of a chapter headline is this headline itself. And so, the

  Chapter "\\REF{type=linked name="That chapter"}" told us ...

example worked.

~hints

By the way, for links to \OREF{n=Sequences}<sequences> the value of a named sequence number
is the \I<number>, not the name:

  Image \RED<\\SEQ{\BLUE<name="block graph"> type=images}>.

  ...

  Looking at the \RED<\\REF{type=linked
  \BLUE<name="block graph">}>. image, we see
  that the block graph ...

so the last part of this example results in something like

  Looking at the \RED<5>. image, we see
  that the block graph ...

~main

Now to display the page number in a reference - just set \C<valueformat> to \CX<pagenr>.

  As mentioned in the \RED<\\REF{type=linked
  name=There \RED<valueformat=pagenr>}>. chapter, ....

Likewise, \CX<pagetitle> makes the \I<title> of a referenced chapter appear. Huh? Isn't that what is displayed
with \C<pure>? Not necessarily - think of sequences or anchors. \C<pure> for a sequence means
"show me the sequence number", while \C<pagetitle> says "show me the title of the chapter that
contains the numbered item". Same for anchors. For links to chapters, well, you're right, there's
no difference between \C<pure> and \C<pagetitle>.


====Reference, but do not link ~ Plain type

It might not have been obvious in the previous chapters, but the \C<type> \I<option> is - optional.
The reason for that is that is has a default, which is \CX<plain> and just means "do not link".

So we can have a reference that is no link? Yes, we can. And it makes sense in various situations.

First, the \I<text> a reference produces is the same whether we make it a link or not. And this text
by default is \I<the tag body>. So

  \\REF{name=There type=\BLUE<linked>}<there>

  \\REF{name=There type=\RED<plain>}<there>

only differ in the fact that "there" is made a link in the first case, and pure text in the second.

Yes, \C<\\REF{name=There type=plain}<there\>> (or \C<\\REF{name=There}<there\>>) produces
the same result as the plain, pure text \C<there>. Although this doesn't seem to make sense on
first sight, it makes things consistent - it can be used the same way in all cases. Think of
\OREF{n="Reference without label"}<bodyless references>:

  \GREEN<// use a sequence number in an image title>
  Image \\SEQ{name="block graph" type=images}.

  ...

  \GREEN<// make page number a \I<link>>
  Looking at the \\REF{type=\BLUE<linked>
  name="block graph"}. image, we see
  that the block graph ...

  \GREEN<// insert the page number, but
  // \I<without linking>>
  Looking at the \\REF{type=\RED<plain>
  name="block graph"}. image, we see
  that the block graph ...

  \GREEN<// same using default values>
  Looking at the \\REF{
  name="block graph"}. image, we see
  that the block graph ...

All we need to do in the last two example paragraphs is to have a number that corresponds to
the sequence number, we do not need to make it a link. It's for exactly that case that \C<plain>
was invented.

In the same way, references to page titles and page numbers of a reference target are often used
to insert just that title or number, not a link to them.

  As mentioned in the \\REF{name=There valueformat=pagenr}>. chapter
  ("\\REF{name=There valueformat=pagetitle}>"), ...


====Missing targets

Whether the target of a reference is located above or below it doesn't matter. But what if it
doesn't exist at all? By default, this is an \I<error> - a nonexisting target was probably
renamed or misspelled unintentionally. But taking into account what you can do with PerlPoint,
this rule not always makes sense:

* If you have a dynamic document with \OREF{n="Conditional parts"}<sections hidden occasionally>
  and link to an existing chapter, this chapter might be missing in the final document. The link
  \I<is correct>, but the (valid) target might disappear nevertheless.

* \OREF{n=Teamwork} allows you to combine documents by various authors. Given there's a
  common outline, authors could refer to chapters written by others. These chapters exist,
  the links are valid, but in the \I<local> document of a single author the targets are
  missed.

To deal with such cases, all we have to do is to add option \CX<occasion> to \C<\\REF>.

  As foretold in the \BLUE<\\REF{name=Intro type=linked
  \RED<occasion=1>}<introduction>>, we want to have a
  closer look at ...

Now, if the target cannot be found, PerlPoint no longer stops processing with a complaint.
Instead, it emits a warning to keep you informed - so you can check if the target is missed
by intention (or just misspelled).

~hints

By the way, the last example shows that we can wrap a line within a tag option area. The same
is true for the tag body - lines can be wrapped within as well.

  As foretold in the \\REF{name=Intro
  type=linked occasion=1}<\RED<introduction
  that was given a few chapters
  before>>, we ...

The reason this works is that the general rule of breaking lines in multiline paragraphs
\I<at whitespaces> applies exactly as for plain text.

~hints

If you do not want to write such long tags with many options, always remember you can declare
\OREF{n=Macros}<macros> to have handy shortcuts.

  \GREEN<// a macro for optional references>
  \RED<+OREF>:\\REF{name=__n__ type=linked occasion=1}<__body__>

  \GREEN<// and then:>
  As foretold in the \RED<\\OREF{n=Intro}<introduction\>>,
  we want to have a closer look at ...

~main

As for the \I<result>, \C<type=linked> is transformed into \OREF{n="Reference, but do not
link"}<\C<type=plain>> behind the scenes if a target is missed with \C<occasion>.


====Refer to this, or well, to that ... ~ Alternatives

\OREF{n="Missing targets"}<Optional references> allow us to refer to targets that might be
missing. The result will be a link in case the target is found, or plain text otherwise.

Now let's say in our document concept we have two chapters about a certain theme. One is
an introduction and rather short, while the other is very detailled. Because the intro is so
short it is quickly written and available in the very first version of our document ("publish
early and often"), while the detailled chapter remains a future plan for a longer time.

Now, if in the first versions (lacking the detailled chapter) we want to refer to a chapter
about that theme, for a valid link
we would need to use a reference to the intro chapter. Later on, when all the work is done and
the detailled chapter is available, we would have to replace such links by those to the then
existing detail chapter.

\I<Or> we could build a reference that switches \I<automatically> as soon as the detailled chapter
becomes available. And this is done by \C<\\REF> option \CX<alt>.

The \C<alt> option takes a comma separated list of possible targets. If the original target
(set by \C<name>) cannot be found, \C<\\REF> looks for \C<alt> and tries all the targets that are
listed there. The first target it finds is used.

~hints

If a link name in the alternatives list contains commata itself they need to be guarded by
backslashes, like so:

  \\REF{type=linked name=Invisible
  alt="Visible\RED<\\>, or sometimes not, Visible"
  }<link text>

~main

  \\REF{type=linked name=Invisible
  \RED<alt="Perhaps visible, Probably visible, Visible">
  }<link text>

Links like these are not only for prestructured documents in early versions. Chapters can always
be hidden by using \OREF{n="Conditional parts"}<conditional parts> - and multi target links are
a way to deal with that. Point to the chapter \I<that is actually included>.


===Document streams

Some day in the PerlPoint mailing list, Robert Inder asked for a way to get a layout like this:

      _______________________________________
     |                                       |
     |  _________________________________    |
     |  |                               |    |
     |  |    An Exciting Slide          |    |
     |  |                               |    |
     |  | * Point One                   |    |
     |  |                               |    |
     |  | * Point Two                   |    |
     |  |                               |    |
     |  | * Point Three                 |    |
     |  |                               |    |
     |  |<= Boring One       Another => |    |
     |  |-------------------------------|    |
     |                                       |
     | NOTES:                                |
     |                                       |
     | Point one is important because        |
     | blah blah                             |
     |                                       |
     | Point two really means that blah ...  |
     |                                       |
     |_______________________________________|

His idea was to have a region for the slide and another region for his notes. This was not
possible in the days of his question, but it is today. In order to get users the required
feature \I<document streams> were invented.

In general the request was to group certain parts of a chapter. And this is what docstreams
do.

\ILLT

====Defining document streams ~ Definition

A docstream is a section of a chapter that can include many paragraphs. It starts with a special
paragraph type and ends together with the chapter or another docstream start. The starting paragraph
has a \X<tilde> (\CX<~>) prefix and contains the name of the docstream.

   \BLUE<=An Exciting Slide>

   * Point One

   * Point Two

   * Point Three

   \RED<~notes>

   Point one is important because blah blah

   Point two really means that blah ...

   \BLUE<=Another>
    
This is a possible source for the slide that Robert requested. At the beginning of the chapter
(\C<\BLUE<=An Exciting Slide>>) the default stream \CX<main> is entered. Everything belongs to
this stream until the \I<stream start paragraph>, \C<\RED<~notes>>. All subsequent paragraphs
in this chapter now belong to that stream. So, the chapter really has \I<two> parts now.

   =An Exciting Slide

   \BLUE<* Point One>

   \BLUE<* Point Two>

   \BLUE<* Point Three>

   ~notes

   \RED<Point one is important because blah blah>

   \RED<Point two really means that blah ...>

The parts do not have to be defined in blocks, they can be interrupted by others. It's also
possible to have \I<many> streams in a chapter and not only two. Switching back to the main
stream is possible by using a \C<\RED<~main>> paragraph.

   =Streaming chapter

   This goes to the main stream.

   \RED<~notes>

   This is a note.

   \RED<~main>

   Back to the main stream.

   \RED<~secret notes>

   Notes of a special type.

   \RED<~main>

   Back to the main stream.

   \RED<~notes>

   Standard notes again.

Ok, fine, we have divided our chapter into parts. But to translate this into a layout like
Roberts, we have to go through two more steps:
\OREF{n="Document streams | Processing"}<processing> and
\OREF{n="Document streams | Layouts"}<layout definition>.

====Processing

Document streams are a relatively new feature - not all of the traditional converters support
them yet. If you are using another converter than \CX<perlpoint> please refer to its documentation
for docstream support.

With \C<perlpoint>, there are two options that control how docstreams are handled. First,
\CX<-dstreaming> is of interest. By default or with a value of \C<0>, docstreams are handled
as real streams. With a value of \C<1>, they are ignored - which means that all paragraphs
belonging to other docstreams than \CX<main> will be removed from the result as if they were
not written. And with a value of \C<2> streams are converted into subchapters.

The second control option is \CX<-skipstream>, which allows to filter out \C<certain> streams.
Remember Roberts request: he looked for a way to display slides and notes together. But what
if some day he needs only the slides? With \C<-skipstream> he could filter out the notes when
requested, without changes to his source. This makes it easy to produce exactly the version
that is required.

~hints

It is not possible to filter out the \C<main> stream.

~main

   \GREEN<# no streams at all>
   perlpoint \RED<-dstreaming 1>

   \GREEN<# no "notes" stream>
   perlpoint \RED<-skipstream notes>

Now if your options let some document streams intact as streams, it's time to have a look at
formatting and layout.

====Layouts

Document streams just label chapter parts, but they do not imply formatting. Robert, for
example, wished to display notes below the slide contents. But this is a matter of his special
layout, others might want to place their notes in a row besides the main text, or in a special
font. And of course there can be completely different needs as in this layout scheme:

  -------------------------------------
  |                                   |
  |            main stream            |
  |                                   |
  -------------------------------------
  |                 |                 |
  |  item 1 stream  |  item 2 stream  |
  |                 |                 |
  -------------------------------------
  |              stream 3             |
  -------------------------------------

Here two items are compared, each in its row, embedded into a common header and footer. So,
in fact the only way to control that is in the layout definition itself. To make this possible
the certain target language and formatter plugins mark streams a way that layout definitions
(\OREF{n="Writing styles"}<styles>) can access them. So, yes, one needs to read the language
and formatter module docs. As an example, we show how to do it in XHTML styles.

~hints

These hints are defined via document streams.

~main

Did you notice the short hints in this tutorial, displayed in light blue boxes like the example at
the right side? These hints are defined via document streams. The source of the example simply
is

   \RED<~hints>

   These hints are defined via document streams.

The XHTML pages are generated with \C<-target XML -format XHTML::Paged>. The \CX<XHTML::Paged>
formatter stores docstreams in a \C<<div\>> section, so that the example above is translated
into

  <div \RED<class="hints">>
    <p>These hints are defined via document streams.</p>
  </div>

Now with CSS, it's easy to format this part special. In the tutorials style there's one CSS
rule that says

   \GREEN</* hints */>
   \RED<.hints> {
           font-size: x-small;
           background-color: LightBlue;
           border: 5px solid LightBlue;
           margin: 3px;
           width: 400px;
           float: right;
          }

And that is all that is required. So, for XHTML output the key to formatting document streams
is CSS.


===Formatted tables

We already saw how \OREF{n=Tables}<simple tables> can be written. Just use the table
paragraph and write your rows and columns:

 @\RED<|>
 given name \RED<|> name    \RED<|> playing
 Peter      \RED<|> Paul    \RED<|> Guitar
 Paul       \RED<|> Newby
 Mary Ann   \RED<|> Shuttle \RED<|> Chess

The problem with this simple approach, if you want to call that a problem, is that all the
formatting is controled outside. You might be able to set up in the converter call or config
or style how tables should be layoutet, but the other side of this medal is that here in your
document you have almost no control about it.

And that's ok, given that it is considered good to separate layout issues from a documents
source.

Nevertheless, there are times when it seems you need more control. And that's why we added
table tags.

A table defined via tags looks like this:

 \RED<\\TABLE>
 given name \RED<|> name    \RED<|> playing
 Peter      \RED<|> Paul    \RED<|> Guitar
 Paul       \RED<|> Newby
 Mary Ann   \RED<|> Shuttle \RED<|> Chess
 \RED<\\END_TABLE>

So, what's the difference? The table starts with a \I<tag> (\CX<\\TABLE>), and it ends with
another tag (\CX<\\END_TABLE>). The rows are still lines, and the cells are still separated
by pipe characters. But these are only the defaults - dealing with tags now we can fine tune
the whole thing.

For example, we can add newlines. As they are no longer completing our table, there is no
reason not to have them if this makes our source more readable. Paul and Mary might be related:

 \\TABLE

 given name | name    | playing

 Peter      | Paul    | Guitar

 Paul       | Newby
 Mary Ann   | Shuttle | Chess

 \\END_TABLE

Or we could use another separator. With tags this is set up by the \CX<separator> option.

 \\TABLE{\RED<separator=")(">}
 given name \RED<)(> name    \RED<)(> playing
 Peter      \RED<)(> Paul    \RED<)(> Guitar
 Paul       \RED<)(> Newby
 Mary Ann   \RED<)(> Shuttle \RED<)(> Chess
 \\END_TABLE

Or we could add alignment with \CX<align>. In fact we can add most of the options that are valid
for HTML's \C<<table\>> tag - and as long as we produce \X<HTML> or \X<XHTML> they will be directly
passed to the \C<<table\>> tag that is generated for that table. (For other target languages
only subsets might be supported - which shows that these extensions are handy but not common.)

Does a tag table need to be placed at the beginning of a paragraph? No! It does not because
a tag is allowed everywhere in a paragraph - and that is true for table tags as well.

 Peter, Paul and Mary play different instruments: \RED<\\TABLE>
 given name | name    | playing
 Peter      | Paul    | Guitar
 Paul       | Newby
 Mary Ann   | Shuttle | Chess
 \RED<\\END_TABLE>, and that's well known for a long time.

But hey, this doesn't look better, does it? All these newlines make this construct rather hard
to read. No problem - rows can be separated by other strings as well - set up in
\CX<rowseparator>.

 Peter, Paul and Mary play different instruments:
 \BLUE<\\TABLE{\RED<rowsaparator="**">}> given
 name | name | playing \RED<**> Peter | Paul | Guitar
 \RED<**> Paul | Newby \RED<**> Mary Ann | Shuttle | Chess
 \BLUE<\\END_TABLE>, and that's well known for a long time.

Now we have a table that is completely inlined.


===Nested tables

\OREF{n="Formatted tables"}<Inlined tables> directly lead us to table nesting. If a whole table
can be expressed within a text paragraph, and all the separators are configurable, there is no
reason not to try this. And in fact, it works!

  \BLUE<\\TABLE{rowseparator="+++"}> column 1 \BLUE<|> column 2 \BLUE<|>
  \RED<\\TABLE{rowseparator="%%%"}> n1 \RED<|> n2 \RED<%%%> n3 \RED<|> n4 \RED<\\END_TABLE>
  \BLUE<+++> xxxx \BLUE<|> yyyy \BLUE<|> zzzzz \BLUE<+++> uuuu \BLUE<|> vvvv \BLUE<|> wwwww \BLUE<\\END_TABLE>

The cell separators do not need a redefinition - they always belong to the innermost table, seen
from their position.

Unfortunately, nested tables are not supported by all target languages. SDF, for example, does
not know them. So, if one is in need of them try if they work with a certain converter (parsing
will fail if not), or consult the manual of your converter. HTML and XHTML, for example, \I<do>
support nested tables and so do all PerlPoint converters that produce them.


===Active Contents

PerlPoint sources, as we know of till now, are \I<static> in nature. Everything is written
down in the sources and known at "writing time". But PerlPoint has \I<dynamic> parts as
well, meaning that Perl code is invoked to evaluate conditions or build sources on the
fly. This is known as "Active Contents".

As evaluating (user) code is potentially dangerous, Active Contents is disabled by default.
If you are sure you can trust the sources, it can be switched on by option \BCX<-active>:

  perlpoint \RED<-active> source.pp

But even then PerlPoint behaves defensive and runs the code snippets in a safe environment
(by \CPAN<Safe>). This environment denies all operations that might corrupt your system
and is configured by option \BCX<-safe>: if you are in need of more operations, you can allow
them by adding a \C<-safe> option to your call. The arguments of \C<-safe> are opcodes as
documented in Perls \CPAN<Opcode> manpage.

  perlpoint -active \RED<-safe sort -safe :browse> source.pp

It might take time to fine tune this compartment, but remember it's the safest way to run
code from external sources. If for any reason you cannot get the code to run, or if you
are absolutely sure you can trust the author of your PerlPoint sources, you can declare
everything as safe by using the special keyword \BCX<ALL>:

  perlpoint -active \RED<-safe ALL> source.pp



Active Contents includes

* \OREF{n="Conditional parts"}<conditional parts>,

* \OREF{n="Import filters: embed documents written in other formats"}<import filters>,

* \OREF{n="Paragraph filters: preprocess your paragraphs"}<paragraph filters>,

* \OREF{n="Document parts produced on the fly"}<embedded Perl>.


===Conditional parts

Sometimes not all parts of a source should be in included into a document. Think of handouts
which should not go into a presentation, second language versions which do not have to be
included into a document in the first language, solutions of training exersizes or advanced
parts of a course. PerlPoint allows to include and exclude such parts dynamically, depending
on conditions expressed in Perl code.

\REF{name="Active Contents" type=linked} needs to be activated to make conditions work,
otherwise all conditions will be treated as false.

\ILLT

====Source sections

The first type of conditionals manages complete document parts, including as many paragraphs
as necessary. "Including paragraphs" means "complete paragraphs", it is not possible to
make paragraph \I<parts> conditional this way. The reason for this is that this type uses
special paragraphs to mark where the conditional part begins and ends. The prefix of these
paragraphs is a \IX<question mark>.

  bla bla bla

  \RED<?> 0

  Something that is never included.

  \RED<?> 1

  This part is included in any case.

The question mark is followed by a \IX<Perl expression>. If the value of this expression is
\X<true>, well, then PerlPoint continues to read the document. But if the expression returns a
\X<false> value, all subsequent parts will be skipped until either a new condition paragraph
appears or the file is read completely.

So in our example above, \C<0> of course evaluates to a false value, and so the next paragraph
will never be processed. Then a second condition follows, and this time the condition evaluates
to a true value. So, after this paragraph PerlPoint continues processing.

Condition paragraphs are only seen by PerlPoint itself. As they are just controlling translation,
they do not appear in the results (HTML, XML or whatever).

Conditions of course can be more complex. They can be anything that is valid Perl code, but to
get readable sources it is recommended to hide complexity in function calls, like here

   ? \RED<shouldWeIncludeTheFollowing()>

The function can be declared in any other Active Contents part read before. A well working
technique is to use \CX<\\EMBED{lang=perl}> for this. This tag starts a section of embedded
Perl code which is evaulated only if Active Contents is enabled, and with the same rules.
In our current context, one important rule is that \I<all> Active Contents code lives in the same
namespace (\CX<main::> from the codes point of view), so function definitions, package variables
etc. can be shared.

Here is a definition of our "should-we-include-this" function:

~hints

Note that in the embedded Perl area newlines are allowed.

~main

   \\EMBED{lang=perl}

   \GREEN<# declare a function for conditions>
   sub shouldWeIncludeTheFollowing
    {
     1;
    }

   \GREEN<# supply an empty string as PerlPoint
   code to be processed>
   '';

   \\END_EMBED

I confess this is a rather simple function, but I think you get the point. Define whatever
function you need, of your prefered complexity. An effective way to do this is to have a
special \I<file> with \I<all> definitions etc. that should be used later on in conditions, and
to include this file in all the documents that make use of it.

   \GREEN<// include code>
   \\INCLUDE{type=perl file="code.pp" smart=1}

Some functions of general use are provided without any definition. These are ...


====Conditional tags

\ILLT

=====Failing intentionally (empty)

=====Ready before completion (empty)

===Index management (empty)

===Embedding target fragments (empty)

===Teamwork (empty)

===Embedding text files as examples (empty)

===Import filters: embed documents written in other formats (empty) ~ Import filters

====Existing filters

Several filters are provided via CPAN or the project page.

\UB<POD>



\UB<Open Office / OASIS Open Document>



====Writing a filter (empty)

===Paragraph filters: preprocess your paragraphs (empty) ~ Paragraph filters

===Document parts produced on the fly (empty) ~ Embedded Perl

===PerlPoint applications (empty)

==Macro examples

\ILLT

===Footnotes

Footnotes make a document look professional.\FNR{n="Footnotes: handy"}

Here are two macros that implement footnotes in PerlPoint:

  +FNR:\\SUP<\\F{size="-2"}<\\REF{type=linked name="__n__"}>>

  +FN:\\F{size="-2"}<\\SEQ{type=footnotes name="__n__"}: __body__>

\RED<\C<\\FNR>> is used to set a footnote \I<reference>. It adds a small note number as a
link to an anchor named by option \C<n>.

\RED<\C<\\FN>> makes this anchor, taking the same \C<n> parameter
to name it, and its body as the note. By making te anchor via \C<\\SEQ> we have an automatic
counter increased with each usage of the macro.

And here is a usage example:

  Bla bla bla bla bla \\FNR{n="bla"}

  Bla bla bla bla bla bla bla

  \GREEN<// footnotes>
  \\HR

  .\\FN{n="bla"}<Typically, this stands for
     any text.>

By using the dotted form of a text paragraph for the note we allow the note text to be wrapped
at any position.\FNR{n="Footnotes: dotted explanation"}

// footnotes
\HR

.\FN{n="Footnotes: handy"}<Besides, they are just handy ;-)>

.\FN{n="Footnotes: dotted explanation"}<Otherwise the explanation could not leave the first
   line without an parser error, as a tag starting a paragraph needs to be closed before the
   paragraph type can be determined.>


===CPAN links (empty)

===ISBN links (empty)

==Writing styles

// there could be sections both for pp2html and perlpoint

\ILLT

===Styles for pp2html (empty)

===Generator styles (empty)

\ILLT

====Directory structure (empty)

====Traditional templates

This template engine was designed to make it easy to transfer \C<pp2html> styles to
\C<perlpoint>. Most of the old features are available (under the same name), plus something
new.

Please note that old styles need to be transfered - they cannot be used directly. But
the good message is that this is easy.

\ILLT

=====Page scheme (empty)

=====Transforming a pp2html style (empty)

=====Including document information (empty)

=====Links to arbitrary chapters (empty)

=====Variable parts (empty)

====Using private template engines (empty)

====Using private generators (empty)

==Index

\INDEX


