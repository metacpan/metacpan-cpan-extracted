 

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.04    |12-02-2006| JSTENZEL | deleted <li> wrapping for embedded lists;
# 0.03    |03-16-2006| JSTENZEL | <li> wrapping embedded lists needs special CSS;
# 0.02    |01-21-2006| JSTENZEL | building filenames we use File::Spec::catfile() now;
#         |03-05-2006| JSTENZEL | in XHTML, <A> has an id attribute, but no name;
#         |          | JSTENZEL | headlines do not need anchors (as each chapter has its
#         |          |          | own page), deleted;
#         |03-09-2006| JSTENZEL | LOCALTOC: nested list wrapped in list points;
# 0.01    |05-07-2004| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::XML::XHTML::Paged> - generates paged XHTML via XML

=head1 VERSION

This manual describes version B<0.04>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Generator::XML::XHTML::Paged;

# declare package version
$VERSION=0.04;
$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2004-2006';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from common generator class
use base qw(PerlPoint::Generator::XML::XHTML);


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use Memoize;
use File::Basename;
use File::Spec::Functions;
use PerlPoint::Generator::XML;
use PerlPoint::Generator::Object::Page;
use PerlPoint::Constants qw(:DEFAULT :templates);

# = CODE SECTION =========================================================================


# provide help portions
sub help
 {
  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

This is the Generator::XML::XHTML::Paged synopsis.

EOS
  }
 }


# initializations done when a backend is available
sub initBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the XML base class
  $me->PerlPoint::Generator::XML::initBackend;

  # configure memoization (usefulness for buildFilename() depends on page
  # number and system capacity - for about 500 pages on a 128 MB Linux box, I got a 0.5 seconds
  # acceleration (this were about 1.8% acceleration if run without parsing))
  memoize('buildFilename') unless $me->{backend}->headlineNr<200;
 }



# headline formatter (unfortunately, we need an overwritten method here because paged
# output always displays first level headlines)
sub formatHeadline
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # build the headline (no need to store anchors, as every chapter has its own page so chapter links will point to pages)
  ($me->{xml}->h1(@{$item->{parts}}))
 }



# tag formatter
sub formatTag
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # declarations
  my ($directive, $xmltag, @results)=('');

  if ($item->{cfg}{data}{name} eq 'INDEXRELATIONS')
    {
     # get headline data
     my $data=[map {$_->[0]} @{$item->{cfg}{data}{options}{__data}}];

     # configure list tag
     my $xmllisttag=$item->{cfg}{data}{options}{format} eq 'enumerated' ? 'ol' : 'ul';

     # write list structure
     @results=$me->{$me->{xmlmode}}->div(
                                          # own class for easier CSS access
                                          {class=>'_ppIndexRelated'},

                                          # start with an intro, if specified
                                          exists $item->{cfg}{data}{options}{intro} ? $me->{$me->{xmlmode}}->p($item->{cfg}{data}{options}{intro}) : (),

                                          # list of related topics
                                          $me->{$me->{xmlmode}}->$xmllisttag(
                                                                             map
                                                                              {
                                                                               # get page title
                                                                               my $page=$me->page($_);
                                                                               my $title=$page->path(type=>'spath', mode=>'title');
                                                                               $title=join('', (map {"$_."} @{$page->path(type=>'npath', mode=>'array')}), " $title") if $item->{cfg}{data}{options}{format} eq 'numbers';

                                                                               # build list entry, type dependent (as link or plain string)
                                                                               $me->{$me->{xmlmode}}->li($item->{cfg}{data}{options}{type} eq 'linked' ? $me->{$me->{xmlmode}}->a({href=>$me->buildFilename($_)}, $title) : $title);
                                                                              } @$data,
                                                                            )
                                        );
    }
  elsif ($item->{cfg}{data}{name} eq 'LOCALTOC')
    {
     # local toc: subchapters defined?
     if (exists $item->{cfg}{data}{options}{__rawtoc__} and @{$item->{cfg}{data}{options}{__rawtoc__}})
       {
        # get type flag, store it more readable
        my $plain=($item->{cfg}{data}{options}{type} eq 'plain');

        # make a temporary headline path array copy
        my @localHeadlinePath=@{$page->path(type=>'fpath', mode=>'array')};

        # prepare a subroutine to build links, if necessary
        my $link;
        unless ($plain)
          {
           $link=sub
                  {
                   # take parameters
                   my ($level, $title)=@_;

                   # update headline path (so that it describes the complete
                   # path of the future chapter then)
                   $localHeadlinePath[$level-1]=$title;

                   # get the absolute number of the upcoming chapter
                   my $chapter=($me->getChapterByPath([@localHeadlinePath[0..$level-1]]))[0]->[0];

                   # supply the path of the upcoming chapter
                   $me->{$me->{xmlmode}}->a({href => $me->buildFilename($chapter)}, $title);
                  }
          }

        # use more readable toc variables
        my $toc=$item->{cfg}{data}{options}{__rawtoc__};
        my $wtoc=$item->{cfg}{data}{options}{__wellformedtoc__};

        # make it a list of the requested format
        if ($item->{cfg}{data}{options}{format} eq 'bullets')
          {
           my $levelbuilder;
           $levelbuilder=sub {$me->{xml}->ul(map {ref($_->[0]) ? $levelbuilder->($_) : $me->{xml}->li($plain ? $_->[1] : $link->(@$_));} @{$_[0]})};
           @results=$levelbuilder->($wtoc);
          }
        elsif ($item->{cfg}{data}{options}{format} eq 'enumerated')
          {
           my $levelbuilder;
           $levelbuilder=sub {$me->{xml}->ol(map {ref($_->[0]) ? $levelbuilder->($_) : $me->{xml}->li($plain ? $_->[1] : $link->(@$_));} @{$_[0]})};
           @results=$levelbuilder->($wtoc);
          }
        elsif ($item->{cfg}{data}{options}{format} eq 'numbers')
          {
           # make a temporary headline number array copy
           my @localHeadlineNumbers=@{$page->path(type=>'npath', mode=>'array')};

           # handle all provided subchapters (different to other formats, we do not have to take care of indentation
           # - the numerical sequences indent automatically)
           @results=$me->{xml}->ul(
                                   map
                                    {
                                     # get level and title
                                     my ($level, $title)=@$_;

                                     # update headline numbering
                                     $localHeadlineNumbers[$level-1]++;

                                     # add point
                                     $me->{xml}->li(
                                                    join('.', @localHeadlineNumbers[0..$level-1]), '. ',
                                                    $plain ? $title : $link->(@$_),
                                                   )
                                    } @$toc
                                  );
          }
        else
          {die "[BUG] Unhandled case $item->{cfg}{data}{options}{format}."}
       }
     else
       {
        # oops - there are no subchapters
        @results=();
       }
    }
  else
    {
     # invoke base method
     return $me->SUPER::formatTag(@_[1..$#_]);
    }

  # supply results
  # warn @results;
  @results;
 }


# page formatter
sub formatPage
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless $item;

  # store this slide - note that there is no frame in XHTML,
  # a slide just starts with its headline
  push(@{$me->{slides}}, $item->{parts})
    if @{$item->{parts}} and grep(ref($_)!~/::comment$/, @{$item->{parts}});

  # supply nothing directly
  '';
 }

# finish
sub finish
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the XML base class
  $me->PerlPoint::Generator::XML::finish;

  # templates can produce additional document files, give them a chance to do so
  # (those extra files are directly written, not passed through to here)
  if ($me->{template})
    {
     $me->{template}->transform(
                                action=>TEMPLATE_ACTION_DOC,
                               );

     # produce the TOC, if possible
     {
      my $fn=catfile($me->{options}{targetdir}, $me->buildFilename('toc'));
      my $handle=new IO::File(">$fn");
      print $handle $me->{template}->transform(
                                               action=>TEMPLATE_ACTION_TOC,
                                              );
     }

     # produce the index, if possible
     {
      my $fn=catfile($me->{options}{targetdir}, $me->buildFilename('index'));
      my $handle=new IO::File(">$fn");
      print $handle $me->{template}->transform(
                                               action=>TEMPLATE_ACTION_INDEX,
                                              );
     }
    }

  # write documents - process all pages
  my $nr=0;
  foreach my $slide (@{$me->{slides}})
    {
     # update page counter
     $nr++;

     # open result file
     my $filename=catfile($me->{options}{targetdir}, $me->buildFilename($nr));
     my $handle=new IO::File(">$filename");

     # start the page
     # print $handle $me->{xml}->xmldecl({version => 1.0,});
     confess $me unless defined $me;
     print $handle $me->{xml}->xmldtd(
                                      [
                                       # document type (needs to match the root element)
                                       'html',

                                       # external id
                                       qq(PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"),

                                       # DTD
                                       qq("http://www.w3c.org/TR/xhtml1/DTD/xhtml1-strict.dtd"),
                                      ]
                                     ), "\n\n";


     # generate page - use template if available
     if ($me->{template})
       {
        # ok, we have a template, pass in all necessary data and print the result
        print $handle $me->{template}->transform(
                                                 action=>TEMPLATE_ACTION_PAGE,
                                                 page=>$nr,
                                                 data=>join('', @$slide),
                                                );

        # templates can use supplementary files, so process them as well
        # (those extra files are directly written, not passed through to here)
        $me->{template}->transform(
                                   action=>TEMPLATE_ACTION_PAGE_SUPPLEMENTS,
                                   page=>$nr,
                                   data=>join('', @$slide),
                                  );
       }
     else
       {
        # no template - generate the page yourself
        print $handle $me->{xml}->html(
                                       {
                                        #xmlns      => qq("http://www.w3c.org/1999/xhtml"),
                                        #'xml:lang' => qq("en"),
                                        #lang       => qq("en"),
                                       },

                                       # add meta data part
                                       $me->{xml}->head(
                                                        # title (mandatory) ...
                                                        $me->{xml}->title($me->{options}{doctitle}),

                                                        # stylesheets
                                                        exists $me->{options}{css} ? map
                                                         {
                                                          # extract title and filename
                                                          my ($file, $title)=split(':', $me->{options}{css}[$_], 2);
                                                          $title="unnamed $_" if $_ and not $title;

                                                          $me->{xml}->link(
                                                                           {
                                                                            href => $file,
                                                                            $_ ? (title=>$title) : (), 
                                                                            rel  => $_<2 ? 'stylesheet' : 'alternate stylesheet',
                                                                            type => 'text/css',
                                                                           },
                                                                          )
                                                          } 0..$#{$me->{options}{css}} : (),

                                                        # add favicon link, if necessary
                                                        exists $me->{options}{favicon}
                                                          ? $me->xml->link(
                                                                           {
                                                                            href => $me->{options}{favicon},
                                                                            rel  => 'SHORTCUT ICON',
                                                                            type => 'image/ico',
                                                                           }
                                                                          )
                                                          : (),

                                                        # the "doc..." options are reserved for further data
                                                        # ... stored in meta tags
                                                        map
                                                         {
                                                          /^doc(.+)$/;
                                                          my $tag=$me->elementName("_$1");
                                                          $me->{xml}->meta({name=>$tag, contents=>$me->{options}{$_}}),
                                                         } sort grep((/^doc/ and not /^doctitle/), keys %{$me->{options}}),
                                                       ),

                                       # embed slides into the body section
                                       $me->{xml}->body(@$slide),
                                      ), "\n\n";
       }

     # close document
     close($handle);
    }
 }

# build page file name
my %filenameSuffixes=(
                      toc   => 'toc',
                      index => 'idx',
                     );

sub buildFilename
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $page)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # for reasons of convenience, we allow to pass in undefined values, and pass them through
  return undef unless defined $page;

  # supply resulting name, depending on the special or common character of the spec
  join('', "$me->{options}{prefix}-", $page=~/^\d+$/ ? $page : $filenameSuffixes{$page}, $me->{options}{suffix});
 }


# flag successfull loading
1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head1 SEE ALSO

=over 4

=item Base formatters

This formatter inherits from C<PerlPoint::Generator> and C<PerlPoint::Generator::XML>.

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

