

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |17.11.2005| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Template::TT2> - beta of a PerlPoint template processor for Template Toolkit 2 layouts

=head1 VERSION

This manual describes beta version B<0.01>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Template::TT2;

# declare package version and author
$VERSION=0.01;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2005-2006';


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# derive ...
use base qw(PerlPoint::Template);

# declare object data fields
use fields qw(
              docdata
              tt2
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use Template;
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

  # build new object
  my $object=fields::new($class);

  # build TT2 object - TODO: EVAL_PERL should be configured by an option
  $object->{tt2}=new Template({ABSOLUTE=>1, EVAL_PERL=>1});

  # supply object
  $object;
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
    "docTemplate|doc_template=s@",

    # template files: supplements
    "supplement_template=s@",
    "supplement_idx_template=s@",
    "supplement_toc_template=s@",

    # template strings - none so far

    # logo - non so far

    # links
    "bootstrapaddress=s",     # address of the first page of the site (not necessarily generated);
    "startaddress=s",         # base address of the site, like a servers address - used to build absolute links to our pages;
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
               docTemplate               => qq(),

               # template strings

               # logo

               # links
               bootstrapaddress       => qq(),
               startaddress           => qq(),
              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

In this call, you are using C<Template::TT2> templates. The TT2 template engine
is intended to allow using Template Toolkit to write C<PerlPoint::Generator> styles.

B<Note: at this place the API should be described. Sorry that it is missing now,
that is one reason to declare this release an early beta.>

In general, you get a complete document structure for use in the template. Please
use the TT2 features to dump the structure, or have a look at the S5 example in the
C<PerlPoint-styles> distribution for a first impression.

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
  foreach (qw(docTemplate))
    {die qq([Fatal] "TT2" templates require option -$_.\n) unless exists $options->{$_};}

  # check mandatory files
  foreach (qw(docTemplate))
    {
     foreach my $template (ref($options->{$_}) ? @{$options->{$_}} : $options->{$_})
      {
       my $filename="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates/$template";
       die qq([Fatal] Missing "TT2" "-$_" template file "$template".\n) unless -e $filename;
      }
    }

  # check files belonging to optional options
  foreach (
           qw(
              supplement_template
              supplement_idx_template
              supplement_toc_template
             )
          )
    {
     # skip check if option unused
     next unless exists $options->{$_};

     # template options can specify one or multiple files
     foreach my $template (ref($options->{$_}) ? @{$options->{$_}} : $options->{$_})
      {
       my $filename="$me->{generator}{cfg}{setup}{stylepath}/$options->{style}/templates/$template";
       die qq([Fatal] Missing "TT2" "-$_" template file "$template".\n) unless -e $filename;
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

  # generate document data structure unless done before
  unless ($me->{docdata})
   {push(@{$me->{docdata}}, $me->preprocessData($_)) for 1..$me->numberOfChapters;}

  # act action dependent: generate document pages
  $params{action}==TEMPLATE_ACTION_DOC and do
    {
     # first look if there is a template defined
     if (exists $options->{docTemplate})
       {
        # process each supplement
        foreach my $template (@{$options->{docTemplate}})
          {
           # build file name
           my $filename=join('', "$options->{targetdir}/$options->{prefix}-", (fileparse($template, qr(\.[^.]+)))[0], $options->{suffix});

           # process template and write target file
           $me->_processTemplate("$tdir/$template", 'all', $params{slides}, $filename);
          }
       }
    };

  # act action dependent: generate a (toc) page
  ($params{action}==TEMPLATE_ACTION_PAGE or $params{action}==TEMPLATE_ACTION_TOC) and do
    {
=pod
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
=cut
    };


  # act action dependent: generate supplements
  $params{action}==TEMPLATE_ACTION_PAGE_SUPPLEMENTS and do
    {
=pod
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
=cut
    };

  # retransform string result into a special data format, if required

  # supply result
  $result;
 }



# helper functions ##########################################################


# process a template for a certain page or the whole document, supply the result
sub _processTemplate
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($template, $page, $slides, $targetfile))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing template file parameter.\n" unless $template;
  confess "[BUG] Missing page parameter.\n" unless $page;
  confess "[BUG] Invalid page parameter $page.\n" unless $page=~/^(\d+|all)$/;
  confess "[BUG] Missing target file name parameter.\n" unless $targetfile;

  # declare variables
  my (@result);

  # get options, define buffer
  my ($options, $string)=$me->options;

  # process template and write target file
  $me->{tt2}->process(
                      # template file
                      $template,

                      # the page data structure
                      {
                       options => $me->options,        # options
                       page    => $page,               # page number
                       docdata => $me->{docdata},      # document data (structure, no contents except headlines)
                       slides  => $slides,             # prepared content
                      },

                      # target file name
                      $targetfile
                     ) or die $Template::ERROR;
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2005-2006.
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

