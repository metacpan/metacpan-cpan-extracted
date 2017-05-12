

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.04    |03.05.2006| JSTENZEL | added string2XMLObject();
# 0.03    |25.02.2006| JSTENZEL | empty XML tags now produced as <tag></tag>, as Opera
#         |          |          | and Firefox failed to handle <tag />;
# 0.02    |01.01.2006| JSTENZEL | high bit characters are transformeds into entities now;
# 0.01    |18.08.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator::XML> - generic XML generator

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
package PerlPoint::Generator::XML;

# declare package version
$VERSION=0.04;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003-2006';



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
              xml
              xmlplain
              xmlready
              xmlmode
             );

# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use XML::Generator;
use File::Basename;
use PerlPoint::Constants;
use PerlPoint::Tags::XML;

# = CODE SECTION =========================================================================

# precompile patterns
my $patternTagTrans=qr(^([-\w]+):([-\w]+)$);

# declare XML tags (TODO: should it become part of the object so that derived classes
# can access and adapt it?)
my %xmltags=(
             # document root and other structures
             __root          => 'presentation',
             __docdata       => 'docdata',
             __slides        => 'slides',
             __slide         => 'slide',

             # document data (meta data)
             _title          => 'title',
             _author         => 'author',
             _description    => 'description',

             # paragraph entities
             headline        => 'headline',
             text            => 'text',
             example         => 'example',
             ulist           => 'ulist',
             olist           => 'olist',
             dlist           => 'dlist',
             dlistitem       => 'item',
             dlistdefinition => 'definition',
             upoint          => 'upoint',
             opoint          => 'opoint',
             dpointitem      => 'item',
             dpointtext      => 'definition',
             dstreamentry    => 'dstreamentry',
             dstreamframe    => 'dstreamframe',

             # helper entities
             indexgroup      => 'indexgroup',
             indexphrase     => 'indexphrase',
             indexoccurence  => 'link',

             # complex tags
             A               => 'anchor',
             IMAGE           => 'img',
             INDEX           => 'index',
             L               => 'link',
             PAGEREF         => 'link',
             REF             => 'link',
             SECTIONREF      => 'link',
             SEQ             => 'sequence',
             X               => 'indexentry',
             XREF            => 'link',

             # table tags
             TABLE           => 'table',
             TABLE_ROW       => 'tablerow',
             TABLE_COL       => 'tablecol',
             TABLE_HL        => 'tablehl',

             # simple tags
             B               => 'strong',
             C               => 'code',
             E               => 'escaped',
             I               => 'em',
             U               => 'underlined',
            );

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
  my __PACKAGE__ $plugin=$pluginClass->new(%params);
  confess "[BUG] $pluginClass does not inherit from ", __PACKAGE__, ".\n" unless $plugin->isa(__PACKAGE__);

  # prepare and add a pretty printing XML generator ...
  $plugin->{cfg}{xml}{pretty}=2 unless exists $plugin->{cfg}{xml}{pretty};
  $plugin->{xml}=new XML::Generator(
                                    escape      => 'always,high-bit',
                                    pretty      => $plugin->{cfg}{xml}{pretty},
                                    empty       => 'close',
                                    conformance => 'strict',
                                   );

  # and a second one for examples ... usually without pretty printing to keep the structure
  $plugin->{xmlplain}=new XML::Generator(
                                         escape      => 'always,high-bit',
                                         pretty      => $plugin->{cfg}{xml}{prettyPlain},
                                         empty       => 'close',
                                         conformance => 'strict',
                                        );

  # and a third one for embedded XML which does not need to be escaped furtherly
  $plugin->{xmlready}=new XML::Generator(
                                         escape      => 0,
                                         pretty      => $plugin->{cfg}{xml}{prettyPlain},
                                         empty       => 'close',
                                         conformance => 'strict',
                                        );

  # by default, we use the pretty printing generator
  $plugin->{xmlmode}='xml';

  # supply new object
  $plugin;
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

  (
   # new options
   [
    "tagtrans=s@",               # a tag transformation/translation spec;
    "writedtd",                  # writes the DTD to the file specified by -xmldtd;
    "xmldtd=s",                  # DTD,
    "xmldoctypeid=s",            # DOCTYPE specifier: external id,
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
               tagtrans     => <<EOO,

This PerlPoint/XML converter uses an own DTD. (If you need a copy of the DTD, please try
C<-writedtd>). As usual, a DTD is only useful if an application can handle it, so you might
want to transform the generated XML to another DTD. This can be done using XSLT or the like,
but in simple cases all you need is just a tag translation, which is provided by this option.

C<-targtrans> takes a string argument of the form <original PP tag name>:<new tag name> to
replace the I<original PP tag name> by the I<new tag name>.

 Example: -tagtrans headline:h1

As you can see, this is a simple name/name translation. Tag options cannot be taken into
account yet, as this would need more detailed transformation rules.

For a list of valid original tag names, please use C<-writedtd>.

The option can be used multiply.

Note: C<-tagtrans> adaptations will be taken into account by C<-writedtd>.

EOO

               writedtd     => <<EOO,

The XML produced by this converter belongs to a special DTD which is specified internally.
A copy of the current DTD is written to a file if this option is used. The name of the
DTD file should be specified by C<-xmldtd>.

 Example: -writedtd -xmldtd ppdoc.dtd

Note: an output file already existing will be overwritten, take care.

EOO

               xmldtd       => <<EOO,

specifies the DTD to use. If used with C<-writedtd>, the argument specifies the DTD file
to I<write>.

 Example: -xmldtd ppdoc.dtd

Note: currently, this option takes no effect without C<-writedtd>.

EOO

               xmldoctypeid => <<EOO,

specifies the document type id.

Note: currently, this option is reserved for future use and has no impact.

EOO

              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

In your case, you want to produce XML.

EOS
  };
 }



# provide source filter declarations
sub sourceFilters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # get the common parent class list, add a few items and provide the result
  (
   $me->SUPER::sourceFilters,  # parent class list
   "xml",                      # embedded XML;
  );
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

  # check DOCTYPE options
  if (exists $me->{options}{writedtd} and not exists $me->{optionlist}[1]{writedtd})
    {
     confess "[BUG] Missing option -xmldtd.\n" unless exists $me->{options}{xmldtd} or exists $me->{optionlist}[1]{xmldtd};
    }
  # confess "[BUG] Missing option -xmldoctypeid.\n" unless exists $me->{options}{xmldoctypeid} or exists $me->{optionlist}[1]{xmldoctypeid}; # reserved for future use

  # check tag translation options
  if (exists $me->{options}{tagtrans})
    {
     # scopy
     my ($error, $counter)=(0, 0);

     # perform check
     foreach my $option (@{$me->{options}{tagtrans}})
       {
        # check format
        unless ($option=~/$patternTagTrans/)
          {
           $error=1;
           warn qq([Error] Wrong format in option "-tagtrans $option": use "<PerlPoint tag>:<XML tag>".\n);
          }
        else
          {
           # check tag
           warn (qq([Warn] Unknown PerlPoint tag "$1" in option "-tagtrans $option" ignored.)),
           splice(@{$me->{options}{tagtrans}}, $counter, 1)
             unless exists $xmltags{$1};
          }

        # update counter
        $counter++;
       }

     # all right?
     die "\n" if $error;
    }

  # being here means that the check succeeded
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

  # take tag translations
  my $error=0;
  foreach my $option (@{$me->{options}{tagtrans}})
    {
     # check format, extract parts
     unless ($option=~/$patternTagTrans/)
      {die qq([Error] Wrong format in targ translation "$option": use "<PerlPoint tag>:<XML tag>".\n);}
     else
      {
       # check tag
       warn (qq([Warn] Unknown PerlPoint tag "$1" in tag translation "$option".\n)),
        $error=1,
        unless exists $xmltags{$1};
      }

     # store translation
     $xmltags{$1}=$2;
    }

  #check success
  die "\n" if $error;

  # write DTD, if requested
  if (exists $me->{options}{writedtd})
    {
     # open DTD
     open(DTD, ">$me->{options}{xmldtd}") or die "[Fatal] Could not open DTD file $me->{options}{xmldtd} for writing: $!";

     # get template
     my $template=join('', <DATA>);

     # transform it to the current tag names
     $template=~s/=$_=/$xmltags{$_}/g for keys %xmltags;

     # write DTD
     print DTD $template;

     # close DTD
     close(DTD);
    }
 }


# formatters
sub preFormatter
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @more))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # invoke base class method, if necessary
  $me->SUPER::preFormatter() if $me->can('SUPER::preFormatter');

  # embed tag?
  if ($opcode==DIRECTIVE_TAG and $more[0] eq 'EMBED')
    {
     # get more parameters
     my ($tag, $settings)=@more;

     # embedded XML configuration
     $me->{flags}{xml}=($mode==DIRECTIVE_START) ? 1 : 0 if $settings->{lang}=~/^xml$/i;
    }

  # a paragraph enforcing plain XML without formatting (newlines added for pretty printing)?
  elsif (
            $opcode==DIRECTIVE_TEXT
         or $opcode==DIRECTIVE_BLOCK
         or $opcode==DIRECTIVE_VERBATIM
        )
    {
     # act mode dependend
     $me->{xmlmode}=$mode==DIRECTIVE_START ? 'xmlplain' : 'xml';
    }
 }

sub formatSimple
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # the base operation is to concatenate the parts
  my $result=join('', @{$item->{parts}});

  # now we have to check for special operations to perform
  unless ($me->{flags}{xml})
    {
    }

  # supply result
  $result;
 }

sub formatHeadline
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{headline};

  # build the headline
  $me->{xml}->$xmltag(
                      {
                       level    => $item->{cfg}{data}{level},
                       full     => $item->{cfg}{data}{full},
                       abbr     => $item->{cfg}{data}{abbr},
                       path     => $page->path(type=>'fpath', mode=>'full', delimiter=>'|'),
                       template => 'dtm',
                      },
                      @{$item->{parts}},
                     );
 }


sub formatComment
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # the base operation is to concatenate the parts
  $me->{xml}->xmlcmnt(@{$item->{parts}});
 }


sub formatText
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{text};

  # build option hash
  my %options;
  $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

  # provide the parts, if necessary
  (@{$item->{parts}} and grep((defined($_) and $_), @{$item->{parts}}) and "@{$item->{parts}}"=~/\S/) ? $me->{xml}->$xmltag(\%options, @{$item->{parts}}) : ();
 }


sub formatBlock
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{example};

  # build option hash
  my %options;
  $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

  # provide the parts, take care to begin the example in a *new* line
  # (after the tag opener)
  $me->{xmlplain}->$xmltag(\%options, "\n", @{$item->{parts}});
 }


sub formatVerbatim
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{example};

  # build option hash
  my %options;
  $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

  # provide the parts
  $me->{xmlplain}->$xmltag(\%options, @{$item->{parts}});
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
  my ($directive, $xmltag, $result)=('');

  # handle the various tags
  if ($item->{cfg}{data}{name} eq 'A')
    {
     # anchor: build result string
     $xmltag=$xmltags{A};
     confess "[BUG] No tag found" unless $xmltag;
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                            {
                                             name => $item->{cfg}{data}{options}{name},
                                            },
                                            @{$item->{parts}},
                                           );

    }
  elsif ($item->{cfg}{data}{name} eq 'EMBED')
    {
     # embedded XML
     if ($item->{cfg}{data}{options}{lang}=~/^XML$/i)
       {
        # just concatenate the parts (and supply them as XML::Generator object, not as string)
        my $pseudotag="embedded-$item->{cfg}{data}{options}{lang}";
        $result=$me->{xmlready}->$pseudotag(@{$item->{parts}});
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'FORMAT')
    {
     # formatting: all we have to do is to store informations
     $result='';

     # justification: store what we got
     $item->{cfg}{data}{options}{align}=ucfirst(lc($item->{cfg}{data}{options}{align}));
     $item->{cfg}{data}{options}{align}='Full' if $item->{cfg}{data}{options}{align} eq 'Justify';
     $me->{flags}{align}=$item->{cfg}{data}{options}{align} if $item->{cfg}{data}{options}{align}=~/^(Left|Full|Center|Right)$/;
     delete $me->{flags}{align} if $item->{cfg}{data}{options}{align} eq 'Default';

     # handle transition settings
     if (exists $item->{cfg}{data}{options}{transition})
       {
        # get setting
        my $transition=$item->{cfg}{data}{options}{transition}!~/^reset$/i ? $item->{cfg}{data}{options}{transition} : undef;

        # update transition settings for all the items that are listed,
        # or in general if no certain item is mentioned
        foreach my $target (qw(slides bullets images blocks verbatims))
          {
           $me->{cfg}{XML}{transition}{$target}=$transition
             if     not exists $item->{cfg}{data}{options}{items}
                or $item->{cfg}{data}{options}{items}=~/(^|(\s*,\s*))$target((\s*,\s*)|$)/i;
          }
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'IMAGE')
    {
     # get a local option copy
     my %options=%{$item->{cfg}{data}{options}};

     # image: parse image path
     my ($base, $path)=fileparse($options{src});

     # replace image source path by required reference path
     $options{src}="$me->{options}{imageref}/$base";

     # get tag name
     $xmltag=$xmltags{$item->{cfg}{data}{name}};

     # build and init option hash
     %options=map {$_, map {/\s/ ? "\"$_\"" : $_} $options{$_}} grep(lc($_)!~/^(__loaderpath__)$/, keys %options);
     $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

     # build result string
     $result=$me->{$me->{xmlmode}}->$xmltag(\%options);
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEX')
    {
     # scopies
     my (%index);

     # index: get data structure
     my $anchors=$item->{cfg}{data}{options}{__anchors};

     # traverse all groups and build their index
     my ($xmlindextag, $xmlentrytag, $xmlgrouptag, $xmloccurencetag)=@xmltags{qw(INDEX indexphrase indexgroup indexoccurence)};
     $result=$me->{$me->{xmlmode}}->$xmlindextag(
                                                 {
                                                 },
                                                 map
                                                  {
                                                   # this is a group
                                                   $me->{xml}->$xmlgrouptag(
                                                                             {
                                                                              # group name
                                                                              group => $_,
                                                                             },

                                                                            # add all the index entries
                                                                            map
                                                                             {
                                                                              # the list of entries
                                                                              $me->{xml}->$xmlentrytag(
                                                                                                        {
                                                                                                         # the phrase
                                                                                                         phrase => $_->[0],
                                                                                                        },
                                                                                                       # the list of occurences is passed by subelements (we need pairs, so attributes do not work ...)
                                                                                                       map
                                                                                                        {
                                                                                                         $me->{xml}->$xmloccurencetag(
                                                                                                                                      {
                                                                                                                                       # attributes describe how to link the reference
                                                                                                                                       type   => 'internal',
                                                                                                                                       target => $_->[0],
                                                                                                                                      },
                                                                                                                                      # the reference string
                                                                                                                                      $_->[1],
                                                                                                                                     ),
                                                                                                        } grep(ref($_), @{$_->[1]}) # TODO: check the structure! Why (doubled) scalars?
                                                                                                      ),
                                                                             } @{$anchors->{$_}},
                                                                           ),
                                       } sort keys %$anchors
                                     );
    }
  elsif ($item->{cfg}{data}{name} eq 'INDEXRELATIONS')
    {
     # get headline data
     my $data=[map {$_->[0]} @{$item->{cfg}{data}{options}{__data}}];

     # configure list tag
     my ($xmllisttag, $xmlpointtag, $xmlreftag)=($xmltags{$item->{cfg}{data}{options}{format} eq 'enumerated' ? 'olist' : 'ulist'}, $xmltags{$item->{cfg}{data}{options}{format} eq 'enumerated' ? 'opoint' : 'upoint'}, $xmltags{REF});

     # write list structure
     $result=$me->{$me->{xmlmode}}->span(
                                         # start with an intro, if specified
                                         exists $item->{cfg}{data}{options}{intro} ? $me->{$me->{xmlmode}}->span($item->{cfg}{data}{options}{intro}) : (),

                                         # list of related topics
                                         $me->{$me->{xmlmode}}->$xmllisttag(
                                                                            map
                                                                             {
                                                                              # get page title
                                                                              my $page=$me->page($_);
                                                                              my $title=$page->path(type=>'spath', mode=>'title');
                                                                              $title=join('', (map {"$_."} @{$page->path(type=>'npath', mode=>'array')}), " $title") if $item->{cfg}{data}{options}{format} eq 'numbers';

                                                                              # build list entry, type dependent (as link or plain string)
                                                                              $me->{$me->{xmlmode}}->$xmlpointtag($item->{cfg}{data}{options}{type} eq 'linked' ? $me->{$me->{xmlmode}}->$xmlreftag({type=>'internal', target=>join('|', @{$page->path(type=>'spath', mode=>'array')})}, $title) : $title);
                                                                             } @$data,
                                                                           )
                                        );
    }
  elsif ($item->{cfg}{data}{name} eq 'L')
    {
     # link: build it
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                            {
                                             type   => 'external',
                                             target => $item->{cfg}{data}{options}{url},
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
                   $xmltag=$xmltags{REF};
                   $result=$me->{$me->{xmlmode}}->$xmltag(
                                                           {
                                                            type   => 'internal',
                                                            target => join('|',
                                                                           map {defined($_) ? $_ : ''} @localHeadlinePath[0..$level-1],
                                                                          ),
                                                           },
                                                          $title,
                                                         );
                  }
          }

        # use a more readable toc variable
        my $toc=$item->{cfg}{data}{options}{__rawtoc__};

        # make it a list of the requested format
        if ($item->{cfg}{data}{options}{format} eq 'bullets')
          {
           my ($xmllisttag, $xmlpointtag)=@xmltags{qw(ulist upoint)};
           $result=$me->{$me->{xmlmode}}->$xmllisttag(map {$me->{$me->{xmlmode}}->$xmlpointtag($plain ? $_->[1] : $link->(@$_))} @$toc);
          }
        elsif ($item->{cfg}{data}{options}{format} eq 'enumerated')
          {
           my ($xmllisttag, $xmlpointtag)=@xmltags{qw(olist opoint)};
           $result=$me->{$me->{xmlmode}}->$xmllisttag(map {$me->{$me->{xmlmode}}->$xmlpointtag($plain ? $_->[1] : $link->(@$_))} @$toc);
          }
        elsif ($item->{cfg}{data}{options}{format} eq 'numbers')
          {
           # make a temporary headline number array copy
           my @localHeadlineNumbers=@{$page->path(type=>'npath', mode=>'array')};

           # handle all provided subchapters
           my ($xmllisttag, $xmlpointtag)=@xmltags{qw(ulist upoint)};
           $result=$me->{$me->{xmlmode}}->$xmllisttag(
                                            map
                                             {
                                              # get level and title
                                              my ($level, $title)=@$_;

                                              # update headline numbering
                                              $localHeadlineNumbers[$level-1]++;

                                              # add point
                                              $me->{$me->{xmlmode}}->$xmlpointtag(
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
        $result='';
       }
    }
  elsif ($item->{cfg}{data}{name} eq 'REF')
    {
     # scopies
     my ($label, @results);

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

     # transform results into a scalar
     $result=join('', @results);

     # if we do not build a link, we are already done now, otherwise, we have to
     # add link syntax
     if ($item->{cfg}{data}{options}{type} eq 'linked')
       {
        # get the tag name
        $xmltag=$xmltags{$item->{cfg}{data}{name}};

        # build target chapter file name, using the absolute page number
        my $link=$me->_buildFilename($chapters[0][0]);

        # add lokal link, if necessary
        $link=join('#', $link, $label) if $label;

        # now build the link
        $result=$me->{$me->{xmlmode}}->$xmltag(
                                                {
                                                 type   => 'internal',
                                                 target => $link,
                                                },
                                               $result,
                                              );
       }




    }
  elsif ($item->{cfg}{data}{name} eq 'SEQ')
    {
     # sequence: just pass the coordinates
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                              type => $item->{cfg}{data}{options}{type},
                                              exists $item->{cfg}{data}{options}{name} ? (name => $item->{cfg}{data}{options}{name}) : (),
                                             },
                                            $item->{cfg}{data}{options}{__nr__},
                                           );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE')
    {
     # build the table
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                              maxcols => $item->{cfg}{data}{options}{__maxColumns__},
                                             },
                                            @{$item->{parts}}
                                           );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_ROW')
    {
     # build the row
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                             },
                                            @{$item->{parts}}
                                           );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_COL')
    {
     # build the cell
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                             },
                                            @{$item->{parts}}
                                           );
    }
  elsif ($item->{cfg}{data}{name} eq 'TABLE_HL')
    {
     # build the cell
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                             },
                                            @{$item->{parts}}
                                           );
    }
  elsif ($item->{cfg}{data}{name} eq 'X')
    {
     # index entry: transform it
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(
                                             {
                                              name => $item->{cfg}{data}{options}{__anchor},
                                             },
                                            (exists $item->{cfg}{data}{options}{mode} and lc($item->{cfg}{data}{options}{mode}) eq 'index_only') ? () : @{$item->{parts}},
                                           );
    }
  elsif (exists $xmltags{$item->{cfg}{data}{name}})
    {
     # a "simple" tag
     $xmltag=$xmltags{$item->{cfg}{data}{name}};
     $result=$me->{$me->{xmlmode}}->$xmltag(@{$item->{parts}});
    }
  else
    {
     # unknown tag, ignore it (but take care to supply an XML::Generator object, not a string)
     my $pseudotag="UnknownTag-$item->{cfg}{data}{name}";
     $result=$me->{$me->{xmlmode}}->$pseudotag(@{$item->{parts}});
    }

  # supply result
  # warn $result;
  $result;
 }


# upoint formatter
sub formatUpoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{upoint};

  # build option hash
  my %options;
  $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

  # provide the parts
  $me->{xml}->$xmltag(\%options, @{$item->{parts}});
 }

# dpoint item formatter
sub formatDpointItem
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{dpointitem};

  # provide the parts
  $me->{xml}->$xmltag(@{$item->{parts}});
 }

# dpoint text formatter
sub formatDpointText
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{dpointtext};

  # provide the parts
  $me->{xml}->$xmltag(@{$item->{parts}});
 }

# dpoint formatter
sub formatDpoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # provide the parts *without envelope as its parts are already structured*
  (@{$item->{parts}});
 }


# upoint formatter
sub formatOpoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{opoint};

  # build and init option hash
  my %options;
  $me->injectTagOptions(\%options, $xmltag, $page, $item) if $me->can('injectTagOptions');

  # provide the parts
  $me->{xml}->$xmltag(\%options, @{$item->{parts}});
 }


sub formatUlist
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{ulist};

  # provide the parts
  $me->{xml}->$xmltag(@{$item->{parts}});
 }


sub formatOlist
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{olist};

  my %options=(exists $item->{cfg}{options} and exists $item->{cfg}{options}{start} and $item->{cfg}{options}{start}) ? (start => $item->{cfg}{options}{start}) : ();

  # provide the parts
  $me->{xml}->$xmltag(\%options, @{$item->{parts}});
 }


sub formatDlist
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($page, $item))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page data parameter.\n" unless $page;
  confess "[BUG] Missing item parameter.\n" unless defined $item;

  # get the tag name
  my $xmltag=$xmltags{dlist};

  # provide the parts
  $me->{xml}->$xmltag(@{$item->{parts}});
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

  # get the tag name
  my $xmltag=$xmltags{dstreamentry};

  # provide the parts
  $me->{xml}->$xmltag(
                      {
                       name => $item->{cfg}{data}{name},
                      },
                      @{$item->{parts}}
                     );
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

  # get the tag name
  my $xmltag=$xmltags{dstreamframe};

  # provide the parts
  $me->{xml}->$xmltag(@{$item->{parts}});
 }


sub elementName
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($name, $check))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing XML element name parameter.\n" unless $name;
  confess qq([BUG] Invalid XML element name parameter "$name".\n) unless exists $xmltags{$name} or $check=1;

  # if this is a trial, return an undefined value in case the element is unknown
  return undef unless exists $xmltags{$name};

  # provide the name of the XML element
  $xmltags{$name};
 }


# convert a plain string into an XML::Generator object
# (the strings should contain valid XML)
sub string2XMLObject
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my (@strings))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing strings parameter.\n" unless @strings;

  # tranformation is done by a trick
  my $dummytag="DUMMYTAG$$";
  my $xmlobject=$me->{xmlready}->$dummytag(join('', @strings));
  @$xmlobject=map {/^<\/?$dummytag>$/ ? () : $_} @$xmlobject;
  $xmlobject;
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

=cut


# the DATA section contains the DTD
__DATA__

<?xml version="1.0" encoding="UTF-8"?>
<!ELEMENT =__root= (=__docdata=, =__slides=)>
<!ELEMENT =__docdata= (=_author=, =_title=)>
<!ELEMENT =_author= (#PCDATA)>
<!ELEMENT =_title=  (#PCDATA)>
<!ELEMENT =__slides= (=__slide=+)>
<!ELEMENT =__slide= (=headline= | =text= | =example= | =TABLE= | =ulist= | =olist= | =dlist= | %standalonetag;)+>
<!ENTITY % standalonetag "=IMAGE= | =INDEX=">
<!ELEMENT =IMAGE= EMPTY>
<!ATTLIST =IMAGE=
	src CDATA #REQUIRED
>
<!ELEMENT =INDEX= (=indexgroup=+)>
<!ELEMENT =indexgroup= (=indexphrase=+)>
<!ATTLIST =indexgroup=
	group CDATA #REQUIRED
>
<!ELEMENT =indexphrase= (=indexoccurence=+)>
<!ATTLIST =indexphrase=
	phrase CDATA #REQUIRED
>
<!ENTITY % tag "=A= | =B= | =C= | =I= | =L= | =SEQ= | =X=">
<!ELEMENT =L= (#PCDATA | %tag;)*>
<!ATTLIST =L=
	target CDATA #REQUIRED
	type CDATA #REQUIRED
>
<!ELEMENT =B= (#PCDATA | %tag;)*>
<!ELEMENT =C= (#PCDATA | %tag;)*>
<!ELEMENT =I= (#PCDATA | %tag;)*>
<!ELEMENT =X= (#PCDATA)>
<!ATTLIST =X=
	name CDATA #REQUIRED
>
<!ELEMENT =headline= (#PCDATA)>
<!ATTLIST =headline=
	abbr     CDATA #REQUIRED
	level    CDATA #REQUIRED
	template CDATA #REQUIRED
	path     CDATA #REQUIRED
	full     CDATA #REQUIRED
>
<!ELEMENT =text= (#PCDATA | %tag;)*>
<!ENTITY % list "=ulist= | =olist= | =dlist=">
<!ELEMENT =ulist= (=upoint=+)>
<!ELEMENT =upoint= (#PCDATA | %tag;)*>
<!ELEMENT =olist= (=opoint=+)>
<!ELEMENT =opoint= (#PCDATA | %tag;)*>
<!ELEMENT =dlist= (=dlistitem= | =dlistdefinition=)*>
<!ELEMENT =dlistitem= (#PCDATA | %tag;)*>
<!ELEMENT =dlistdefinition= (#PCDATA | %tag;)*>
<!ELEMENT =example= (#PCDATA | %tag;)*>
<!ELEMENT =TABLE= (=TABLE_ROW=+)>
<!ATTLIST =TABLE=
	maxcols CDATA #REQUIRED
>
<!ELEMENT =TABLE_ROW= (=TABLE_HL=+ | =TABLE_HL=+)>
<!ELEMENT =TABLE_COL= (#PCDATA | %tag;)*>
<!ELEMENT =TABLE_HL= (#PCDATA)>

