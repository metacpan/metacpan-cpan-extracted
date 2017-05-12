 

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.07    |02-12-2006| JSTENZEL | bugfix: nested TOC lists had additional <li> frames;
# 0.06    |05-03-2006| JSTENZEL | added INDEXCLOUD support;
#         |          | JSTENZEL | conversion of XML strings into XML objects now done by
#         |          |          | new PP::Generator::XML function;
# 0.05    |03-16-2006| JSTENZEL | <li> wrapping embedded lists needs special CSS;
# 0.04    |02-21-2006| JSTENZEL | the <embedded-(x)html> tags included for embedded parts
#         |          |          | made the produced XHTML invalid, deleted (using a
#         |          |          | dirty manipulation of an intermediate XML::Generator
#         |          |          | object, hopefully this can be changed in the future);
#         |03-05-2006| JSTENZEL | index now produced as better XHTML;
#         |          | JSTENZEL | in XHTML, <A> has an id attribute, but no name;
#         |          | JSTENZEL | added buildAnchorId();
#         |          | JSTENZEL | nested lists are wrapped in list points, for correct XHTML;
#         |          | JSTENZEL | anchors now built as simple strings on base of MD5
#         |          |          | checksums, to get valid XHTML addresses;
#         |03-09-2006| JSTENZEL | LOCALTOC: nested list wrapped in list points;
#         |          | JSTENZEL | index relation <div> now has an own class, "_ppIndexRelated";
#         |03-11-2006| JSTENZEL | U: in XHTML strict, there is no <u> tag, so now CSS is used;
# 0.03    |01-21-2006| JSTENZEL | buildFilename() uses File::Spec::catfile() now;
#         |          | JSTENZEL | bugfix in buildTargetLink() which could result in
#         |          |          | links to labels instead of to pages (wrong assumption
#         |          |          | about current page);
# 0.02    |01-01-2006| JSTENZEL | this is a cumulated history entry:
#         |          | JSTENZEL | added the template support the previous version was
#         |          |          | documented to have;
#         |          | JSTENZEL | removed attribute targethandle - with templates, files
#         |          |          | can be opened by the template engine, so a general
#         |          |          | handling is not always appropriate;
#         |          | JSTENZEL | added buildFilename() to allow generalized algorithms
#         |          |          | to work - code in this class must work for child
#         |          |          | classes as well;
#         |          | JSTENZEL | added buildTargetLink() to build link targets in one
#         |          |          | place;
#         |          | JSTENZEL | fixed a letter case error - sequence anchor tags were
#         |          |          | written uppercased;
#         |          | JSTENZEL | now storing an array reference for each page in the
#         |          |          | slides attribute, allowing using code (like template
#         |          |          | engines) to distinguish pages;
#         |01-06-2006| JSTENZEL | allowing nested tables now;
# 0.01    |09-09-2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::XML::XHTML> - generates XHTML via XML

=head1 VERSION

This manual describes version B<0.07>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Generator::XML::XHTML;

# declare package version
$VERSION=0.07;
$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003-2006';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from common generator class
use base qw(PerlPoint::Generator::XML);

# declare object data fields
use fields qw(
              slides
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use File::Spec::Functions;
use Digest::MD5 qw(md5_hex);
use HTML::TagCloud::Extended;
use PerlPoint::Generator::XML 0.04;
use PerlPoint::Constants qw(:DEFAULT :templates);

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
  my $me=fields::new($class);

  # store options of interest
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
    # ... and add your own
    "css=s@",                   # style sheets;
    "favicon=s",                # register a favicon;
    "norobots",                 # add meta tags to deny robot access;
    "nosmarttags",              # add meta tags to deny meta tags;
    "validate",                 # activates validation (a passive switch, yet)
   ],

   # and base options that we ignore
   [
    qw(
       tagtrans
       xmldtd
       xmldoctypeid
       writedtd
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
               css => <<EOO,

If you want to use CSS with your generated pages, this option is for you. Pass the URL of
the CSS file as argument.

 Examples:

  -css test.css
  -css "http://myserver/css/test.css"

As the W3C specs allow to use numerous stylesheets together, the C<-css> option can be used
multiply.

EOO

               favicon => <<EOO,

This option takes a favicon URL.

 Examples:

  -favicon 'http://myserver/favicon.ico'
  -favicon favicon.ico

Favicons are little images in Microsoft icon format, intended to be displayed in a browsers
address line, right before the page address.

The flavicon setting is made for I<all> pages. Page specific settings cannot be made this way.

As the argument is an URL, the generator cannot check it. Make sure the icon is available
when you display your pages.

EOO

               norobots => <<EOO,

Adds a C<meta name="ROBOTS" content="NOINDEX, NOFOLLOW"> meta tag to generated pages, to
deny robot access.

 Example: -norobots

EOO

               nosmarttags => <<EOO,

Adds a C<meta name="MSSmartTagsPreventParsing" content="true"> meta tag to generated pages, to
suppress smart tags as specified by Microsoft.

 Example: -nosmarttags

EOO

               validate => <<EOO,

A flag activating page validation functionality. At the time of this writing, implementation
is forwarded to template directives. See there for details.

Note: this option should probably become a C<-set> switch, as soon as such switches are
available to backends.

 Example: -validate

EOO

              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

According to your formatter choice, the XML produced will be formatted as I<XHTML>.

EOS
  }
 }


# provide source filter declarations
sub sourceFilters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # get the common parent class list, replace a few items and provide the result
  (
   grep($_!~/^xml$/i, $me->SUPER::sourceFilters),  # parent class list, but we do not support pure XML
   "xhtml",                                        # embedded XHTML;
   "html",                                         # support legacy sources;
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
                               A:a
                               dlist:dl
                               dpointitem:dt
                               dpointtext:dd
                               example:pre
                               olist:ol
                               opoint:li
                               text:p
                               ulist:ul
                               upoint:li
                               U:u
                              )
                           ];

  # check your own options, if necessary

  # being here means that the check suceeded
  1;
 }


sub bootstrap
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::bootstrap;

  # configure your parts - nested tables are supported (TODO: should this be encapsulated by a Generator method?)
  $me->{build}{nestedTables}=1;
 }



# initializations done when a backend is available
sub initBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # don't forget the base class
  $me->SUPER::initBackend;
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

  # build the headline, store it with anchors (anchors as MD 5 checksums)
  (
   $me->{xml}->a({id=>$me->buildAnchorId($item->{cfg}{data}{full})}),
   $path ? $me->{xml}->a({id=>$me->buildAnchorId(join('|', $path, $item->{cfg}{data}{full}))}) : (),
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
  if ($item->{cfg}{data}{name} eq 'A')
    {
     # anchor: build result string
     push(
          @results,
          $me->{$me->{xmlmode}}->a(
                                   {
                                    # this is the difference to the XML generator handling:
                                    # valid XHTML tag names are required to be very simple strings,
                                    # so we use *checksums*
                                    id => $me->buildAnchorId($item->{cfg}{data}{options}{name}),
                                   },
                                   @{$item->{parts}},
                                  )
         );
    }
  elsif ($item->{cfg}{data}{name} eq 'EMBED')
    {
     # embedded (X)HTML
     if ($item->{cfg}{data}{options}{lang}=~/^X?HTML$/i)
       {
        # just pass parts through (supplying them via XML::Generator object, not as string)
        push(@results, $me->string2XMLObject(@{$item->{parts}}));
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'F')
    {
     # the FONT tag is deprecated, use inlined CSS instead
     my $style;

     # faces
     $style.="font-family:$item->{cfg}{data}{options}{face};"
       if (exists $item->{cfg}{data}{options}{face});

     # size
     if (exists $item->{cfg}{data}{options}{size})
       {
        # get original setting
        my $size=$item->{cfg}{data}{options}{size};

        # translate old fashioned fuzzy setups, if necessary
        if ($size=~/^[-+]?\d+$/)
          {
           {
            # for recalculation, keep in mind that size "3" is the standard
            # size in HTML's deprecated FONT tag
            # (ugly do {} only used to avoid noisy "= instead == in condition"
            # warnings in perl 5.8.x)
            do {$size='medium'} and last if $size=~/^[-+]0$/ or $size==3;

            do {$size='smaller'}  and last if $size==-1 or $size==2;
            do {$size='small'}    and last if $size==-2 or $size==1;
            do {$size='x-small'}  and last if $size==-3 or $size eq '0';
            do {$size='xx-small'} and last if $size<-4;

            do {$size='larger'}   and last if $size eq '+1' or $size==4;
            do {$size='large'}    and last if $size eq '+2' or $size==5;
            do {$size='x-large'}  and last if $size eq '+3' or $size==6;
            do {$size='xx-large'} and last if $size=~/^\+[456]$/ or $size>6;
           }
          }

        $style.="font-size:$size;";
       }

     # color
     $style.="color:$item->{cfg}{data}{options}{color};"
       if (exists $item->{cfg}{data}{options}{color});

     # provide results
     push(@results, $me->{$me->{xmlmode}}->span({$style ? (style => $style) : ()}, @{$item->{parts}}));
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEX')
    {
     # scopies
     my (%index, %anchors);

     # index: get data structure
     my $anchors=$item->{cfg}{data}{options}{__anchors};

     # start with an anchor and a navigation bar ...
     push(@results, $me->{$me->{xmlmode}}->a({id=>(my $bar)=$me->buildAnchorId($me->{anchorfab}->generic)}));
     push(@results, map {$anchors{$_}=$me->buildAnchorId($me->{anchorfab}->generic); $me->{$me->{xmlmode}}->a({href=>"#$anchors{$_}"}, $_)} sort keys %$anchors);
     push(@results, $me->{$me->{xmlmode}}->hr());

     # now, traverse all groups and build their index
     foreach my $group (sort keys %$anchors)
       {
        # make the character a "headline", including an anchor and linking back to the navigation bar
        push(
             @results,
             $me->{$me->{xmlmode}}->p($me->{$me->{xmlmode}}->a({id=>$anchors{$group}})),
             $me->{$me->{xmlmode}}->h1($me->{$me->{xmlmode}}->a({href=>"#$bar"}, $group))
            );

        # now add all the index entries
        push(
             @results, 
             $me->{$me->{xmlmode}}->div(
                                        {class => 'indexgroup'},
                                        map
                                         {
                                          # scopy
                                          my ($occ)=(0);

                                          (
                                           # each entry has its own DIV area
                                           $me->{$me->{xmlmode}}->div(
                                                                      {class => 'indexentry'},

                                                                      # now first insert the entry string
                                                                      $me->{$me->{xmlmode}}->span(
                                                                                                  # should be formatted via CSS, the trailing whitespace
                                                                                                  # is a basic "formatting" (for readability) # TODO: document possible CSS use
                                                                                                  {class => 'indexitem'},
                                                                                                  "$_->[0] ",
                                                                                                  ),

                                                                      # then, the list of occurences
                                                                      $me->{$me->{xmlmode}}->span(
                                                                                                  {class => 'indexreflist'},
                                                                                                  map
                                                                                                   {
                                                                                                    # an occurence reference
                                                                                                    (
                                                                                                     $occ++ ? '; ' : (),
                                                                                                     $me->{$me->{xmlmode}}->a({href=>$me->buildTargetLink($page, $_->[1], $_->[0], [])}, $_->[1]),
                                                                                                    ),
                                                                                                   } grep(ref($_), @{$_->[1]}) # TODO: check the structure! Why (doubled) scalars?
                                                                                                  ),
                                                                     ),
                                          )
                                         } @{$anchors->{$group}},
                                       ),
            );
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEXCLOUD')
    {
     # index: get quick list data structure
     my $entries=$item->{cfg}{data}{options}{__entries};

     # build a tag cloud object
     my $cloud=HTML::TagCloud::Extended->new(
                                             use_hot_color => 'size',
                                            );

     # configure font sizes, if necessary
     if (exists $item->{cfg}{data}{options}{smallestFont} or exists $item->{cfg}{data}{options}{largestFont})
      {
       # find min and max font size
       my $min=$item->{cfg}{data}{options}{smallestFont} || 12;  # 12 is the default of HTML::TagCloud::Extended
       my $max=$item->{cfg}{data}{options}{largestFont}  || 36;  # 36 is the default of HTML::TagCloud::Extended

       # configure cloud object
       $cloud->base_font_size(int(($min+$max)/2));
       $cloud->font_size_range(int(($max-$min)/2));
      }

     # configure cloud object as necessary
     $cloud->colors->set(hot => $item->{cfg}{data}{options}{hottestColor}) if exists $item->{cfg}{data}{options}{hottestColor};

     # add all index entries for the cloud
     $cloud->add($_, '', $entries->{$_}) for keys %$entries;

     # write list structure (we do not need to take care of the top limit, as this is done by the generator base module)
     @results=$me->{$me->{xmlmode}}->div(
                                         # own class for easier CSS access
                                         {class=>'_ppIndexCloud'},

                                         # start with an intro, if specified
                                         exists $item->{cfg}{data}{options}{intro} ? $me->{$me->{xmlmode}}->p($item->{cfg}{data}{options}{intro}) : (),

                                         # list of related topics
                                         $me->string2XMLObject($cloud->html_and_css)
                                        );
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEXRELATIONS')
    {
     # get index data
     my $data=[map {$_->[0]} @{$item->{cfg}{data}{options}{__data}}];

     # configure list tag
     my $listtag=$item->{cfg}{data}{options}{format} eq 'enumerated' ? 'ol' : 'ul';

     # write list structure
     @results=$me->{$me->{xmlmode}}->div(
                                          # own class for easier CSS access
                                          {class=>'_ppIndexRelated'},

                                          # start with an intro, if specified
                                          exists $item->{cfg}{data}{options}{intro} ? $me->{$me->{xmlmode}}->p($item->{cfg}{data}{options}{intro}) : (),

                                          # list of related topics
                                          $me->{$me->{xmlmode}}->$listtag(
                                                                          map
                                                                           {
                                                                            # get page title
                                                                            my $tpage=$me->page($_);
                                                                            my $title=$tpage->path(type=>'spath', mode=>'title');
                                                                            $title=join('', (map {"$_."} @{$tpage->path(type=>'npath', mode=>'array')}), " $title") if $item->{cfg}{data}{options}{format} eq 'numbers';

                                                                            # build list entry, type dependent (as link or plain string)
                                                                            $me->{$me->{xmlmode}}->li($item->{cfg}{data}{options}{type} eq 'linked' ? $me->{$me->{xmlmode}}->a({href=>$me->buildTargetLink($page, $_, $title, [@{$tpage->path(type=>'spath', mode=>'array')}])}, $title) : $title);
                                                                           } @$data,
                                                                         )
                                        );
    }
  elsif ($item->{cfg}{data}{name} eq 'L')
    {
     # link: build it
     @results=$me->{$me->{xmlmode}}->a(
                                        {
                                         href => $item->{cfg}{data}{options}{url},
                                         exists $item->{cfg}{data}{options}{target} ? (target => $item->{cfg}{data}{options}{target}) : (),
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

                   # get the absolute number of the upcoming chapter
                   my $chapter=($me->getChapterByPath([@localHeadlinePath[0..$level-1]]))[0]->[0];

                   # supply the path of the upcoming chapter
                   @results=$me->{$me->{xmlmode}}->a(
                                                     {
                                                      href => $me->buildTargetLink($page, $chapter, $title, [@localHeadlinePath[0..$level-1]])
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
                 # complete closed levels and integrate them as they are
                 push(@{$buffered[$_-1]}, $me->{$me->{xmlmode}}->$listMethodName(@{$buffered[$_]}))
                   for reverse $level..@buffered-1;
                 
                 # delete all buffer levels which were integrated,
                 # delete headline numbers of the levels that were closed
                 $#buffered=$#localHeadlineNumbers=$level-1;
                }

              # buffer item on current level
              push(@{$buffered[$level-1]}, $me->{$me->{xmlmode}}->li(
                                                                     # write numbers if we are building a numbered lists
                                                                     $item->{cfg}{data}{options}{format} eq 'numbers' ? join('', join('.', @localHeadlineNumbers[0..$level-1]), '. ') : (),
                                                                     $plain ? $title : $link->(@$_)
                                                                    )
                  );
             }

           # close open lists (down to the initial level depth)
           push(@{$buffered[$_-1]}, $me->{$me->{xmlmode}}->$listMethodName(@{$buffered[$_]}))
             for reverse $startLevel+1 .. @buffered-1;

           # finally, build the list (on startup level), including nested lists eventually
           @results=$me->{$me->{xmlmode}}->$listMethodName(@{$buffered[$startLevel]});
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
        # build target link
        @results=$me->{$me->{xmlmode}}->a({href => $me->buildTargetLink($page, $chapters[0][0], $label, $chapters[0][5])}, @results);
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'PAGEREF')
    {
     # TODO: this is a special variant of REF, merge implementations

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

     # display the objects page number (for more generic or configurable numbers,
     # this could be done by a function)
     @results=join('.', @{$chapters[0][7]}, '');

     # now build the link
     @results=$me->{$me->{xmlmode}}->a({href => $me->buildTargetLink($page, $chapters[0][0], $label, $chapters[0][5])}, @results);
    }
  elsif ($item->{cfg}{data}{name} eq 'SECTIONREF')
    {
     # TODO: this is a special variant of REF - merge implementations

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

     # SECTIONREF tags have no body and are displayed as chapter title
     # (to be found in target data)
     @results=$chapters[0][2];

     # now build the link
     @results=$me->{$me->{xmlmode}}->a({href => $me->buildTargetLink($page, $chapters[0][0], $label, $chapters[0][5])}, @results);
    }
  elsif ($item->{cfg}{data}{name} eq 'SEQ')
    {
     # sequence: pure text for now, possibly anchored
     # (what's best to keep the sequence type?)
     if (exists $item->{cfg}{data}{options}{name})
       {
        @results=$me->{$me->{xmlmode}}->a(
                                          {id => $me->buildAnchorId($item->{cfg}{data}{options}{name})},
                                          $item->{cfg}{data}{options}{__nr__},
                                         );
       }
     else
       {@results=$item->{cfg}{data}{options}{__nr__};}
    }
  elsif ($item->{cfg}{data}{name} eq 'SUB')
    {
     # vertical aligned text: add inlined CSS
     @results=$me->{$me->{xmlmode}}->span(
                                          {
                                           style => "vertical-align:sub;",
                                          },
                                          @{$item->{parts}}
                                         );
    }
  elsif ($item->{cfg}{data}{name} eq 'SUP')
    {
     # vertical aligned text: add inlined CSS
     @results=$me->{$me->{xmlmode}}->span(
                                          {
                                           style => "vertical-align:super; font-size:smaller;",
                                          },
                                          @{$item->{parts}}
                                         );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE')
    {
     # build the table
     @results=$me->{$me->{xmlmode}}->table(@{$item->{parts}});
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_COL')
    {
     # build the cell
     @results=$me->{$me->{xmlmode}}->td(
                                         {
                                         },
                                        @{$item->{parts}} ? @{$item->{parts}} : '&nbsp;'
                                       );
    }
  elsif ($item->{cfg}{data}{name} eq 'U')
    {
     # in XHTML, there is no <u> tag - use CSS instead
     @results=$me->{$me->{xmlmode}}->span(
                                          {
                                           style => 'text-decoration: underline;',
                                          },
                                          @{$item->{parts}},
                                         );
    }
  elsif ($item->{cfg}{data}{name} eq 'X')
    {
     # index entry: transform it into an anchor
     @results=$me->{$me->{xmlmode}}->a(
                                       {id => $me->buildAnchorId($item->{cfg}{data}{options}{__anchor})},
                                       (exists $item->{cfg}{data}{options}{mode} and lc($item->{cfg}{data}{options}{mode}) eq 'index_only') ? () : @{$item->{parts}},
                                      );
    }
  elsif ($item->{cfg}{data}{name} eq 'XREF')
    {
     # TODO: this is a special variant of REF - merge implementations

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

     # build text to display (XREF tags always have a body) - the tag body is our text
     @results=@{$item->{parts}};

     # now build the link
     @results=$me->{$me->{xmlmode}}->a({href => $me->buildTargetLink($page, $chapters[0][0], $label, $chapters[0][5])}, @results);
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


# in XHTML, nested lists need to be wrapped into a list point - unordered lists
sub formatUlist
 {
  # get parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;

  # call base method, which will check the parameters,
  # and supply a wrapped object if necessary
  $me->wrapNestedList($me->SUPER::formatUlist($page, $item), $item);
 }

# in XHTML, nested lists need to be wrapped into a list point - ordered lists
sub formatOlist
 {
  # get parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;

  # call base method, which will check the parameters,
  # and supply a wrapped object if necessary
  $me->wrapNestedList($me->SUPER::formatOlist($page, $item), $item);
 }

# in XHTML, nested lists need to be wrapped into a list point - definition lists
sub formatDlist
 {
  # get parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;

  # call base method, which will check the parameters,
  # and supply a wrapped object if necessary
  $me->wrapNestedList($me->SUPER::formatDlist($page, $item), $item);
 }


# wrap a list in case it is nested (in XHTML, nested lists are list points)
sub wrapNestedList
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($object, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing object data parameter.\n" unless $object;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # check if the parent level is a list (TODO: definition lists are more complex!)
  my $parent=$item->{context}[-1];
  my $wrapper=($parent==DIRECTIVE_ULIST or $parent==DIRECTIVE_OLIST) ? 'li' : $parent==DIRECTIVE_DLIST ? 'dd' : undef;

  # provide the parts
  $wrapper ? $me->{xml}->$wrapper($object) : $object;
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

  # don't forget the base class
  $me->SUPER::finish;

  # produce via templates if available, otherwise produce your own way
  if ($me->{template})
    {
     $me->{template}->transform(
                                action => TEMPLATE_ACTION_DOC,
                                slides => $me->{slides},
                               );
    }
  else
    {
     # open result file
     my $handle=new IO::File(join('', '>', $me->buildFilename));

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

     # write document
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

                                    # embed slides into a special section
                                    $me->{xml}->body(map {@$_;} @{$me->{slides}}),
                                   ), "\n\n";

     # close document
     close($handle);
    }
 }


# build target filename
sub buildFilename
 {
  # get and check parameters
  ((my __PACKAGE__ $me))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # supply resulting name - ignore whatever (page nr) parameter might be set
  catfile($me->{options}{targetdir}, "$me->{options}{prefix}$me->{options}{suffix}");
 }


# Build target link, using the absolute chapter path,
# or use a local link, if necessary. In all cases the
# link contains two parts: a page and a label and requires at least one of them.
sub buildTargetLink
 {
  # get and check parameters
  ((my __PACKAGE__ $me), (my ($page, $targetPageNr, $label, $titlePath)))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing current page data parameter.\n" unless $page;
  confess "[BUG] Missing target page number parameter.\n" unless $targetPageNr;
  confess "[BUG] Missing title path parameter.\n" unless $titlePath;
  confess "[BUG] Title path parameter is no array reference.\n" unless ref($titlePath) eq 'ARRAY';

  # set "same page" flag
  my $targetPage;
  my $samePageFlag=($targetPage=$me->buildFilename($targetPageNr)) eq $me->buildFilename($page->nr-1);

  # build page part - can be omitted if we are on the target page already
  # (use an empty string then to get a "#" in the final join() below)
  my $pagePart=$samePageFlag ? '' : $targetPage;

  # label part - if we have no label, we use the chapter path if we are on the target page,
  # otherwise we link to the entire page which means that we omit the label part
  # (use an empty list then to get no "#" in the final join() below)
  # use Data::Dumper; warn Dumper $titlePath;
  my @labelPart=$label ? $me->buildAnchorId($label) : ($samePageFlag and @$titlePath) ? $me->buildAnchorId(join('|', @$titlePath)) : ();

  # supply result
  join('#', $pagePart, @labelPart);
}


# build an anchor id
sub buildAnchorId
 {
  # get and check parameters
  ((my __PACKAGE__ $me), (my ($name)))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing anchor name parameter.\n" unless $name;

  # supply id (as a checksum, but beginning with a prefix (XHTML achor ids need to begin with a letter))
  join('', 'MD5_', md5_hex($name));
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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003-2006.
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

