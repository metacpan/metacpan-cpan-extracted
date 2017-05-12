

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |08.07.2004| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Template> - PerlPoint template handler

=head1 VERSION

This manual describes version B<0.01>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Template;

# declare package version and author
$VERSION=0.01;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2004';


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# declare object data fields
use fields qw(
              generator
              options
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use File::Copy;
use File::Basename;


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
  confess "[BUG] Missing generator parameter.\n" unless exists $params{generator};
  confess "[BUG] Generator parameter is no PerlPoint::Generator object.\n" unless $params{generator}->is('PerlPoint::Generator');
  confess "[BUG] This method should be called via its own package only.\n" unless $class eq __PACKAGE__;

  # get options
  my $options=$params{generator}->options();

  # check environment: style specified?
  die "[Fatal] Templates cannot be used without a style, please set -style.\n" unless exists $options->{style} or exists $options->{help};

  # check environment: template prepared to handle our target language?
  die "[Fatal] Please use option -templatesAccept to specify which targets are handled by your templates.\n" unless exists $options->{templatesAccept};
  {
   my %acceptedTargets;
   @acceptedTargets{@{$options->{templatesAccept}}}=();
   die "[Fatal] $options->{formatter} formatted target $options->{target} ist not supported by the templates in style $options->{style}.\n"
     unless exists $acceptedTargets{"$options->{target}/$options->{formatter}"};
  }

  # declarations
  my __PACKAGE__ $plugin;

  # check for a template directory in the current style
  unless (exists $options->{help} or -d "$params{generator}{cfg}{setup}{stylepath}/$options->{style}/templates")
    {die "[Fatal] No template directory in style $options->{style}.\n";}
  else
    {
     # try to load the template class
     my $pluginClass=join('::', __PACKAGE__, $options->{templatetype});
     eval "require $pluginClass" or die "[Fatal] Missing template engine class $pluginClass, please install it ($@).\n";
     die $@ if $@;
  
     # build our object as an instance of the *plugin* class and check it
     $plugin=$pluginClass->new();
     confess "[BUG] Template class $pluginClass does not inherit from ", __PACKAGE__, ".\n" unless $plugin->isa(__PACKAGE__);

     # check API
     foreach (qw(declareOptions bootstrap transform))
       {die "[BUG] Template class $pluginClass does not not provide required method $_().\n" unless $plugin->can($_);}
    }

  # init attributes
  $plugin->{generator}=$params{generator};
  $plugin->{options}=$options;             # this is a copy by intention (templates cannot overwrite originals!)

  # supply new object
  $plugin;
 }


# bootstrap
sub bootstrap
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # perform usage checks
  $me->checkUsage or die;

  # copy image files, if necessary
  my $dir=join('/', $me->{generator}{cfg}{setup}{stylepath}, $me->options->{style}, 'templates');
  foreach my $file (<$dir/*.gif>, <$dir/*.jpg>, <$dir/*.png>)
    {
     # get basename
     my $basename=basename($file);

     # copy file, if necessary
     if (
             not -e "$me->{generator}{options}{targetdir}/$basename"
         or -M "$me->{generator}{options}{targetdir}/$basename" > -M $file
        )
       {
        warn "[Info] Copying template image file $file to target directory $me->{generator}{options}{targetdir}.\n";
        copy($file, $me->{generator}{options}{targetdir}) or die "[Fatal] Could not copy $file to $me->{generator}{options}{targetdir}.\n";
       }
    }
 }


# check usage
sub checkUsage
 {
  # currently this is a fallback in case child classes do not define it on their own
  1;
 }

# provide generator object
sub generator
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # provide the aggregated object
  $me->{generator};
 }


# provide options (the module itself does not provide any options at the moment, but in case
# all derived classes don't this is well and do not define this method, this method here
# serves as a fallback so that objects of the Template hierarchy always can call options())
sub options
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # provide data (we don't add anything to the base options)
  $me->{options};
 }


# provide help portions
sub help
 {
  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
              },

   # supply synopsis part
   SYNOPSIS => join("\n\n", "\n\n=head2 Templates", <<EOS), # complicated to pass PAR (pp)

Templates allow to specify common page (part) patterns, specialized for certain pages via
keywords or functions. Various templating systems are around, and it is basically possible
to use I<each> of them in conjunction with PerlPoint. Nevertheless, there need to be "engine"
modules available, which help to pass data back and forth between the PerlPoint system and
your templates.

EOS
  }
 }


# common preprocessing: provide usually used data in a template independent data structure
sub preprocessData
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;

  # declare variables
  my ($rc);

  # get options
  my $options=$me->options;

  # get page number
  $rc->{pageNr}=$me->numberOfChapters();

  # get data of the first page
  $rc->{fNumber}=$me->pageBySpec('first', $page);
  $rc->{fPage}=$me->page($rc->{fNumber});
  $rc->{fFile}=$me->buildFilename($rc->{fNumber});
  $rc->{fText}=$rc->{fPage}->path(type=>'spath', mode=>'title');

  # get data of the current page
  $rc->{cPage}=$me->page($page);
  $rc->{cFile}=$me->buildFilename($page);
  $rc->{cText}=$rc->{cPage}->path(type=>'spath', mode=>'title');
  $rc->{cVars}=$rc->{cPage}->vars();

  # get data of the parent page (one level above)
  $rc->{uNumber}=$me->pageBySpec('up', $page);
  $rc->{uPage}=$me->page($rc->{uNumber});
  $rc->{uFile}=$me->buildFilename($rc->{uNumber}) || '';
  $rc->{uText}=defined $rc->{uPage} ? $rc->{uPage}->path(type=>'spath', mode=>'title') : '';

  # get data of the previous page
  $rc->{pNumber}=$me->pageBySpec('previous', $page);
  $rc->{pPage}=$me->page($rc->{pNumber});
  $rc->{pFile}=$me->buildFilename($rc->{pNumber}) || '';
  $rc->{pText}=defined $rc->{pPage} ? $rc->{pPage}->path(type=>'spath', mode=>'title') : '';
  $rc->{pVars}=defined $rc->{pPage} ? $rc->{pPage}->vars() : {};

  # get data of the next page
  $rc->{nNumber}=$me->pageBySpec('next', $page);
  $rc->{nPage}=$me->page($rc->{nNumber});
  $rc->{nFile}=$me->buildFilename($rc->{nNumber}) || '';
  $rc->{nText}=defined $rc->{nPage} ? $rc->{nPage}->path(type=>'spath', mode=>'title') : '';

  # get data of the last page
  $rc->{lNumber}=$me->pageBySpec('last', $page);
  $rc->{lPage}=$me->page($rc->{lNumber});
  $rc->{lFile}=$me->buildFilename($rc->{lNumber});
  $rc->{lText}=$rc->{lPage}->path(type=>'spath', mode=>'title');

  # prebuild more replacement strings
  $rc->{doctitle}=$me->{generator}{options}{doctitle};
  $rc->{title}=$rc->{cPage}->path(type=>'fpath', mode=>'title');
  $rc->{tocFile}=$me->buildFilename('toc');
  $rc->{indexFile}=$me->buildFilename('index');

  # the page path has to be produced with links
  my $cc=0;
  my $pnArray=$rc->{cPage}->path(type=>'ppath', mode=>'array');
  my $csArray=$rc->{cPage}->path(type=>'spath', mode=>'array');
  $rc->{cPath}=[(exists $me->{options}{bootstrapaddress} ? [$me->{options}{bootstrapaddress}, 'Start'] : ()), map {[basename($me->buildFilename($pnArray->[$cc++])), $_];} @$csArray[0 .. $#{$csArray}-1]];

  # supply data (does this need to become an object?)
  $rc;
 }



# GENERATOR METHOD WRAPPERS ###########################################################

# To simplify the usage of the template module, we provide wrappers for various
# generator methods. Yes, this slows things down, but improves usability.

sub numberOfChapters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # pass call through
  shift;
  $me->{generator}->numberOfChapters(@_);
 }

sub pageBySpec
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # pass call through
  shift;
  $me->{generator}->pageBySpec(@_);
 }

sub page
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # pass call through
  shift;
  $me->{generator}->page(@_);
 }

sub buildFilename
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing path arguments.\n" unless @_>1;

  # pass call through
  shift;
  $me->{generator}->buildFilename(@_);
 }




# display a class specific copyright message
sub _classCopyright
 {
  my ($class)=@_;

  my $rootClass=__PACKAGE__;
  $class=ref($class) if ref($class);
  return '' unless $class and $class=~/^$rootClass/;

  no strict 'refs';
  (_classCopyright(@{join('::', $class, 'ISA')}), join('', $class, ' ', $class->VERSION, ' (c) ', ${join('::', $class, 'AUTHOR')}, ".\n"));
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2004.
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

