

#
# This is a template file, intended to be used as a startup frame when writing new formatters.
# Search for TODO remarks and follow the instructions therein.
#
# Optional methods are marked.
#
 

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |<data>    | <author> | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::LANGUAGE::Formatter> - generates Formatter formatted LANGUAGE files

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
package PerlPoint::Generator::LANGUAGE::Formatter;

# declare package version
$VERSION=0.01;
$AUTHOR='<author> (<mail>), <(c)-year>';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from common generator class
use base qw(PerlPoint::Generator::LANGUAGE);

# declare object data fields
use fields qw(
              # TODO: insert the fields you need
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use PerlPoint::Constants;
use PerlPoint::Converters;
use PerlPoint::Generator::LANGUAGE;  # older perls need this, newer perls do it with "use base"

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
  confess "[BUG] Missing options hash.\n" unless exists $params{options};

  # build object
  my $me;
  $me=fields::new($class);

  # store options of interest (really necessary?)
  $me->{options}{$_}=$params{options}{$_}
   for grep(exists $params{options}{$_}, qw(
                                           ),
           );

  # supply new object
  $me;
 }


# provide option declarations
sub declareOptions
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # start with the base options
  $me->readOptions($me->SUPER::declareOptions);

  # now add your own
  (
   [
    # TODO: add options used by this formatter, in Getopt::Long syntax.
    #       Remember to supply help for your options in help(), see below.
    "example=s",                 # an example option;
   ],

   # and base options that we ignore
   [
    # TODO: list options of base classes that become *invalid* by using this formatter.
    qw(
       baseexample
      ),
   ],
  );
 }


# provide help portions
sub help
 {
  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
               # TODO: supply help for all options that were added by this module
               #       (see declareOptions() above). Use the option name as keys
               #       and the help texts as values of your entries. You may embed
               #       POD markup, but please dont use headlines and lists.
               example => qq(an example option),
              },

   # supply synopsis part
   # TODO: add a *formatter specific* part of the SYNOPSIS that is displayed when
   #       a user specifies -help. Your part will be mixed with others, hierarchically.
   #       Make sure to check the result.
   SYNOPSIS => <<EOS,

According to your formatter choice, the LANGUAGE produced will be formatted by I<Formatter>.

EOS
  }
 }


# provide source filter declarations
#
# TODO: adapt this method to reply a list of patterns for languages that can be embedded into
#       PerlPoint sources when using this formatter. Please note that both base classes can
#       provide a list already, which you might want to extend or restrict.
#
# OPTIONAL METHOD: if you don't want to modify the inherited list, just remove this method.
#       
sub sourceFilters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # get the common parent class list, replace a few items and provide the result
  (
   grep($_!~/^example$/i, $me->SUPER::sourceFilters),  # parent class list, but we do not support pure EXAMPLE
   "myown",                                            # embedded MYOWN;
  );
 }

# check usage
sub checkUsage
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class (checks translations as well)
  $me->SUPER::checkUsage;

  # adapt tag translations (allows to use several standard XML converters)
  $me->{options}{tagtrans}=[
                            qw(
                               TABLE_COL:td
                               TABLE_HL:th
                               TABLE_ROW:tr
                               anchor:a
                               dlist:dl
                               dpointitem:dt
                               dpointtext:dd
                               example:pre
                               olist:ol
                               opoint:li
                               text:p
                               ulist:ul
                               upoint:li
                              )
                           ];

  # check your own options
  die "[Fatal] Please specify the name of the result file by -xmlfile.\n" unless exists $me->{options}{xmlfile};
  not -e $me->{options}{xmlfile} or -w _ or die "[Fatal] XML file $me->{options}{xmlfile} cannot be written.\n";
 }


# sub bootstrap
#  {
#   # get and check parameters
#   (my __PACKAGE__ $me)=@_;
#   confess "[BUG] Missing object parameter.\n" unless $me;
#   confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

#   # don't forget the base class
#   $me->SUPER::bootstrap;
#  }



# initializations done when a backend is available
sub initBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::initBackend;

  # open result file
  my $handle=$me->{targethandle}=new IO::File(">$me->{options}{xmlfile}");

  # start the page
  # print $handle $me->{xml}->xmldecl({version => 1.0,});
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
 }

# headline formatter
sub formatHeadline
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # build the tag name and a path
  my $tag="h$item->{cfg}{data}{level}";
  my $path=$page->path(type=>'fpath', mode=>'full', delimiter=>'|');

  # build the headline, store it with anchors
  (
   $me->{xml}->a({name=>$item->{cfg}{data}{full}}),
   $path ne $item->{cfg}{data}{full} ? $me->{xml}->a({name=>$path}) : (),
   $me->{xml}->$tag(@{$item->{parts}}),
  )
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

  # handle the various tags
  if ($item->{cfg}{data}{name} eq 'INDEX')
    {
     # scopies
     my (%index, %anchors);

     # index: get data structure
     my $anchors=$item->{cfg}{data}{options}{__anchors};

     # start with an anchor and a navigation bar ...
     push(@results, $me->{xml}->a({name=>(my $bar)=$me->{anchorfab}->generic}));
     push(@results, map {$anchors{$_}=$me->{anchorfab}->generic; $me->{xml}->a({href=>"#$anchors{$_}"}, $_)} sort keys %$anchors);

     # now, traverse all groups and build their index
     foreach my $group (sort keys %$anchors)
       {
        # make the character a "headline", linking back to the navigation bar
        push(@results, $me->{xml}->p($me->{xml}->strong($me->{xml}->a({href=>"#$bar"}, $group))));

        # now add all the index entries
        push(
             @results, 
             $me->{xml}->div(
                             {class => 'indexgroup'},
                             map
                              {
                               (
                                # first, the entry string
                                $me->{xml}->div(
                                                {class => 'indexitem'},
                                                $_->[0],
                                               ),

                                # then, the list of occurences
                                $me->{xml}->div(
                                                {class => 'indexreflist'},
                                                map
                                                 {
                                                  # an occurence reference
                                                  $me->{xml}->a({href=>"#$_->[0]"}, $_->[1]),
                                                 } grep(ref($_), @{$_->[1]}) # TODO: check the structure! Why (doubled) scalars?
                                               ),
                               )
                              } @{$anchors->{$group}},
                            ),
            );
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'L')
    {
     # link: build it
     @results=$me->{xml}->a(
                            {
                             href => $item->{cfg}{data}{options}{url},
                            },
                            @{$item->{parts}},
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

                   # supply the path of the upcoming chapter
                   @results=$me->{xml}->a(
                                          {
                                           href => join('', '#',
                                                        join('|',
                                                             map {defined($_) ? $_ : ''} @localHeadlinePath[0..$level-1],
                                                            ),
                                                       ),
                                          },
                                          $title,
                                         );
                  }
          }

        # use a more readable toc variable
        my $toc=$item->{cfg}{data}{options}{__rawtoc__};

        # make it a list of the requested format
        if ($item->{cfg}{data}{options}{format}=~/^(bullets|enumerated|numbers)$/)
          {
           # start a stack of intermediate level results
           my @buffered;

           # setup method name to build a (partial) list
           my $listMethodName=$item->{cfg}{data}{options}{format}=~/^(bullets|numbers)$/ ? 'ul' : 'ol';

           # make a temporary headline number array copy (used for numbered lists)
           my @localHeadlineNumbers=@{$page->path(type=>'npath', mode=>'array')};

           # calculate initial level depth for indentation (real headline levels should
           # not be reflected in a TOC listing them - a TOC *list* should start at level 1)
           my $startLevel=@localHeadlineNumbers;

           # traverse TOC entries
           foreach (@$toc)
             {
              # get level and title
              my ($level, $title)=@$_;

              # update headline numbering
              $localHeadlineNumbers[$level-1]++;

              # previous level closed?
              if ($level<@buffered)
                {
                 # complete closed levels and integrate them as lists
                 push(@{$buffered[$_-1]}, $me->{xml}->$listMethodName(@{$buffered[$_]})),
                   for reverse $level..@buffered-1;
                 
                 # delete all buffer levels which were integrated,
                 # delete headline numbers of the levels that were closed
                 $#buffered=$#localHeadlineNumbers=$level-1;
                }

              # buffer item on current level
              push(@{$buffered[$level-1]}, $me->{xml}->li(
                                                          # write numbers if we are building a numbered lists
                                                          $item->{cfg}{data}{options}{format} eq 'numbers' ? join('', join('.', @localHeadlineNumbers[0..$level-1]), '. ') : (),
                                                          $plain ? $title : $link->(@$_)
                                                         )
                  );
             }

           # close open lists (down to the initial level depth)
           push(@{$buffered[$_-1]}, $me->{xml}->$listMethodName(@{$buffered[$_]})),
             for reverse $startLevel+1 .. @buffered-1;

           # finally, build the list (on startup level), including nested lists eventually
           @results=$me->{xml}->$listMethodName(@{$buffered[$startLevel]});
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
  elsif ($item->{cfg}{data}{name} eq 'REF')
    {
     # scopies
     my ($label);

     # catch target
     my $target=$item->{cfg}{data}{options}{name};

     # get the upcoming chapters data
     my @chapters=$me->getChapterByPath($target);

     # Anything found? Otherwise search for an anchor of the target name and get its page data
     unless ($chapters[0][0])
       {
        # get value and page
        my $data=$me->getAnchorData($target);

        # anything found?
        if (defined $data)
          {
           # get chapter data
           @chapters=$me->getChapterByPagenr($data->[1]);

           # set up local link
           $label=$target;
          }
       }

     # build text to display: is there a body?
     if ($item->{cfg}{data}{options}{__body__})
       {
        # yes: the tag body is our text
        @results=@{$item->{parts}};
       }
     else
       {
        # no body: what we display depends on option "valueformat"
        if ($item->{cfg}{data}{options}{valueformat} eq 'pure')
          {
           # display the value of the requested object
           @results=$item->{cfg}{data}{options}{__value__};
          }
        elsif ($item->{cfg}{data}{options}{valueformat} eq 'pagetitle')
          {
           # display the objects page title, to be found in target data
           @results=$chapters[0][2];
          }
        elsif ($item->{cfg}{data}{options}{valueformat} eq 'pagenr')
          {
           # display the objects page number (for more generic or configurable numbers,
           # this could be done by a function)
           @results=join('.', @{$chapters[0][7]}, '');
          }
        else
          {die "[BUG] Unhandled case $item->{cfg}{data}{options}{valueformat}."}
       }

     # if we do not build a link, we are already done now, otherwise, we have to
     # add link syntax
     if ($item->{cfg}{data}{options}{type} eq 'linked')
       {
        # build target chapter file name, using the absolute page number
        my $link=$me->_buildFilename($chapters[0][0]);

        # add lokal link, if necessary
        $link=join('#', $link, $label) if $label;

        # now build the link
        @results=$me->{xml}->a({href => $link}, @results);
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'SEQ')
    {
     # sequence: pure text for now, possibly anchored
     # (what's best to keep the sequence type?)
     if (exists $item->{cfg}{data}{options}{name})
       {
        @results=$me->{xml}->A(
                               {
                                name => $item->{cfg}{data}{options}{name},
                               },
                               $item->{cfg}{data}{options}{__nr__},
                              );
       }
     else
       {@results=$item->{cfg}{data}{options}{__nr__};}
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE')
    {
     # build the table
     @results=$me->{xml}->table(@{$item->{parts}});
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_COL')
    {
     # build the cell
     @results=$me->{xml}->td(
                             {
                             },
                             @{$item->{parts}} ? @{$item->{parts}} : '&nbsp;'
                            );
    }
  elsif ($item->{cfg}{data}{name} eq 'X')
    {
     # index entry: transform it into an anchor
     @results=$me->{xml}->a(
                            {
                             name => $item->{cfg}{data}{options}{__anchor},
                            },
                            @{$item->{parts}},
                           );
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


# docstream entry formatter
sub formatDStreamEntrypoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless $item;

  # provide the parts
  $me->{xml}->div({class=>$item->{cfg}{data}{name}}, @{$item->{parts}});
 }



# docstream frame formatter
sub formatDStreamFrame
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless $item;

  # provide the parts
  $me->{xml}->div({class=>'streamFrame'}, @{$item->{parts}});
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
  push(@{$me->{slides}}, @{$item->{parts}})
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

  # don't forget the base class
  $me->SUPER::finish;

  # write document
  my ($handle)=($me->{targethandle});
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

                                                  # the "doc..." options are reserved for further data
                                                  # ... stored in meta tags
                                                  map
                                                   {
                                                    /^doc(.+)$/;
                                                    my $tag=$me->elementName("_$1");
                                                    $me->{xml}->meta({name=>$tag, contents=>$me->{options}{$_}}),
                                                   } sort grep((/^doc/ and not /^doctitle/), keys %{$me->{options}}),
                                                 ),

                                 # embed slides into a special section
                                 $me->{xml}->body(@{$me->{slides}}),
                                ), "\n\n";


  # close document
  close($handle);
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003-2004.
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

