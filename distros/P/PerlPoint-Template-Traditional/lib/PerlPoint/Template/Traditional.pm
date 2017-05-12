

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.02    |03.12.2005| JSTENZEL | producing better XHTML: empty tags closed (<tag />);
# 0.01    |08.07.2004| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Template::Traditional> - PerlPoint template processor for traditional pp2html layouts

=head1 VERSION

This manual describes version B<0.02>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Template::Traditional;

# declare package version and author
$VERSION=0.02;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2004-2006';


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# declare object data fields
use fields qw(
             );

# derive ...
use base qw(PerlPoint::Template);


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
use PerlPoint::Constants 0.17 qw(:templates);


# = CODE SECTION =========================================================================


=pod

=head2 new()


B<Parameters:>

=over 4

=item class

The class name.

=back

B<Returns:> the new object.

B<Example:>


=cut
sub new
 {
  # get parameter
  my ($class, %params)=@_;

  # check parameters
  confess "[BUG] Missing class name.\n" unless $class;

  # build and supply new object
  fields::new($class);
 }


# provide option declarations
sub declareOptions
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  (
   # new options
   [
    # template files: document templates (for files produced *once*)
    "doc_template=s@",

    # template files: header contents
    "header_template=s",
    "header_idx_template=s",
    "header_toc_template=s",

    # template files: body top
    "top_template=s",
    "top_idx_template=s",
    "top_toc_template=s",

    # template files: body bottom
    "bottom_template=s",
    "bottom_idx_template=s",
    "bottom_toc_template=s",

    # template files: navigation
    "nav_template=s",
    "nav_top_template=s",
    "nav_bottom_template=s",

    # template files: supplements
    "supplement_template=s@",
    "supplement_idx_template=s@",
    "supplement_toc_template=s@",

    # template strings
    "bot_left_txt=s",
    "bot_middle_txt=s",
    "bot_right_txt=s",
    "contents_header=s",
    "index_header=s",
    "label_contents=s",
    "label_index=s",
    "label_next=s",
    "label_prev=s",
    "top_left_txt=s",
    "top_middle_txt=s",
    "top_right_txt=s",

    # logo
    "logo_image_filename=s",

    # links
    "bootstrapaddress=s",     # address of the first page of the site (not necessarily generated);
    "startaddress=s",         # base address of the site, like a servers address - used to build absolute links to our pages;

    # link navigation
    "linknavigation",

    # tree applet support (in the tradition of pp2html)
    "appletdir|applet_dir=s", # target applet directory (allow "applet_dir" for backwards compatibility with pp2html);
    "appletref|applet_ref=s", # target applet directory reference (allow "applet_ref" for backwards compatibility with pp2html);

    "tree_app_hint=s",        # tree applet hint text, to be displayed if Java is deactivated;
    "tree_app_height=s",      # tree applet area height;
    "tree_app_width=s",       # tree applet area width;
    "tree_base=s",            # applet code directory;
   ],

   # there is no base option that we ignore
   [],
  );
 }


# provide help portions
sub help
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
               # template files: document files
               doc_template              => qq(),

               # template files: header contents
               header_template           => qq(),
               header_idx_template       => qq(),
               header_toc_template       => qq(),

               # template files: body top
               top_template           => qq(),
               top_idx_template       => qq(),
               top_toc_template       => qq(),

               # template files: body bottom
               bottom_template        => qq(),
               bottom_idx_template    => qq(),
               bottom_toc_template    => qq(),

               # template files: navigation
               nav_template           => qq(),
               nav_top_template       => qq(),
               nav_bottom_template    => qq(),

               # template strings
               bot_left_txt           => qq(),
               bot_middle_txt         => qq(),
               bot_right_txt          => qq(),
               contents_header        => qq(),
               index_header           => qq(),
               label_contents         => qq(),
               label_index            => qq(),
               label_next             => qq(),
               label_prev             => qq(),
               top_left_txt           => qq(),
               top_middle_txt         => qq(),
               top_right_txt          => qq(),

               # logo
               logo_image_filename    => qq(),

               # links
               bootstrapaddress       => qq(),
               startaddress           => qq(),

               # link navigation
               linknavigation         => qq(),

               # tree applet support
               appletdir              => qq(),
               applet_dir             => qq(),
               appletref              => qq(),
               applet_ref             => qq(),

               tree_app_hint          => qq(),
               tree_app_height        => qq(),
               tree_app_width         => qq(),
               tree_base              => qq(),
              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

In this call, you are using C<Template::Traditional> templates. The Traditional template engine
is intended to allow further use of C<pp2html> styles with new Generator based converters. It
supports most of the options and keywords of C<pp2html>'s styles, plus a few additional.

Compared to other templating systems like the Template Toolkit, PerlPoint::Traditional
templates are very straightforward. Simple keywords are replaced by certain replacements.
This isn't very sophisticated, but it has the advantage to not require any additional modules
installed. If you are not satisfied by this template language, please check out templates
using other engines - search CPAN for C<PerlPoint::Template::Xyz> modules.

=head3 Template files

Following the tradition of C<pp2html>, Traditional templates expect a I<page body> to be
described by up to I<four> files which embed the page contents. The layer scheme is shown
here:

 page body:    <body>

               top template

               optional top navigation template

               contents

               optional bottom navigation template

               bottom template

               </body>

Top and bottom template files are specified by options C<-top_template> and C<-bottom_template>
for kernel pages, and C<-top_idx_template> and C<-bottom_idx_template> for index pages, and
C<-top_toc_template> and C<-bottom_toc_template> for TOC pages.

Navigation template files are specified by C<-nav_top_template> and C<-nav_bottom_template>.
These files are optional, the options can be omitted. If top and bottom navigation template
are identical, one can use C<-nav_template> to specify them both at once.

The C<<body>> and C<</body>> tags are no part of the templates, they are added automatically.

While in C<pp2html> the header of a generated page was written automatically, it now became
template driven as well. Use option C<-header_template> (or C<header_idx_template> or
C<-header_toc_template>, respectively) to specify the appropriate template.

A header template is built according to the same rules as body (part) templates, although
there are template keywords that are designed for header use only, see below.

The following scheme shows the complete layer model, including tags added automatically. Those
tags should I<not> be written to the template files.

 page frame:   <html>

 page header:  <head>

               header template

               </head>

 page body:    <body>

               top template

               optional top navigation template

               - page contents -

               optional bottom navigation template

               bottom template

               </body>

 page frame:   </html>

Additionally, one can produce I<supplementary files> such as frames. These files are templated
completely, not in parts, and get specified by C<-doc_template> for files to be produced I<once>
and C<-supplement_template> (or  C<-supplement_idx_template> or  C<-supplement_toc_template>,
respectively) for page specific files. The names of those generated files depend on the template
names and are composed as a sequence of the C<-prefix> value, the template file basename, a dash,
the page number. another dash and the value of option C<-suffix> for page specific files
(C<<prefix>-<tfile>-<pagenumber><suffix>>, example: C<doc-baseframe-10.html>). For document
specific files templated via C<-doc_template>, the rule is C<<prefix>-<tfile><suffix>>, example:
C<doc-frameset.html>. Each of these template options can be specified multiply, to produce as
many files as you are in need of.

 Example: To produce a frameset with three frames
          (top, contents, bottom), we need a frameset
          file (one for all pages given we can navigate
          internally), and three frame files per chapter,
          which are the usual contents file plus two
          extra files for the page specific top and
          bottom frames.

          These options will do the job:

           -prefix doc -suffix .${\( lc($me->{generator}{options}{target}) )}

           -doc_template frameset.tpl
           -supplement_template topframe.tpl
           -supplement_template bottomframe.tpl

          plus the usual options to template the contents
          page (which is the middle frame here).

          As a result, we will get

            - one file doc-frameset.${\( lc($me->{generator}{options}{target}) )}
            - and three files per page:

               * doc-topframe-<page>.${\( lc($me->{generator}{options}{target}) )}
               * doc-<page>.${\( lc($me->{generator}{options}{target}) )}
               * doc-bottomframe-<page>.${\( lc($me->{generator}{options}{target}) )}

Knowing how the filenames are build, all files can be interlinked with ease.

=head3 Keywords

The keywords supported in Traditional templates are listed in the following.

=over 4

=item BOT_LEFT_TXT        

Inserts the text specified by option C<-bot_left_txt>.

=item BOT_MIDDLE_TXT      

Inserts the text specified by option C<-bot_middle_txt>.

=item BOT_RIGHT_TXT       

Inserts the text specified by option C<-bot_right_txt>.

=item BOOTSTRAP_ADDRESS

Inserts the URL specified by option C<-boostrapaddress>, pointing to the absolute start URL
(a page that does not need to be generated, by the way).

=item DATE(<format>)

This is a I<function> and will be replaced by the current data and time, formatted via
C<POSIX::strftime()>. The <format> is required in C<POSIX::strftime()> syntax.

 Example: DATE(%c)

=item DOCAUTHOR

The I<document> author, as specified by option C<-docauthor>.

=item DOCDATE

The document date/time string, as configured by option C<-docdate>.

=item DOCSUBTITLE

The I<document> subtitle, as specified by option C<-docsubtitle>.

=item DOCTITLE

The I<document> title, as specified by option C<-doctitle>.

=item LABEL_CONTENTS

Inserts the text specified by option C<-label_contents>.

=item LABEL_INDEX

Inserts the text specified by option C<-label_index>.

=item LABEL_NEXT

Inserts the text specified by option C<-label_next>.

=item LABEL_PREV

Inserts the text specified by option C<-label_prev>.

=item LOGO_IMAGE_FILENAME

=item OPT(<option>, <text>)

Inserts <text> if <option> is set. The <text> can contain further keywords, except for
nested C<OPT()> calls.

For reasons of parsing, make sure the closing paren is the last paren in the template
line, as the function consumes everything till there.

 Example: OPT(flavicon, <p>These pages use flavicons.</p>)

=item PAGE_CONTENTS

The page number of the TOC page.

=item PAGE_FIRST

The page number of the first page.

=item PAGE_HERE

The page number of the current page.

=item PAGE_INDEX

The page number of the index page, if any.

=item PAGE_LAST

The page number of the last page.

=item PAGE_NEXT

The page number of the next page, if any.

=item PAGE_PATH

This inserts the "path" of the current chapter, which is a sequence of (short) chapter titles
(being links to the chapters), leading from root to the current page. This is useful for
navigation, to allow readers quick jumps to higher level base chapters.

The start URL specified by C<-bootstrapaddress> always starts the path. Levels are delimited by
slashes.

 Example: If in the hierarchy of chapters

            1. Root Level

            1.1. Sublevel

            1.2. More about this

            1.2.1. Example

          the PAGE_PATH keyword should be replaced on every page,
          the result would be

            for 1.: Start URL

            for 1.1.: Start URL / Root Level

            for 1.2.: Start URL / Root Level

            for 1.2.1.: Start URL / Root level / More about this

=item PAGE_PREV

The page number of the previous page, if any.

=item PAGE_UP

The page number of the parent page.

=item REF(E<lt>separatorE<gt>E<lt>whitespace(s)E<gt>E<lt>address> E<lt>separatorE<gt> E<lt>textE<gt>)

A link to a document anchor, described by E<lt>addressE<gt>. Addresses are specified the same
way as in the C<name> option of C<\REF> tags, see there for details. The E<lt>textE<gt>
is used to set up the link text. Address and text are delimited by a string defined
as E<lt>separatorE<gt>. The whitespace after the separator definition is I<mandatory>,
more whitespaces can be used at your option.

Examples:

  REF(, An interesting chapter, Chapter)

  REF(--- Overview | perl, parl and PAR --- A PAR intro)

Closing parens within addresses or texts have to be preceeded by a backslash.

  REF(# Tools (par and parl\) # Tools)

=item START_ADDRESS

Inserts the URL specified by option C<-startaddress>, pointing to the very first page.

=item TREE_APPLET_TOC

Inserts code for the free Java navigation applet traditionally provided with C<pp2html>.
Different to C<pp2html>, the "Traditional" template engine does not generate applet TOC
pages on its own, but it supports styles that build such pages. To do so, just use this
wildcard in a TOC template specified by C<-top_toc_template> or C<-bottom_toc_template>.

If the wildcard is used, the template engine copies all necessary Java files into the
directory specified by option C<-appletdir>. Other related options are C<-appletdir>
(or C<-applet_dir>), C<-appletref> (or C<-applet_ref>), C<-tree_app_hint>, C<-tree_app_height>,
C<-tree_app_width> and C<-tree_base>.


=item TXT_CONTENTS

The title of the TOC page.

=item TXT_FIRST

The title of the first page.

=item TXT_HERE

The title of the current page.

=item TXT_INDEX

The title of the index page, if any.

=item TXT_LAST

The title of the last page.

=item TXT_NEXT

The title of the next page, if any.

=item TXT_PREV

The title of the previous page, if any.

=item TXT_UP

The title of the parent page.

=item TOP_LEFT_TXT        

Inserts the text specified by option C<-top_left_txt>.

=item TOP_MIDDLE_TXT      

Inserts the text specified by option C<-top_middle_txt>.

=item TOP_RIGHT_TXT       

=item TITLE

The I<page> title (chapter headline).

=item URL_CONTENTS

The URL of the TOC page.

=item URL_FIRST

The URL of the first page.

=item URL_HERE

The URL of the current page.

=item URL_INDEX

The URL of the index page, if any.

=item URL_LAST

The URL of the last page.

=item URL_NEXT

The URL of the next page, if any.

=item URL_PREV

The URL of the previous page, if any.

=item URL_UP

The URL of the parent page.

=item VAR(<var>) or VAR_AT_FINISH(<var>)

Inserts the value of the PerlPoint variable <var>, with the value available at the I<end>
of the chapter.

 Example: VAR(language)

=item VAR_AT_BEGIN(<var>)

Inserts the value of the PerlPoint variable <var>, with the value available at the I<beginning>
of the chapter.

 Example: VAR_AT_BEGIN(language)

=item CSS_LINKTAGS

Inserts tags to load CSS files specified by option C<-css>. The stylesheet specified first
will be made the main stylesheet, while all subsequently specified sheets will be included
as alternatives, in the order they were declared.

According to the specs, this keyword should be used in header templates only. (This will not
be checked by the template engine.)

=item DOC_METATAGS

According to the specs, this keyword should be used in header templates only. (This will not
be checked by the template engine.)

=item FAVICON_LINKTAG

Inserts a favicon link tag referring to the icon specified by option C<-favicon>. If the
option was omitted, the keyword will be replaced by an empty string.

For details about favicons, please see the description of C<-favicon>.

According to the specs, this keyword should be used in header templates only. (This will not
be checked by the template engine.)

=item LINK_NAVIGATION

Inserts navigation link tags as specified by the W3C (C<<link rel="start" ...>> etc.). Most
modern browsers translate them into navigation buttons to the first, previous, next etc. page.

According to the specs, this keyword should be used in header templates only. (This will not
be checked by the template engine.)

=item PAGE

The number of the current page. Counting starts with 1.

=item PAGE_CNT

The number of chapters (pages) in the document.

 Example: to display "page x of y", use

          PAGE/PAGE_CNT

=item TITLE

This will insert the document title, as specified by option C<-title>.

=back

=cut

EOS
  }
 }



# bootstrap
sub bootstrap
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base method
  $me->SUPER::bootstrap();

  # copy CSS and JavaScript files, if necessary
  my $dir=join('/', $me->{generator}{cfg}{setup}{stylepath}, $me->options->{style}, 'templates');
  foreach my $file (<$dir/*.css>, <$dir/*.js>)
    {
     # get basename
     my $basename=basename($file);

     # copy file, if necessary
     if (
             not -e "$me->{generator}{options}{targetdir}/$basename"
         or -M "$me->{generator}{options}{targetdir}/$basename" > -M $file
        )
       {
        warn "[Info] Copying ", $file=~/\.css$/i ? 'CSS' : 'JavaScript', " file $file to target directory $me->{generator}{options}{targetdir}.\n";
        copy($file, $me->{generator}{options}{targetdir}) or die "[Fatal] Could not copy $file to $me->{generator}{options}{targetdir}.\n";
       }
    }

  # configure applet options as necessary
  $me->{options}{tree_app_hint}='Please, activate Java.' unless exists $me->{options}{tree_app_hint};
  $me->{options}{tree_app_height}=400 unless exists $me->{options}{tree_app_height};
  $me->{options}{tree_app_width}=200  unless exists $me->{options}{tree_app_width};
  $me->{options}{appletdir}=$me->{options}{targetdir} unless exists $me->{options}{appletdir};

  if (not exists $me->{options}{appletref})
    {
     if ($me->{options}{appletdir} eq $me->{options}{targetdir})
       {$me->{options}{appletref}='.';}
     else
       {
        if ($me->{options}{appletdir}=~m(^/))
          {
           # we got an absolute path, use it
           $me->{options}{appletref}=$me->{options}{appletdir};
          }
        else
          {
           # we got a relative path, absolutify it and use the result
           my ($base, $path, $type)=fileparse($me->{options}{appletdir});
           $me->{options}{appletref}=join('/', abs_path($path), basename($me->{options}{appletdir}));
          }
       }
    }

  $me->{options}{tree_base}=$me->{options}{appletref} unless exists $me->{options}{tree_base};

  # make applet target directory, if necessary
  if (exists $me->{options}{appletdir} and not -d $me->{options}{appletdir})
    {
     warn "[Info] Making tree applet directory $me->{options}{appletdir}.\n" unless exists $me->{options}{noinfo};
     mkpath($me->{options}{appletdir});
    }
 }


# check usage
sub checkUsage
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::checkUsage;

  # get options
  my $options=$me->options;

  # check mandatory options
  foreach (qw(header_template top_template bottom_template))
    {die qq([Fatal] "Traditional" templates require option -$_.\n) unless exists $options->{$_};}

  # check mandatory files
  foreach (qw(header_template top_template bottom_template))
    {
     my $filename="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates/$options->{$_}";
     die qq([Fatal] Missing "Traditional" "-$_" template file "$options->{$_}".\n) unless -e $filename;
    }

  # check files belonging to optional options
  foreach (
           qw(
              doc_template

              header_idx_template
              header_toc_template

              top_idx_template
              top_toc_template

              bottom_idx_template
              bottom_toc_template

              nav_template
              nav_idx_template
              nav_toc_template

              supplement_template
              supplement_idx_template
              supplement_toc_template
             )
          )
    {
     # skip check if option unused
     next unless exists $options->{$_};

     # template options can specify one or multiple files
     unless (ref $options->{$_})
       {
        my $filename="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates/$options->{$_}";
        die qq([Fatal] Missing "Traditional" "-$_" template file "$options->{$_}".\n) unless -e $filename;
       }
     else
       {
        # process each file
        foreach my $template (@{$options->{$_}})
          {
           my $filename="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates/$template";
           die qq([Fatal] Missing "Traditional" "-$_" template file "$template".\n) unless -e $filename;
          }
       }
    }

  # flag success
  1;
 }


# the transformator
sub transform
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my %params)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing action parameter.\n" unless exists $params{action} and defined $params{action};
  unless (
             $params{action}==TEMPLATE_ACTION_DOC
          or $params{action}==TEMPLATE_ACTION_TOC
          or $params{action}==TEMPLATE_ACTION_INDEX
         )
    {
     confess "[BUG] Missing page number parameter.\n" unless exists $params{page} and defined $params{page};
     confess "[BUG] Missing data parameter.\n" unless exists $params{data} and defined $params{data};
    }

  # declarations
  my ($result)=('');

  # get options
  my $options=$me->options;

  # build template directory path
  my $tdir="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates";

  # transform source data into a string, if required

  # act action dependent: generate document pages
  $params{action}==TEMPLATE_ACTION_DOC and do
    {
     # first look if there are supplements to process
     if (exists $options->{doc_template})
       {
        # process each supplement
        foreach my $template (@{$options->{doc_template}})
          {
           # process template (use first page number)
           my $string=$me->_processTemplate("$tdir/$template", 1);

           # build file name
           my $filename=join('', "$options->{targetdir}/$options->{prefix}-", (fileparse($template, qr(\.[^.]+)))[0], $options->{suffix});

           # write file
           open(SUPPFILE, ">$filename") or die qq([Fatal] Could not open output file "$filename": $!.\n);
           print SUPPFILE $string;
           close(SUPPFILE);
          }
       }
    };

  # act action dependent: generate a (toc) page
  ($params{action}==TEMPLATE_ACTION_PAGE or $params{action}==TEMPLATE_ACTION_TOC) and do
    {
     # anything to do?
     return if $params{action}==TEMPLATE_ACTION_TOC and not exists $options->{header_toc_template};
     my $toc=$params{action}==TEMPLATE_ACTION_TOC;

     # start page
     $result.="\n\n<html>\n\n";

     # begin header
     $result.="\n\n<head>\n\n";

     # header contents: this was added to the traditional list of template files
     $result.=$me->_processTemplate(join('/', $tdir, $options->{$toc ? 'header_toc_template' : 'header_template'}), $toc ? 1 : $params{page});

     # complete header
     $result.="\n\n</head>\n\n";

     # begin body
     $result.="\n\n<body>\n\n";

     # now the body contents: start with top part
     $result.=$me->_processTemplate(join('/', $tdir, $options->{$toc ? 'top_toc_template' : 'top_template'}), $toc ? 1 : $params{page});

     # add navigation, if necessary
     $result.=$me->_processTemplate(join('/', $tdir, $options->{$toc ? 'nav_toc_template' : 'nav_template'}), $toc ? 1 : $params{page})
       if exists $options->{$toc ? 'nav_toc_template' : 'nav_template'};

     # include data (for TOCs, make sure not to add a standard TOC if the tree applet is used
     # - this should be more generic in case users use other methods ...)
     $result.=$toc ? $result=~/<applet code="TreeApp\.class" codebase=/ ? '' : $me->_toc() : $params{data};

     # add bottom navigation, if necessary
     $result.=$me->_processTemplate(join('/', $tdir, $options->{$toc ? 'nav_toc_template' : 'nav_template'}), $toc ? 1 : $params{page})
       if exists $options->{$toc ? 'nav_toc_template' : 'nav_template'};

     # finally, add the bottom part
     $result.=$me->_processTemplate(join('/', $tdir, $options->{$toc ? 'bottom_toc_template' : 'bottom_template'}), $toc ? 1 : $params{page});

     # close the body
     $result.="\n\n</body>\n\n";

     # and complete the page
     $result.="\n\n</html>\n\n";
    };


  # act action dependent: generate supplements
  $params{action}==TEMPLATE_ACTION_PAGE_SUPPLEMENTS and do
    {
     # first look if there are supplements to process
     if (exists $options->{supplement_template})
       {
        # process each supplement
        foreach my $template (@{$options->{supplement_template}})
          {
           # process template
           my $string=$me->_processTemplate("$tdir/$template", $params{page});

           # build file name
           my $filename=join('', "$options->{targetdir}/$options->{prefix}-", (fileparse($template, qr(\.[^.]+)))[0], "-$params{page}$options->{suffix}");
           warn "= PAGE SUPPLEMENT =====> $filename\n";

           # write file
           open(SUPPFILE, ">$filename") or die qq([Fatal] Could not open output file "$filename": $!.\n);
           print SUPPFILE $string;
           close(SUPPFILE);
          }
       }
    };

  # retransform string result into a special data format, if required

  # supply result
  $result;
 }



# helper functions ##########################################################

# process a template
sub _processTemplate
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($file, $page))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing template file parameter.\n" unless $file;
  confess "[BUG] Missing page data parameter.\n" unless $page;

  # declare variables
  my (@result);

  # common preprocessing
  my $td=$me->preprocessData($page);

  # get options
  my $options=$me->options;

  # stylesheet links
  my $cssLinkTags=join('', exists $options->{css} ? map
                                                     {
                                                      # extract title and filename
                                                      my ($file, $title)=split(':', $options->{css}[$_], 2);
                                                      $title="unnamed $_" if $_ and not $title;

                                                      # add css links
                                                      join('',
                                                           qq(<link href="$file"),
                                                           $_ ? qq( title="$title") : '', 
                                                           ' rel="',  $_<2 ? 'stylesheet' : 'alternate stylesheet', '"',
                                                           qq( type="text/css"),
                                                           qq( />\n),
                                                          );
                                                     } 0..$#{$options->{css}} : (),
                      );

  # add favicon link, if necessary
  my $faviconLinkTag=exists $me->{options}{favicon} ? qq(<link href="$me->{options}{favicon}" rel="SHORTCUT ICON" type="image/ico" />\n) : '';

  # the "doc..." options are reserved for further data ... stored in meta tags
  my $docMetaTags='';
  for (sort grep((/^doc/ and not /^doc(_|title)/), keys %$options))
    {
     /^doc(.+)$/;
     my $tag=$me->{generator}->elementName("_$1");
     $docMetaTags.=join('', qq(  <meta name="$tag" content="$options->{$_}" />\n)) if exists $options->{$_};
    };

  # add more meta tags, if necessary
  $docMetaTags.=qq(  <meta name="ROBOTS" content="NOINDEX, NOFOLLOW" />\n) if exists $options->{norobots};
  $docMetaTags.=qq(  <meta name="MSSmartTagsPreventParsing" content="true" />\n) if exists $options->{nosmarttags};

  # prepare <link> navigation if required
  my $linkNavigation='';
  if (exists $options->{linknavigation})
    {
     # activate available elements
     $linkNavigation.=qq(  <link rel="start" href="$td->{fFile}" />\n) if $td->{fFile};
     $linkNavigation.=qq(  <link rel="prev"  href="$td->{pFile}" />\n) if $td->{pFile};
     $linkNavigation.=qq(  <link rel="next"  href="$td->{nFile}" />\n) if $td->{nFile};
     $linkNavigation.=qq(  <link rel="up"    href="$td->{uFile}" />\n) if $td->{uFile};
     $linkNavigation.=qq(  <link rel="last"  href="$td->{lFile}" />\n) if $td->{lFile};

     # the contents link is always available
     $linkNavigation.=qq(  <link rel="contents" href="$td->{tocFile}" />\n);

     # add the index link, if possible
     $linkNavigation.=qq(  <link rel="index" href="$td->{indexFile}" />\n) if $td->{indexFile} and not exists $options->{no_index};
    }

  # prepare the linked page path
  my $cPath=join(' / ', map {join('', qq(<a href="$_->[0]">$_->[1]</a>));} @{$td->{cPath}});

  # ok, open template
  open(TPL, $file) or die "[Fatal] Can't open template $file: $!\n";

  # replace placeholders
  while (<TPL>)
    {
     # optional parts (evaluate them first, to allow placeholders in substitutions)
     s/OPT\((.+?),\s*(.+)\s*\)/exists $options->{$1} ? $2 : ''/ge;

     # process static placeholders
     s/\bTITLE\b/$td->{title}/g;
     s/\bCSS_LINKTAGS\b/$cssLinkTags/g;
     s/\bFAVICON_LINKTAG\b/$faviconLinkTag/g;
     s/\bDOC_METATAGS\b/$docMetaTags/g;
     s/\bLINK_NAVIGATION\b/$linkNavigation/g;

     s/URL_FIRST/$td->{fFile}/g;
     s/TXT_FIRST/$td->{fText}/g;
     s/PAGE_FIRST/$td->{fNumber}/g;

     s/URL_HERE/$td->{cFile}/g;
     s/TXT_HERE/$td->{cText}/g;
     s/PAGE_HERE/$td->{cNumber}/g;

     s/URL_LAST/$td->{lFile}/g;
     s/TXT_LAST/$td->{lText}/g;
     s/PAGE_LAST/$td->{lNumber}/g;

     s/URL_PREV/$td->{pFile}/g;
     s/TXT_PREV/$td->{pText}/g;
     s/PAGE_PREV/$td->{pNumber}/g;

     s/URL_NEXT/$td->{nFile}/g;
     s/TXT_NEXT/$td->{nText}/g;
     s/PAGE_NEXT/$td->{nNumber}/g;

     s/URL_UP/$td->{uFile}/g;
     s/TXT_UP/$td->{uText}/g;
     s/PAGE_UP/$td->{uNumber}/g;

     # what's this meant to be???
#     s/<[\s\w="]*URL_DOWN[\s"]*?>/$url_down/g;
#     s/TXT_DOWN/$txt_down/g;

     # addresses of specific pages
     s/URL_CONTENTS/$td->{tocFile}/g;
     s/URL_INDEX/$td->{indexFile}/g;

     # page data
     s/\bPAGE_CNT\b/$td->{pageNr}/g;
     s/\bPAGE\b/$page/g;
     s/PAGE_PATH/$cPath/g;

     # various straight forward keyword/option translations
     s/TXT_CONTENTS/exists $options->{contents_header} ? $options->{contents_header} : ''/geo;
     s/TXT_INDEX/exists $options->{index_header} ? $options->{index_header} : ''/geo;
     s/BOOTSTRAP_ADDRESS/exists $options->{boostrapaddress} ? $options->{boostrapaddress} : ''/geo;
     s/START_ADDRESS/exists $options->{startaddress} ? $options->{startaddress} : ''/geo;
     foreach my $keyword (qw(
                             BOT_LEFT_TXT        
                             BOT_MIDDLE_TXT      
                             BOT_RIGHT_TXT       
                             DOCAUTHOR
                             DOCDATE
                             DOCSUBTITLE
                             DOCTITLE
                             LABEL_CONTENTS
                             LABEL_INDEX
                             LABEL_NEXT
                             LABEL_PREV
                             LOGO_IMAGE_FILENAME
                             PREFIX
                             SUFFIX
                             TOP_LEFT_TXT        
                             TOP_MIDDLE_TXT      
                             TOP_RIGHT_TXT       
                            )
                         )
       {s/$keyword/exists $options->{lc($keyword)} ? $options->{lc($keyword)} : ''/ge;}

     # "functions"
     s/DATE\((.+?)\)/strftime($1, localtime)/ge;
     s/REF\((\S+)\s+(.+)(?:\s*\1\s*(.+))(?<!\\)\)/$me->{generator}->buildAnchorLink($2, defined($3) ? $3 : ())/ge;

     # variables
     s/VAR(_AT_FINISH)?\((.+?)\)/exists $td->{cVars}{$2} ? $td->{cVars}{$2} : ''/ge;
     s/VAR_AT_BEGIN\((.+?)\)/exists $td->{pVars}{$1} ? $td->{pVars}{$1} : ''/ge;

     # special: tree applet index
     if (/TREE_APPLET_TOC/)
       {
        # copy applet classes, if necessary
        my $appletSrcDir="$me->{generator}{cfg}{setup}{stylepath}/$me->{generator}{options}{style}/templates/applet_src";
        die("[Fatal] No applet source directory in ", dirname($appletSrcDir), ".\n") unless -d $appletSrcDir;
        foreach my $appletfile (sort <$appletSrcDir/*.class>)
          {
           # get image basename
           my $basename=basename($appletfile);

           # copy image, if necessary
           if (
                   exists $me->{options}{appletdir}
               and (
                       not -e "$me->{options}{appletdir}/$basename"
                    or -M "$me->{options}{appletdir}/$basename" > -M $appletfile
                    )
              )
             {
              # inform user, unless suppressed
              warn qq([Info] Copying tree applet file $appletfile to $me->{options}{appletdir}.\n) unless exists $me->{options}{noinfo};

              # perform action
              copy($appletfile, $me->{options}{appletdir});
             }
          }

        # begin the applet code string
        my $applet=<<EOA;

<applet code="TreeApp.class" codebase="$options->{tree_base}" alt="$options->{tree_app_hint}" name="Tree" width="$options->{tree_app_width}" height="$options->{tree_app_height}">
<param name=bgColor value="FFFFFF">
<param name=font value="Helvetica-plain-14">
<param name="rootTitle" value="$options->{doctitle};book.gif,o_book.gif;;$options->{doctitle}">
<param name="expanded" value="true">
<param name="baseURL" value="./">

EOA

        # add hints for all pages
        foreach my $chapter (1..$td->{pageNr})
          {
           # get short path in the required format (levels delimited by slashes)
           my @apath=@{$me->page($chapter)->path(type=>'spath', mode=>'array')};
           my $apath=join('/', @apath);
           die "[Fatal] Missing levels in $apath.\n" if grep(not (defined), @apath);

           # update applet string
           $applet.=join('', qq(<param name="item$chapter" value="$apath;book.gif,o_book.gif;), $me->buildFilename($chapter), qq(,Data;$apath">\n));
          }

        # complete applet code
        $applet.="\n</applet>\n\n";

        # ok, replace the wildcard
        s/TREE_APPLET_TOC/$applet/g;
       }

     # finally, add the transform lines to the result string
     push(@result, $_);
    }

  # close template file
  close(TPL);

  # supply result
  join('', @result);
 }


# build a toc
sub _toc
 {
  # get and check parameters
  my ($me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # declare variables
  my (@result);

  # common preprocessing
  my $td=$me->preprocessData(1);

  # add entries for all pages
  foreach my $chapter (1..$td->{pageNr})
    {
     # get short path in the required format (levels delimited by slashes)
     my @apath=@{$me->page($chapter)->path(type=>'spath', mode=>'array')};
     my $apath=join('/', @apath);
     die "[Fatal] Missing levels in $apath.\n" if grep(not (defined), @apath);

     # add string
     push(@result, join('', qq(<p class="s), scalar(@apath), qq("><a href="), $me->buildFilename($chapter), qq(">$apath[-1]</a></p>\n)));
    }

  # supply result
  join('', @result);
 }




# flag successful loading
1;

# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head1 SEE ALSO

=over 4



=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2004-2006.
All rights reserved.

This module is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

The Artistic License should have been included in your distribution of
Perl. It resides in the file named "Artistic" at the top-level of the
Perl source tree (where Perl was downloaded/unpacked - ask your
system administrator if you dont know where this is).  Alternatively,
the current version of the Artistic License distributed with Perl can
be viewed on-line on the World-Wide Web (WWW) from the following URL:
http://www.perl.com/perl/misc/Artistic.html


=head1 DISCLAIMER

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

