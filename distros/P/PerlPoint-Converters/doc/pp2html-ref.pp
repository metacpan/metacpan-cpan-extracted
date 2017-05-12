
// vim: set filetype=pp2html:
+PP:PerlPoint

$TOP_BGCOLOR=#AFBDCA

=Introduction

This is the reference manual for \C<pp2html>. The \C<pp2html> program is a tool to convert simple
text files written in \PP format to a set of HTML files which can be presented with a
normal web browser. This can be used both for making presentations and for creating
documents for the intranet or internet.

The most important features of \C<pp2html> are:

* Simple ASCII file in \PP format as source

* Automated generation of table of contents and navigation

* Optional index generation

* Possibility for simple character formatting

* Optional frame sets

* Support for TreeApplet in table of contents

* Possibility to include other \PP files

* Embedding of Perl code

\B<Further reading>

Please have also a look at the following documents:

* \L{url="../Getting-Started/index.htm" target=_blank}<Getting Started>

//* pp2html Tutorial

* \L{url="../FAQ-pp2html/index.htm" target=_blank}<pp2html FAQ>

* \L{url="../FAQ-Parser/index.htm" target=_blank}<PerlPoint Parser FAQ>

* \L{url="../Writing-Converters/index.htm" target=_blank}<Writing PerlPoint converters>

//* Style Guide



=Installation

\X{mode=index_only}<Installation>For using \PP and pp2html you need the following components:

* Perl 5.005.03 or better

* Storable

* Digest::SHA1

* Digest::MD5

* Getopt::ArgvFile

* PerlPoint-Package

* PerlPoint-Converters

* Test::Harness

* Test::Simple

An easy way to install all the needed modules is the following:

  perl -MCPAN -e 'Bundle::PerlPoint'

To install a module you must do the following steps:

# Get the module form CPAN.

# Unpack the tar.gz or .tgz file and cd to the new module directory, for example:

 % gunzip PerlPoint-Package-0.35.tgz
 % cd PerlPoint-Package-0.35

## Make and install the package:

 % perl Makefile.PL
 % make test
 % make install

If you do not have write permission in the standard Perl installation path you may install
the modules in your home directory:

 % perl Makefile.PL PREFIX=$HOME

This will install the package somewhere in ./lib/perl5/... under your home. Don't forget to
set \C<PERL5LIB> to include the corresponding paths. Otherwise the new modules will not be found
in \C<@INC>.

\B<Special hint for NT or Win9x systems:>

Versions before 0.35 of \B<PerlPoint-Package> may have problems with the \C<--cache> option.
Disable this option in the .cfg option files for the pp2html examples.

=Sources and Support

* All mentioned components for the installation can be found on CPAN.

* Support should be found in the mailing list for \PP:

  perlpoint@perl.org

To join the \X<mailing list>, send a message to \C<perlpoint-subscribe@perl.org>

If you prefer, you can also contact the authors directly:

  lorenz.domke@gmx.de 

  perl@jochen-stenzel.de

=Running pp2html

To run \C<pp2html> you need an input file in \PP format (see \SECTIONREF{name="PerlPoint Syntax"}
and eventually an \XREF{name="Option Files"}<option file> to specify all the options you want to use.

All possible options are describe in the \SECTIONREF{name="Options"} chapter.

Here are some examples for calls to \C<pp2html>:

 # Change to the directory where the input file is 
 # located and start pp2html:

 pp2html input.pp

 pp2html -target_dir ./slides -title="\PP" input.pp

 pp2html @my_options.cfg input.pp

 pp2html -style big_blue -style_dir /home/PP/styles input.pp




=PerlPoint Syntax

==Paragraphs

The following paragraph types are used by \C<pp2html>:

* Comments paragraphs

* Headline paragraphs

* Text paragraphs

* Block paragraphs

* Verbatim block (here documents)

* List paragraphs

* Table paragraphs

* Condition paragraphs

* Variable assignment paragraphs

* Macro paragraphs

\INCLUDE{type=PP file="parser-paragraphs.pp" headlinebase=2}
//\INCLUDE{type=PP file="parser-paragraphs.pp"}

==Tags

\INCLUDE{type=PP file="parser-tags.pp" headlinebase=2}


\INCLUDE{type=PP file="tagdoc-example.pp" headlinebase=2}


=Options

This chapter describes all options of \C<pp2html>.
There are many of them but don't be afraid. There is no need to
specify them all on the commandline. Have a look at the chapter
about \SECTIONREF{name="Option Files"}.


\INCLUDE{type=PP file="pp2html-ref-options.pp"}

==Option Files


It is recommended to write an \I<\X<option file>> for each of your \PP presentations or
documents. Just write down all options you need in a file, line by line:

 # Option file for my cool presentation:

 --title "How to make Slides"
 --target_dir ./pp-slides
 --style big_blue
 --style_dir /home/PerlPoint/pp2html_styles

Then you can call \C<pp2html> with \C<@options.cfg>

  pp2html @options.cfg how-to-make-slides.pp

For more information about option files please refer to the \B<Getopt::ArgvFile> manpage:

 perldoc Getopt::ArgvFile

=Using Templates

==Simple Layout

The most simple case is to not use any template files. This will just create
a set of HTML files containing the headers and texts you noted in your input file.
This is inconvenient as you have no navigation hyperlinks (except the links which
have been created in the table of contents, \I<slide0000.htm>)

You can create simple HTML fragments as top and bottom templates:

\B<File:> simple_top.tpl

  <TABLE bgcolor="#AFBDCA" width=100% cellpadding=5 cellspacing=0>
    <TR>
      <TD width=20%><img src="Logo.gif"></TD>
      <TD align=center>TITLE</TD>
      <TD align=right width=20%>August 2001</TD>
    </TR>
  </TABLE>

\B<File:> simple_bot.tpl

 <TABLE WIDTH=100%  BORDER=0 CELLSPACING=0 CELLPADDING=2>
 <TR>
   <TD border=0>
   </TD>
  <TD VALIGN=top ALIGN=right ><SMALL>
     Copyright &copy; 
     <a href="mailto:Lorenz.Domke@gmx.de">Lorenz Domke</a><br>
     All rights reserved.
     </SMALL>
  </TD>
 </TR>
 </TABLE>

Then use this by calling

 pp2html --top_template simple_top.tpl \\
   --bottom_template simple_bot.tpl -title "Cool Slides" input.pp

In a similar manner you create navigation templates for top and/or bottom
navigation bars which contain simple HTML tables. The cells may be colored
and you use the URL_NEXT, TXT_NEXT etc. keywords. These keywords are 
automatically replaced with hyperlinks to the corresponding pages and with
the page headers respectively.

See the examples in the \C<pp2html_styles> subdirectory of the PerlPoint-Converters
package.

==Frame Set Layout

If you want to create framesets you must use a frameset template.
This looks like:

 <html>
 <head>
   <title>TITLE</title>
 </head>
 
 <frameset border=0 frameborder=0 framespacing=0 rows="60, *, 60">
     <frame src="./pp_book-top.htm" name="Top">
     <frameset border=0 frameborder=0 framespacing=0 cols="205, *">
       <frame src="slide0000.htm" name="Index">
       <frame src="slide0001.htm" name="Data">
     </frameset>
     <frame src="./pp_book-bot.htm" name="Foot">
 </frameset>

 <body>
   Please call the <a href="slide0000.htm">titel page</a>
 </body>
 </html> 

This defines a frameset with four frames.  The "Index" frame and the "Data" frame
start with the table of contents page and the first page of the presentation.
"Top" and "Foot" frame use fixed templates. All the templates are copied to the
target directory by \C<pp2html> and keywords like "TITLE" are replaced with corresponding
values.

See also the examples in the \C<pp2html_styles> subdirectory of the PerlPoint-Converters
package.

==Keyword Replacement

Template files may contain some keywords in capital letters which are
automatically replaced with corresponding values when the pages are
created. The most important are

  PAGE
  TITLE
  URL_PREV
  URL_NEXT
  URL_INDEX

See the \XREF{name="--bottom_template=filename"}<--bottom_template> option and
the  \XREF{name="top_left_txt"}<--top_left_txt> option for more information.

==Using Styles


Using styles is simple. You need to specify the \C<--style> option and eventually the
\C<--style_dir> option if the styles directory is not a subdirectory of the current
working directory:

 pp2html --style pp_book --style_dir /home/PP/styles input.pp

A typical option file for usage with styles looks like:

 --activeContents
 --safeOpcode ALL
 --cache
 --slide_dir orange_slides
 --image_ref .
 --count_only
 
 --style orange_slides
 --style_dir ./pp2html_styles
 --base_left_txt '&copy; <a href="mailto:lorenz.domke@gmx.de">lorenz.domke@gmx.de</a>'
 --base_right_txt "June 2001"
 --logo_image_filename Logo.gif

This activates active contents and the cache. The target directory for the slides is
specified and the path for referencing images in <IMG> tags is defined.
The \C<--count_only> switch suppresses the output of all headers of the created pages.

The second block defines the style to be used and overwrites some of the texts used in the
styles template files.
                   

=Cache

To speed up the processing of large documents, \PP provides a caching mechanism. If your input
file is named \I<xyz>.pp, the \PP Parser will create a cache file called .\I<xyz>.pp\B<.ppcache>.
To take advanage of this feature you must specify the \C<--cache> option because caching is not
enabled by default. The cache file can be cleared with the \C<--cacheCleanup> option.

Some of the possibilites of using active contents are demonstrated in the following section.

\INCLUDE{type=PP file="parser-active-contents.pp"}

=Trouble Shooting

Often you will encounter syntax errors in your input file. The \PP parser tries to
issue some useful error message but sometimes it is difficult to locate the problem.

In this situation you can use the \C<--trace 2> switch to activate output from the lexer:

  pp2html --trace 2 @options.cfg input.pp

This means that all token are printed on \B<stdout> so that you can easily see, where the
parser stops.

=Appendix


==Literature, Links

This chapter presents some hints for further reading.

See for example:

* \C<http://www.reportlab.com/demos/pythonpoint/pythonpoint.html>

  The GNU Portable presenter, available on CPAN (PPresenter)

* Contribution to the Third German Perl-Workshop 2001:
  \C<http://www.perlworkshop.de/2001/contributions/PerlPoint/pptalk/slide0001.htm>

* Article in the \C<Linux Enterprise> magazine (\C<http://www.linuxenterprise.de> 
  issue 7, 2001: "Auf dem Präsentierteller"

