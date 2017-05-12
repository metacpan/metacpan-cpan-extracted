

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.02    |30.04.2006| JSTENZEL | added INDEXCLOUD support;
# 0.01    |23.05.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::SDF> - generic SDF generator

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
package PerlPoint::Generator::SDF;

# declare package version
$VERSION=0.02;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003';



# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# inherit from base generator class
use base qw(PerlPoint::Generator);

# declare your fields (the _perlbug field is a workaround, obviously Perl 5.8.0 is buggy
# when it treats the first field entry as a PerlPoint::Backend object)
use fields qw(
              _perlbug
              flags
             );

# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use File::Basename;
use PerlPoint::Constants;
use PerlPoint::Tags::SDF;

# = CODE SECTION =========================================================================


# declare class data: simple tag translations
my %simpleTags=(
                # base
                B => 'B',
                C => 'EX',
                E => 'E',
                I => 'I',

                # imported tags
                U => 'U',
               );

# a small translation table to handle curly braces
my %curlyBraceTranslations=('{' => '{{CHAR:lbrace}}', '}' => '{{CHAR:rbrace}}');


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
  confess "[BUG] Missing style type parameter.\n" unless exists $params{formatter};
  confess "[BUG] This method should be called via its own package only.\n" unless $class eq __PACKAGE__;

  # try to load the style type class
  my $pluginClass=join('::', $class, $params{formatter});
  eval "require $pluginClass" or die "[Fatal] Missing plugin $pluginClass, please install it ($@).\n";
  die $@ if $@;

  # build an object of the *plugin* class and check it
  my $plugin=$pluginClass->new(%params);
  confess "[BUG] $pluginClass does not inherit from ", __PACKAGE__, ".\n" unless $plugin->isa(__PACKAGE__);

  # supply new object
  $plugin;
 }


# provide option declarations
sub declareOptions
 {
  # get and check parameters
  my ($me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # start with the base options
  $me->readOptions($me->SUPER::declareOptions);

  (
   # new options
   [],

   # there is no base option that we ignore
   [],
  );
 }


# provide help portions
sub help
 {
  # get and check parameters
  my ($me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

In your case, you want to produce SDF.

EOS
  };
 }


# provide source filter declarations
sub sourceFilters
 {
  # get and check parameters
  my ($me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # get the common parent class list, add a few items and provide the result
  (
   $me->SUPER::sourceFilters,  # parent class list
   "sdf",                      # embedded SDF;
   "html",                     # embedded HTML (sdf can handle it);
  );
 }


# formatters

sub preFormatter
 {
  # get and check parameters
  my ($me, $opcode, $mode, @more)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # embed tag?
  if ($opcode==DIRECTIVE_TAG and $more[0] eq 'EMBED')
    {
     # get more parameters
     my ($tag, $settings)=@more;

     # embedded SDF configuration
     $me->{flags}{sdf}=($mode==DIRECTIVE_START) ? 1 : 0 if $settings->{lang}=~/^sdf$/i;

     # embedded HTML configuration
     $me->{flags}{html}=($mode==DIRECTIVE_START) ? 1 : 0 if $settings->{lang}=~/^html$/i;
    }
 }

sub formatSimple
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # the base operation is to concatenate the parts
  my $result=join('', @{$item->{parts}});

  # now we have to check for special operations to perform
  unless ($me->{flags}{sdf})
    {
     # Guard translations of things like "\B<{key=>value}>" by translating "{".
     # *Opening* curly braces might confuse SDF as well (unless corresponding
     # closing braces will follow).
     $result=~s/([{}])/$curlyBraceTranslations{$1}/g;

     # brackets seem to have a special meaning in SDF,
     # (sdf evaluates their contents via eval()), so guard them
     $result=~s/\[/\\[/g
      if grep(($_ eq DIRECTIVE_BLOCK or $_ eq DIRECTIVE_VERBATIM), @{$item->{context}});
    }

  # replace more characters which may confuse sdf, except where they are intended
  # (but not intended to confuse ;-)
  unless (grep($_ eq DIRECTIVE_VERBATIM, @{$item->{context}}) or $me->{flags}{sdf} or $me->{flags}{html})
    {
     $result=~s/</{{CHAR:lt}}/g;
     $result=~s/>/{{CHAR:gt}}/g;
    }

  # supply result
  $result;
 }

sub formatHeadline
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get path
  my $path=$page->path(type=>'fpath', mode=>'full', delimiter=>'|');

  # build the title
  join('',
       "H$item->{cfg}{data}{level}\[id=q($item->{cfg}{data}{full})]{{N[id=q(",
       join('|', $path ? $path : (), $item->{cfg}{data}{full}),
       ")]",
       join('', @{$item->{parts}}),
       "}}\n\n",
      );
 }


sub formatComment
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # the base operation is to concatenate the parts
  join('', "# ", @{$item->{parts}}, "\n");
 }


sub formatText
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # Concatenate the parts, preceede them by formatting hints, if alignment ist configured.
  # Otherwise guard all non special text paragraphs by backslashes to avoid SDF
  # misinterpretation.
  return '' unless @{$item->{parts}} and grep(defined, @{$item->{parts}});

  join('',
       exists $me->{flags}{align} ? qq(N[align="$me->{flags}{align}"]\n) : (defined $item->{parts}[0] and $item->{parts}[0]!~/^(Note|Sign)$/ and $item->{parts}[0]!~/^\{\{/) ? '\\' : '',
       @{$item->{parts}},
       "\n\n",
      );
 }


sub formatBlock
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # pass over to a generalized method
  shift;
  $me->_formatExample('E:', @_);
 }


sub formatVerbatim
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # pass over to a generalized method
  shift;
  $me->_formatExample('>', @_);
 }

sub _formatExample
 {
  # get and check parameters
  my ($me, $prefix, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # remove empty lines at begin and end and a final newline at the end of the block
  shift(@{$item->{parts}}) while $item->{parts}[0]=~/\s*^$/;
  pop(@{$item->{parts}}) while $item->{parts}[-1]=~/\s*^$/;
  chomp($item->{parts}[-1]);

  # format example block
  join('',
       "\n\n$prefix",
       (
        map {
             s/\n/\n$prefix/g;
             $_        
            } @{$item->{parts}},
       ),
       "\n\n",
      );
 }


sub formatTag
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # declarations
  my ($directive, $result)=('');

  # handle the various tags
  if (exists $simpleTags{$item->{cfg}{data}{name}})
    {
     $directive=$simpleTags{$item->{cfg}{data}{name}};
     $result=join('', "{{$directive:", @{$item->{parts}}, '}}');
    }
  elsif ($item->{cfg}{data}{name} eq 'A')
    {
     # anchor: build result string
     $result=join('', qq({{N[id=q($item->{cfg}{data}{options}{name})]), @{$item->{parts}}, '}}');
    }
  elsif ($item->{cfg}{data}{name} eq 'EMBED')
    {
     # embedded part: SDF is prepared for printing
     if ($item->{cfg}{data}{options}{lang}=~/^SDF$/i)
       {
        # just concatenate the parts
        $result=join('', @{$item->{parts}});
       }
     elsif ($item->{cfg}{data}{options}{lang}=~/^HTML$/i)
       {
        # concatenate first ...
        $result=join('', @{$item->{parts}});

        # then inline as possible
        my $newlines=$result=~/\n/;
        $result=join('',
                     $newlines ? "\n!block inline\n" : "{{INLINE:",
                     $result,
                     $newlines ? "\n!endblock\n"     : "}}",
                    );
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'FORMAT')
    {
     # formatting: all we have to do is to store informations
     $result='';

     # store what we got
     $item->{cfg}{data}{options}{align}=ucfirst(lc($item->{cfg}{data}{options}{align}));
     $item->{cfg}{data}{options}{align}='Full' if $item->{cfg}{data}{options}{align} eq 'Justify';
     $me->{flags}{align}=$item->{cfg}{data}{options}{align} if $item->{cfg}{data}{options}{align}=~/^(Left|Full|Center|Right)$/;
     delete $me->{flags}{align} if $item->{cfg}{data}{options}{align} eq 'Default';
    }
  elsif ($item->{cfg}{data}{name} eq 'IMAGE')
    {
     # image: parse image path
     my @image=fileparse($item->{cfg}{data}{options}{src});
     
     # build result string
     $result=join('', qq(\n\n!import "$image[0]"; ), $image[1] ? qq(base="$image[1]"; ) : '', join('; ', map {join('=', $_, map {/\s/ ? "\"$_\"" : $_} ucfirst(lc($item->{cfg}{data}{options}{$_})))} grep(lc($_)!~/^(src|__loaderpath__)$/, keys %{$item->{cfg}{data}{options}})), "\n\n");
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEX')
    {
     # scopies
     my (%index);

     # index: get data structure
     my $anchors=$item->{cfg}{data}{options}{__anchors};

     # start with an anchor and a navigation bar ...
     $result=join('', "{{N[id=q(", (my $bar)=$me->{anchorfab}->generic, ")]");
     $result.=join(' ', map {join('', "{{CMD[jump=q(#", $me->{anchorfab}->generic, ")]$_}}")} sort keys %$anchors);
     $result.="}}\n\n";

     # now, traverse all groups and build their index
     foreach my $group (sort keys %$anchors)
       {
        # make the character a "headline", linking back to the navigation bar
        $result.=join('', "{{B:{{CMD[jump=q(#$bar)]$group}}}}\n\n");

        # now add all the index entries
        foreach my $entry (@{$anchors->{$group}})
          {
           # first, the entry string
           $result.="{{I:$entry->[0]}}\t";

           # then, the list of occurences
           $result.=join(', ', map {"{{CMD[jump=q(#$_->[0])]$_->[1]}}"} grep(ref($_), @{$entry->[1]})); # TODO: check the structure! Why (doubled) scalars?

           # complete this line
           $result.="\n";
          }

        # complete the paragraph
        $result.="\n\n";
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEXCLOUD')
    {
     # scopies
     my (%index);

     # index: get quick list data structure
     my $entries=$item->{cfg}{data}{options}{__entries};

     # sort entries by occurence, then by entry, present results as a sorted list
     my $c=0;
     $result.=join("\n", map {join(' ', ++$c==1 ? '^' : '+', "$_ ($entries->{$_})")} sort {$entries->{$b} <=> $entries->{$a} || $b cmp $a} keys %$entries);
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEXRELATIONS')
    {
     # get headline data
     my $data=[map {$_->[0]} @{$item->{cfg}{data}{options}{__data}}];

     # write list structure
     $result=join(
                  "\n\n",

                  # start with an intro, if specified
                  exists $item->{cfg}{data}{options}{intro} ? $item->{cfg}{data}{options}{intro} : (),

                  # list of related topics
                  map
                   {
                    # get page title
                    my $page=$me->page($_);
                    my $title=$page->path(type=>'spath', mode=>'title');
                    $title=join('', (map {"$_."} @{$page->path(type=>'npath', mode=>'array')}), " $title") if $item->{cfg}{data}{options}{format} eq 'numbers';
                     
                    # build list entry, type dependent (as link or plain string)
                    join('',
                         $item->{cfg}{data}{options}{format} eq 'enumerated' ? '^ ' : '* ',
                         $item->{cfg}{data}{options}{type} eq 'linked' ? join('',
                                                                              "{{CMD[jump=q(#",
                                                                              join('|',
                                                                                   @{$page->path(type=>'spath', mode=>'array')},
                                                                                  ),
                                                                              ")]$title}}",
                                                                             )
                                                                       : $title,
                        );
                   } @$data,
                 );
    }
  elsif ($item->{cfg}{data}{name} eq 'L')
    {
     # link: build it
     $result=join('', qq({{CMD[jump=q($item->{cfg}{data}{options}{url})]), @{$item->{parts}}, '}}');
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
                   join('',
                        "{{CMD[jump=q(#",
                        join('|',
                             map {defined($_) ? $_ : ''} @localHeadlinePath[0..$level-1],
                            ),
                        ")]$title}}",
                        );
                  }
          }

        # start TOC code
        $result="\n\n";

        # use a more readable toc variable
        my $toc=$item->{cfg}{data}{options}{__rawtoc__};

        # make it a list of the requested format
        if ($item->{cfg}{data}{options}{format} eq 'bullets')
          {$result.=join('', '*', ' ', $plain ? $_->[1] : $link->(@$_), "\n\n") for @$toc;}
        elsif ($item->{cfg}{data}{options}{format} eq 'enumerated')
          {$result.=join('', '^', ' ', $plain ? $_->[1] : $link->(@$_), "\n\n") for @$toc;}
        elsif ($item->{cfg}{data}{options}{format} eq 'numbers')
          {
           # make a temporary headline number array copy
           my @localHeadlineNumbers=@{$page->path(type=>'npath', mode=>'array')};

           # handle all provided subchapters
           for (@$toc)
             {
              # get level and title
              my ($level, $title)=@$_;

              # update headline numbering
              $localHeadlineNumbers[$level-1]++;

              # build result
              $result.=join('',
                            '*',
                            ' ',
                            join('.', @localHeadlineNumbers[0..$level-1]), '. ',
                            $plain ? $title : $link->(@$_),
                            "\n\n"
                           );
             }
          }
        else
          {die "[BUG] Unhandled case $item->{cfg}{data}{options}{format}."}
       }
     else
       {
        # oops - there are no subchapters
        $result='';
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'REF')
    {
     # plain text? (never has a body)
     if ($item->{cfg}{data}{options}{type} eq 'plain')
       {
        # supply just the referenced value
        $result=$item->{cfg}{data}{options}{__value__};
       }
     # link?
     elsif ($item->{cfg}{data}{options}{type} eq 'linked')
       {
        # catch target
        my $target=$item->{cfg}{data}{options}{name};
        $target=~s/\s*\|\s*/\|/g;

        # is there a body?
        if ($item->{cfg}{data}{options}{__body__})
          {
           # Yes, there is a body. This is equal to XREF.
           $result=join('', "{{CMD[jump=q(#$target)]", @{$item->{parts}}, "}}");
          }
        else
          {
           # No body: this means the referenced value becomes the linked text.
           $result=join('', "{{CMD[jump=q(#$target)]$item->{cfg}{data}{options}{__value__}}}");
          }
       }
     else
       {die "[BUG] Unhandled case $item->{cfg}{data}{options}{type}."}
    }
  elsif ($item->{cfg}{data}{name} eq 'SECTIONREF' or $item->{cfg}{data}{name} eq 'PAGEREF')
    {
     # These tags do not have a body.
     # The displayed text is the *final* part of the anchor name (which can be hierarchical).
     my $target=$item->{cfg}{data}{options}{name};
     $target=~s/\s*\|\s*/\|/g;
     $result=join('', "{{CMD[jump=q(#$target)]", (reverse split(/\|/, $target))[0], "}}");
    }
  elsif ($item->{cfg}{data}{name} eq 'SEQ')
    {
     # sequence: all we have to do is to present a number
     # and to optionally set an anchor
     $result=join('',
                  exists $item->{cfg}{data}{options}{name} ? qq({{N[id=q($item->{cfg}{data}{options}{name})]) : '',
                  $item->{cfg}{data}{options}{__nr__},
                  exists $item->{cfg}{data}{options}{name} ? q(}}) : '',
                 );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE')
    {
     # build the table
     $result=join('',
                  "\n\n!block table; noheadings\n",
                  join(';', map {"c$_";} (1..$item->{cfg}{data}{options}{__maxColumns__})),
                  "\n",
                  join("\n", @{$item->{parts}}),
                  "\n!endblock\n\n",
                 );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_ROW')
    {
     # build a row by concatenating the cells, using a semicolon delimiter
     $result=join(';', @{$item->{parts}});
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_COL')
    {
     # the cell is built as a string composed of its parts
     $result=join('', @{$item->{parts}});
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_HL')
    {
     # the cell is built as a bold formatted string composed of its parts
     $result=join('', '{{B:', @{$item->{parts}}, '}}');
    }
  elsif ($item->{cfg}{data}{name} eq 'X')
    {
     # index entry: this is an anchor implicitly, so build result string
     $result=join('',
                  qq({{N[id=q($item->{cfg}{data}{options}{__anchor})]),
                  (exists $item->{cfg}{data}{options}{mode} and lc($item->{cfg}{data}{options}{mode}) eq 'index_only') ? () : @{$item->{parts}},
                  '}}',
                 );
    }
  elsif ($item->{cfg}{data}{name} eq 'XREF')
    {
     # a flexible reference: build it
     my $target=$item->{cfg}{data}{options}{name};
     $target=~s/\s*\|\s*/\|/g;
     $result=join('', "{{CMD[jump=q(#$target)]", @{$item->{parts}}, "}}");
    }
  else
    {

     $result=join('', @{$item->{parts}});
    }

  # in blocks, all tags need to be reopened in new lines
  # (because SDF does not know multiline tag contents)
  # format example block
  $result=~s/(\n[ \t]*)/}}$1\{{$directive:/g if grep(($_ eq DIRECTIVE_BLOCK or $_ eq DIRECTIVE_VERBATIM), @{$item->{context}});

  # supply result
  # warn $result;
  $result;
 }


sub formatUpoint
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # write point
  join('', '*' x @{$item->{cfg}{data}{hierarchy}}, ' ', @{$item->{parts}}, "\n\n");
 }


sub formatDpointItem
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # write item, followed by a colon
  join('', @{$item->{parts}}, ": ");
 }

*formatDpoint=\&formatUpoint;


sub formatOpoint
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # write point
  join('', scalar($item->{cfg}{data}{hierarchy}[-1]==1 ? '^' : '+') x @{$item->{cfg}{data}{hierarchy}}, ' ', @{$item->{parts}}, "\n\n");
 }


sub _formatList
 {
  # get and check parameters
  my ($me, $page, $item)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # write list
  join('', @{$item->{parts}});
 }


# all list can be handled the same way
*formatOlist=\&_formatList;
*formatUlist=\&_formatList;
*formatDlist=\&_formatList;


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

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003.
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

