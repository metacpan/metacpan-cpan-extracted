

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.08    |03.12.2006| JSTENZEL | INDEXCLOUD POD fix: chapterdelimiter => chapterDelimiter;
# 0.07    |25.04.2006| JSTENZEL | added INDEXCLOUD;
# 0.06    |05.03.2006| JSTENZEL | FORMAT, HIDE, INDEX, INDEXRELATIONS, LOCALTOC and READY
#         |          |          | got a "standalone" configuration flag;
#         |10.03.2006| JSTENZEL | IMAGE now adds an "alt" option ("Image") as default;
# 0.05    |15.04.2005| JSTENZEL | A is now checking if it is the innermost tag/macro;
#         |16.05.2005| JSTENZEL | alt option of REF can handle backslash guarded commata;
#         |23.08.2005| JSTENZEL | doc fix: intro option of INDEXRELATIONS was not described;
# 0.04    |18.08.2003| JSTENZEL | A is a basic tag now;
#         |02.05.2004| JSTENZEL | F is a basic tag now;
#         |05.05.2004| JSTENZEL | anchors now take the number of their definition page;
#         |          | JSTENZEL | additional hook parameter: page number;
#         |          | JSTENZEL | REF: type=plain was ignored in case of a body - why? changed;
#         |          | JSTENZEL | new REF option "valueformat";
#         |          | JSTENZEL | REF: __value__ now holds an array reference to object name
#         |          |          | and page;
#         |06.05.2004| JSTENZEL | A stored headline IDs in the anchor, replaced by name;
# 0.03    |26.01.2003| JSTENZEL | X is a basic tag now;
#         |          | JSTENZEL | new index related tags INDEX and INDEXRELATIONS;
#         |02.02.2003| JSTENZEL | X is now checking if it is the innermost tag/macro;
#         |26.04.2003| JSTENZEL | documented new tags;
# 0.02    |02.10.2001| JSTENZEL | added LOCALTOC;
#         |11.10.2001| JSTENZEL | added SEQ;
#         |12.10.2001| JSTENZEL | added REF;
#         |13.10.2001| JSTENZEL | added HIDE;
#         |24.10.2001| JSTENZEL | added FORMAT and STOP;
#         |31.10.2001| JSTENZEL | added FORMAT doc;
#         |03.12.2001| JSTENZEL | now all messages mention the inflicted tag name and
#         |          |          | a source line number where possible;
# 0.01    |19.03.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Tags::Basic> - declares basic PerlPoint tags

=head1 VERSION

This manual describes version B<0.08>.

=head1 SYNOPSIS

  # declare basic tags
  use PerlPoint::Tags::Basic;

=head1 DESCRIPTION

This module declares several basic PerlPoint tags. Tag declarations
are used by the parser to determine if a used tag is valid, if it needs
options, if it needs a body and so on. Please see
\B<PerlPoint::Tags> for a detailed description of tag declaration.

Every PerlPoint translator willing to handle the tags of this module
can declare this by using the module in the scope where it built the
parser object.

  # declare basic tags
  use PerlPoint::Tags::Basic;

  # load parser module
  use PerlPoint::Parser;

  ...

  # build parser
  my $parser=new PerlPoint::Parser(...);

  ...

It is also possible to select certain declarations.

  # declare basic tags
  use PerlPoint::Tags::Basic qw(I C);


A set name is provided as well to declare all the flags at once.

  # declare basic tags
  use PerlPoint::Tags::Basic qw(:basic);


=head1 TAGS

=head2 B

marks text as I<bold>. No options, but a mandatory tag body.

=head2 C

marks text as I<code>. No options, but a mandatory tag body.


=head2 F

This is a generalized I<font> tag, introduced by C<pp2html>
and made generally available. It sets up the formatting of a
selected text. Traditionally, these are font settings like
text color and font size, but there can be more formattings.

Both options and body are mandatory.

Please note that this tag is fairly general. Accepted options and
their meaning are defined by the I<converters>, but there are
conventions that make documents portable between converters.

So, by convention, options C<color> and C<size> set up the color
and font size of the selected text, in the tradition and argument
syntax of HTML.

 A \F{color=red}<red> colored text.

=head2 FORMAT

is a container tag to configure result formatting. Configuration
settings are received via tag options and are intended to remain
valid until another modification. For example, one may set the
default text color of examples to green. This would remain valid
until the next text color setting.

Please note that this tag is very general. Accepted options and
their meaning are defined by the I<converters>. Nevertheless,
certain settings are commonly used by convention.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.


=head2 HIDE

hides everything in its body. Makes most sense when used with
a tag condition.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.


=head2 I

marks text as I<italic>. No options, but a mandatory tag body.

=head2 IMAGE

includes an I<image>. No tag body, but a mandatory option C<"src"> to pass
the image file, and an optional option C<"alt"> to store text alternatively
to be displayed. The option set is open - there can be more options
but they will not be checked by the parser. If C<alt> is not set it defaults
to an empty string (added automatically).

The image source file name will be supplied I<absolutely> in the stream.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.


=head2 INDEX

Generates an index listing all keywords collected via I<X>. Index formatting
is up to the converters.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.


=head2 INDEXCLOUD

Generates a "cloud" of the index entries. The term is inspired by the "tag clouds"
which became popular in the Internet, but the final formatting might be different,
as it is up to the converters. Not all target formats might have features to
present a cloud, but finally one should get a kind of a ranking that shows which
index entries were used frequently.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.

This tag can be configured by options. All options are optional, except where stated.

=over

=item chapterDelimiter

A supplementary option to C<chapters>. Defines the delimiter string used to separate
multiple chapter names in the C<chapters> value.

Without this parameter the value of C<chapters> is treated as I<one> chapter title.

This option has no effect if C<chapters> is not used.

Example:

  chapterDelimiter="==" chapters="One Chapter==Another Chapter"


=item chapters

This mandatory parameter specifies the chapters of which index entries should be
taken into account, including all their subchapters. A chapter is specified by
its title, as with C<\REF>. To list more than one chapter, delimit the titles
by a string that is not contained in them, and declare this delimiter string with
the C<chapterDelimiter> option.

Example:

  chapterDelimiter="==" chapters="One Chapter==Another Chapter"


=item coolestColor

The color that should be used for index entries that have the least references.
The color is specified the HTML way, hexadecimal with a C<#> prefix.

As colorization strongly depends on the target format, converters I<can> ignore
this setting.

This parameter is optional. The default value is subject of converter definitions.

Example:

  coolestColor="#ff3c5d"


=item hottestColor

This is the color that should be used for index entries that are referenced most.
It is specified as a hexadecimal RGB value, preceded by C<#> (as in HTML).

As colorization strongly depends on the target format, converters I<can> ignore
this setting.

This parameter is optional. The default value is subject of converter definitions.

Example:

  hottestColor="#ff3c5d"


=item intro

An optional text to be displayed before the cloud. If there are no index entries
found in the chapters specified, this text will I<not> be displayed.

This parameter is optional.

Example:

  intro="Index entries in this chapter:"


=item largestFont

An optional parameter configuring the font size for index entries referenced most,
in pixels. The default size is up the converters.

Depending on their capabilities converters might ignore this setting.

Example:

  largestFont=40


=item smallestFont

This option specifies the minimal font size to be used in the cloud. The default
value is up to the converters.

Depending on their capabilities converters might ignore this setting.

Example:

  smallestFont=10


=item top

Limits the number of index entries visualized by the cloud to the specified
number of top rated entries.

Example:

  top=20


=back


=head2 INDEXRELATIONS

Inserts a chapter "cross reference" based on the keywords found in all
chapters using this tag.

So, the tag has two functions. First, it I<collects> all index entries
made in its chapters (and optionally all its subchapters). Second, it
includes a reference to other chapters with I<INDEXRELATIONS> which
match the own index entries according to the configuration.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.

Configuration is done via options.

=over 4

=item format

This setting configures what kind of list will be generated. The following
values are specified:

=over 4

=item bullets

produces an I<unordered> (bullet) list,

=item enumerated

produces an I<ordered> list,

=item numbers

produces a list where each chapter is preceeded by its chapter number,
according to the documents hierarchy (C<1.1.5>, C<2.3.> etc.).

=back

If this option is omitted, the setting defaults to C<bullets>.

=item intro

A text that can optional preceed the list of related chapters.
I<This text is not displayed if the list is empty.>

=item readdepth

Configures where keywords shall be collected - B<startpage> includes
only the chapter where the tag is located in, while B<full> includes
all the subchapters as well.

Defaults to C<full>.

=item reldepth

Determines which keywords of other chapters shall be taken into account:
keywords found in the chapters containing I<INDEXRELATIONS> directly
(B<startpage>), or all their subchapters as well (B<full>).

Defaults to C<full>.

=item threshold

Sets up what chapters shall be counted as "related", basing on the matching
index entries: can be set up absolutely (e.g. C<3 similar entries at least>) or
by a percentage (e.g. C<50% of I<my> entries shall be marked there at least>).

Defaults to 100%.

=item type

B<linked> makes each listed chapter title a link to the related
chapter. Note that this feature depends on the target formats link
support, so results may vary.

By default, titles are displayed as I<plain text> - B<plain> can be
used to specify this explicitly.

=back

B<Examples:>


  \INDEXRELATIONS{format=numbers}

C<>

  \INDEXRELATIONS{threshold="100%"
                  format=enumerated
                  type=plain}

C<>

  \INDEXRELATIONS{readdepth=full
                  reldepth=startpage
                  threshold="50%"
                  format=bullets
                  type=linked}




=head2 LOCALTOC

inserts a list of subchapters, which means a list of the plain subchapter
titles. This is especially useful at the beginning of a greater document
section, or on an introduction page where you want to preview what the
audience can expect in the following talk section.

Using a tag relieves the documents author from writing and maintaining
this list manually.

If used as the only contents of a text paragraph the paragraph wrapper
will be removed from the stream and the tag is streamed standalone.

There is no tag body, but the result can be configured by I<options>.

=over 4

=item depth

Subchapters may have subchapters as well. By default, the whole tree is
displayed, but this can be limited by this option. Pass the I<number>
of sublevels that shall be included. The lowest possible value is C<1>.
Invalid option values will cause syntax errors.

Consider you are in a level 1 headline with these subchapters:

  ==Details 1
  ==Details 2
  ===Details 2 explained
  ===Details 2 furtherly explained
  ==Conclusion

Depth C<1> will result in listing "Details 1", "Details 2" and "Conclusion".
Depth C<2> or greater will add the explanation subchapters of level 3.

Note that the option expects an I<offset> value. The list depth is
independend of the I<absolute> levels of subchapters. This way,
your settings will remain valid even if absolute levels change (which
might happen when the document is included, for example).

=item format

This setting configures what kind of list will be generated. The following
values are specified:

=over 4

=item bullets

produces an unordered list,

=item enumerated

produces an I<ordered> list,

=item numbers

produces a list where each chapter is preceeded by its chapter number,
according to the documents hierarchy (C<1.1.5>, C<2.3.> etc.).

=back

If this option is omitted, the setting defaults to C<bullets>.


=item type

B<linked> makes each listed subchapter title a link to the related
chapter. Note that this feature depends on the target formats link
support, so results may vary.

By default, titles are displayed as I<plain text> - B<plain> can be
used to specify this explicitly.


=back

B<Examples:>


  \LOCALTOC

C<>

  \LOCALTOC{depth=2}

C<>

  \LOCALTOC{format=enumerated type=linked}



=head2 READY

declares the document to be read completely. No options, no body. Works
instantly. Not even the current paragraph will become part of the result.
I<This tag is still experimental, and its behaviour may change in future versions.>
It is suggested to use it in a single text paragraph, usually embedded
into conditions.

  ? ready

C<>

  \READY

C<>

  ? 1


=head2 REF

This is a very general and highly configurable reference.
It can be used both to make linked and unlinked references,
it can fallback to alternative references if necessary,
and it can finally be that optional that the specified
reference does not even has to exist.

There are various options. Please note that several options
are filled by the parser. They are not intended to be
propagated to document authors.

To make best use of \REF it is recommended to register
all anchors at parsing time (with the parsers anchor
object passed to all tag hooks).


=over 4

=item name

specifies the name of the target anchor.
A missing link is an error unless C<occasion>
is set to a true value or an C<alt>ternative
address can be found.

Links are verified using the parsers anchor
object which is passed to all tag hooks.

=item type

configures which way the result should be produced:

I<linked>: The result is made a link to the referenced object.

I<plain>:  This is the default and means that the result is supplied as plain text.
(This is the body text. For bodyless use, option I<valueformat> determines which text this is.)

=item valueformat

This option configures which text to display I<if the tag has no body>. If there I<is> a
tag body, this option is ignored and the body text is used.

=over 4

=item pure

This is the default. The text displayed is the I<value> of the referenced object.
The value of a referenced object highly depends on its construction method. Please
refer to the specific elements documentation for details or just find it out be a trial.

  Headline anchors made by the parser have an value
  of the "headline string", which means the pure title
  without any included tags.

  Sequence numbers made by C<\SEQ> are evaluated
  with their respective numbers.


=item pagetitle

The I<title> of the page the referenced object is located in.

=item pagenr

The I<number> of the page the referenced object is located in, e.g. "1.2.3.4.".
(Note that the format depends on the documents numbering scheme, which might be determined
by the used converter and calling options.)

=back



=item alt

If the anchor specified by C<name> cannot be found,
the tag will try all entries of a comma separated list
specified by this options value. (For readability,
commata may be surrounded by whitespaces.) Trials
follow the listed link order, the first valid address
found will be used.

If an alternative contains commata itself, guard them
by a preceeding backslash.

Links are verified using the parsers anchor
object which is passed to all tag hooks.

=item occasion

If the tag cannot find a valid address (either
by C<name> or by trying <alt>), usually an
error occurs. By setting this option to a true
value a missing link will be ignored. The result
is equal to a I<non specified> C<\REF> tag.

=item __body__

A flag saying there was a body specified or not.
This information can help converters to start a translation
before having read the tag body tokens (producing
links, a tag without body means that we have to
use the value of the referenced object (see C<__value__>)
our text, otherwise, the body text must be used).

=item __value__

The value of the (finally) referenced object. This
only works if the referenced anchor was registered
to the parsers C<PerlPoint::Anchors> object which
is passed to all tag hooks.

=item __chapter__

The I<absolute> number of the chapter the reference points to.
Again, this only works if the referenced anchor was registered
to the parsers C<PerlPoint::Anchors> object.

=back


=head2 SEQ

Inserts the next value of a certain numerical sequence.
Optionally, the generated number can be made an I<anchor>
to reference it at another place.

There is no tag body, but there are several I<options>.
Please note that the parser passes informations by
internal options as well.


=over 4

=item type

This specifies the sequence the number shall
belong to. If the specified string is not already
registered as a sequence, a new sequence is opened.
The first number in a new sequence is C<1>. If
the sequence is already known, the next number in
it will be supplied.

=item name

If passed, this option sets an anchor name which
is registered to the parsers C<PerlPoint::Anchors>
object (which is passed to all tag hooks). This makes
it easy to reference the generated number at another
place (by \REF or another referencing tag). The value
of such a link is the sequence number.

By default, no anchor is generated.

=item __nr__

This is the generated sequence number, inserted by the parser.
No user option.

=back

=head2 STOP

Enforces an syntactical error which stops document processing immediately.
Most useful when used with tag conditions.

=head2 X

Marks the body to included into the index. Formatting of the index is up to
the converters, as is its location unless the I<INDEX> tag is used to include
it explicitly.

There are no basic options, but usually converters declare their own, so please
refer to the docs of your preferred converter for option details.


=head1 TAG SETS

There is only one set "basic" including all the tags.

=cut


# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Tags::Basic;

# declare package version
$VERSION=0.08;

# declare base "class"
use base qw(PerlPoint::Tags);


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;
use vars qw(%tags %sets);

# = LIBRARY SECTION ======================================================================

# load modules
use File::Basename;
use Cwd qw(cwd abs_path);
use PerlPoint::Constants 0.14 qw(:parsing :tags);


# = CODE SECTION =========================================================================

# private variables
my (%seq, %index);

# tag declarations
%tags=(
       # base fomatting tags: no options, mandatory body
       B => {body => TAGS_MANDATORY,},
       C => {body => TAGS_MANDATORY,},
       I => {body => TAGS_MANDATORY,},


       # anchor
       A => {
             # optional options, mandatory body
             options => TAGS_MANDATORY,
             body    => TAGS_OPTIONAL,

             # hook - update the hash of index entries
             hook    => sub
                         {
                          # take parameters
                          my ($tagLine, $options, $body, $anchors, $headlineIds, $chapterNr)=@_;

                          # inits
                          my $ok=PARSING_OK;

                          # probably we should check if the anchor entry is the innermost tag
                          # - which it currently should be (at least for HTML targets), but of
                          # course this makes it more inconvenient for users ...
                          warn qq(\n\n[Error] Anchor tags need to be the innermost tags/macros in line $tagLine, sorry.\n) and return(PARSING_ERROR) if grep((ref), @$body);

                          # check options
                          $ok=PARSING_FAILED, warn qq(\n\n[Error] Missing "name" option in A tag, line $tagLine.\n) unless exists $options->{name};

                          # all right?
                          if ($ok==PARSING_OK)
                           {
                            # add an anchor
                            $anchors->add($options->{name}, $options->{name}, $chapterNr);
                           }

                          # flag success
                          $ok;
                         },
            },


       # index entry
       X => {
             # optional options, mandatory body
             options => TAGS_OPTIONAL,
             body    => TAGS_MANDATORY,

             # hook - update the hash of index entries
             hook    => sub
                         {
                          # take parameters
                          my ($tagLine, $options, $body, $anchors, $headlineIds, $chapterNr)=@_;

                          # probably we should check if the index entry is the innermost tag
                          # - which it currently should be, but of course this makes it more
                          # inconvenient for users ...
                          warn qq(\n\n[Error] Index tags need to be the innermost tags/macros in line $tagLine, sorry.\n) and return(PARSING_ERROR) if grep((ref), @$body);

                          # add or update entry (this only works if the tag is the innermost tag/macro)
                          my $entry=join(' ', @$body);
                          $index{tags}{$headlineIds}{$entry}++;

                          # add an anchor (with a generic name), store its name for \INDEX
                          # and make it part of the option list (for converter access)
                          $anchors->add((my $anchor)=$anchors->generic, $headlineIds, $chapterNr);
                          push(@{$index{anchors}{$entry}}, [$anchor, (split('-', $headlineIds))[-1]], $chapterNr);
                          $options->{__anchor}=$anchor;

                          # flag success
                          PARSING_OK;
                         },
            },


       # full index
       INDEX => {
                 # no body, currently no options
                 body    => TAGS_DISABLED,
                 options => TAGS_DISABLED,

                 # can be used as a standalone tag
                 standalone => 1,

                 # activate the finish hook
                 hook    => sub {PARSING_OK;},

                 # finish hook - provide index data
                 finish  => sub
                             {
                              # take parameters
                              my ($options, $anchors)=@_;

                              # preformat an index
                              foreach my $entry (sort keys %{$index{anchors}})
                               {
                                my $group=uc(substr($entry, 0, 1));
                                $group='_' if $group=~/[\W\d]/;
                                push(@{$options->{__anchors}{$group}}, [$entry, $index{anchors}{$entry}]);
                               }

                              # flag success
                              PARSING_OK;
                             },
                },


       # index cloud - the implementation here is very similar to INDEX
       INDEXCLOUD => {
                      # no body, currently no options
                      body    => TAGS_DISABLED,
                      options => TAGS_OPTIONAL,

                      # can be used as a standalone tag
                      standalone => 1,

                      # activate the finish hook
                      hook    => sub {PARSING_OK;},

                      # finish hook - provide index data
                      finish  => sub
                                  {
                                   # take parameters
                                   my ($options, $anchors)=@_;

                                   # preformat an index
                                   foreach my $entry (sort keys %{$index{anchors}})
                                    {
                                     my $group=uc(substr($entry, 0, 1));
                                     $group='_' if $group=~/[\W\d]/;
                                     push(@{$options->{__anchors}{$group}}, [$entry, $index{anchors}{$entry}]);
                                    }

                                   # flag success
                                   PARSING_OK;
                                  },
                     },


       # index crossref (related chapters according to matching index entries)
       INDEXRELATIONS => {
                          # options, no body
                          options => TAGS_OPTIONAL,
                          body    => TAGS_DISABLED,

                          # can be used as a standalone tag
                          standalone => 1,

                          # hook!
                          hook    => sub
                                      {
                                       # take parameters
                                       my ($tagLine, $options, $body, $anchors, $headlineIds, $chapterNr)=@_;

                                       # declare variables
                                       my $ok=PARSING_OK;

                                       # check options
                                       $ok=PARSING_ERROR,  warn qq(\n\n[Error] Option "readdepth" of tag INDEXRELATIONS needs to be "startpage" or "full", line $tagLine.\n) if exists $options->{readdepth} and $options->{readdepth}!~/^(startpage|full)$/;
                                       $ok=PARSING_ERROR,  warn qq(\n\n[Error] Option "reldepth" of tag INDEXRELATIONS needs to be "startpage" or "full", line $tagLine.\n) if exists $options->{reldepth} and $options->{reldepth}!~/^(startpage|full)$/;
                                       $ok=PARSING_ERROR,  warn qq(\n\n[Error] Option "threshold" of tag INDEXRELATIONS needs to be a number or a valid percentage spec, line $tagLine.\n) if exists $options->{threshold} and $options->{threshold}!~/^\s*((((\d{1,2})|(100))\s*\%)|(\d+))\s*$/;

                                       $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "format" setting "$options->{format}" in LOCALTOC tag, line $tagLine.\n)
                                         if     exists $options->{format}
                                            and $options->{format}!~/^(bullets|enumerated|numbers)$/;

                                       $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "type" setting "$options->{type}" in LOCALTOC tag, line $tagLine.\n)
                                         if     exists $options->{type}
                                            and $options->{type}!~/^(linked|plain)$/;

                                       # check successfull?
                                       return $ok unless $ok==PARSING_OK;

                                       # set defaults, if necessary
                                       if ($ok==PARSING_OK)
                                         {
                                          $options->{format}='bullets' unless exists $options->{format};
                                          $options->{type}='plain'     unless exists $options->{type};
                                         }

                                       # note occurence
                                       $index{idr}{$headlineIds}={};

                                       # pass the headline id to the finish hook
                                       $options->{__id}=$headlineIds;

                                       # flag success
                                       PARSING_OK;
                                      },

                          # finish hook - extract index data
                          finish  => sub
                                      {
                                       # take parameters
                                       my ($options)=@_;

                                       # declarations
                                       my @chapters;

                                       # prepare the index for cross references unless done before
                                       unless (exists $index{flags}{arranged})
                                         {
                                          # make a list of all entry points (to avoid multiple
                                          # usage of "keys %..." later on)
                                          my @collectors=keys %{$index{idr}};

                                          # build a pattern to search for matching chapters
                                          my $pattern=join('|', map {"($_)"} keys %{$index{idr}});

                                          # now collect all relevant tags for their "parent" INDEXRELATIONs
                                          foreach my $chapter (grep(/^($pattern)/o, keys %{$index{tags}}))
                                            {
                                             # make a list of index entries known for this chapter
                                             my %entries;
                                             @entries{keys %{$index{tags}{$chapter}}}=();

                                             # store index entries for all entry points (collectors)
                                             foreach my $collector (grep($chapter=~/^$_/, @collectors))
                                               {
                                                # Found in the collectors own chapter? Note this.
                                                @{$index{idr}{$collector}{direct}}{keys %entries}=() if $chapter eq $collector;

                                                # ALL occurences, including those in collectors subchapters, are stored in a second list.
                                                @{$index{idr}{$collector}{full}}{keys %entries}=();
                                               }
                                            }

                                          # mark that data were arranged
                                          $index{flags}{arranged}=1;
                                         }

                                       # get chapter id (and delete it by the way)
                                       my $headlineIds=delete($options->{__id});

                                       # get all index entries of your own chapter, depending on the depth option
                                       my %entries;
                                       @entries{exists $index{idr}{$headlineIds} ? keys %{$index{idr}{$headlineIds}{(exists $options->{readdepth} and lc($options->{readdepth}) eq 'startpage') ? 'direct' : 'full'}} : ()}=();

                                       # anything found?
                                       if (%entries)
                                         {
                                          # collect data (skip all chapters in the same hierachy chain)
                                          foreach my $id (sort grep {(not _checkHeadlineChain($_, $headlineIds))} keys %{$index{idr}})
                                            {
                                             # scopy
                                             my @found;

                                             # get all equal entries;
                                             @found=map {exists $entries{$_} ? $_ : ()} keys %{$index{idr}{$id}{(exists $options->{reldepth} and lc($options->{reldepth}) eq 'startpage') ? 'direct' : 'full'}};

                                             # calculate percentage, extract chapter id
                                             my $percentage=100*@found/scalar(keys %entries);
                                             my $chapter=(split(/-/, $id))[-1];

                                             # validate results - can we use them?
                                             if (@found)
                                               {
                                                # validate results - can we use them?
                                                if (exists $options->{threshold})
                                                  {
                                                   # percentage calculation required?
                                                   if ($options->{threshold}=~/^\s*((\d{1,2})|(100))\s*\%\s*$/)
                                                     {
                                                      # check percentage
                                                      push(@chapters, [$chapter, $percentage]) if $percentage>=$1;
                                                     }
                                                   else
                                                     {
                                                      # check the number of results
                                                      push(@chapters, [$chapter, $percentage]) if $options->{threshold}<=@found;
                                                     }
                                                  }
                                                else
                                                  {
                                                   # no threshold - use results
                                                   push(@chapters, [$chapter, $percentage]);
                                                  }
                                               }
                                            }
                                         }

                                       # provide results via option, sort it by relevance
                                       $options->{__data}=[sort {$a->[1]<=>$b->[1]} @chapters];

                                       # flag success in the appropriate way
                                       @chapters ? PARSING_OK : PARSING_IGNORE;
                                      },
            },


       # container of formatting switches
       FORMAT => {
                  # all switches are passed by options
                  options => TAGS_MANDATORY,

                  # no body needed
                  body    => TAGS_DISABLED,

                  # can be used as a standalone tag
                  standalone => 1,
                 },


       # format a selected text ("F" initially meant "font")
       F     => {
                 # options and body both are required
                 options => TAGS_MANDATORY,
                 body    => TAGS_MANDATORY,
                },

       # resolve a reference
       HIDE  => {
                 # conditions are options (currently), so ...
                 options => TAGS_OPTIONAL,

                 # there must be something to hide
                 body    => TAGS_MANDATORY,

                 # hook!
                 hook    => sub
                             {
                              # if this hook is invoked, it means we *shall* hide
                              # all content, so instruct the parser appropriately
                              PARSING_ERASE;
                             },
                },

       # image: no body, but several mandatory options
       IMAGE => {
                 # mandatory options
                 options => TAGS_MANDATORY,

                 # no body required
                 body    => TAGS_DISABLED,

                 # can be used as a standalone tag
                 standalone => 1,

                 # hook!
                 hook    => sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($tagLine, $options)=@_;

                              # check them
                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Missing "src" option in IMAGE tag, line $tagLine.\n) unless exists $options->{src};
                              $ok=PARSING_ERROR,  warn qq(\n\n[Error] Image file "$options->{src}" does not exist or is no file in IMAGE tag, line $tagLine.\n) if $ok==PARSING_OK and not (-e $options->{src} and not -d _);

                              # add "alt" option, if necessary
                              $options->{alt}='Image' unless exists $options->{alt};

                              # add current path to options, if necessary (deprecated)
                              $options->{__loaderpath__}=cwd() if $ok==PARSING_OK;

                              # absolutify the image source path (should work on UNIX and DOS, but other systems?)
                              my ($base, $path, $type)=fileparse($options->{src});
                              $options->{src}=join('/', abs_path($path), basename($options->{src})) if $ok==PARSING_OK;

                              # supply status
                              $ok;
                             },
                },

       # subchapter list
       LOCALTOC => {
                    # no body, optional options
                    body    => TAGS_DISABLED,
                    options => TAGS_OPTIONAL,

                    # can be used as a standalone tag
                    standalone => 1,

                    # hook in to check option values
                    hook    => sub
                                {
                                 # declare and init variable
                                 my $ok=PARSING_OK;

                                 # take parameters
                                 my ($tagLine, $options)=@_;

                                 # check them
                                 $ok=PARSING_FAILED, warn qq(\n\n[Error] LOCALTOC tag option "depth" requires a number greater 0, line $tagLine.\n)
                                  if     exists $options->{depth}
                                     and $options->{depth}!~/^\d+$/
                                     and $options->{depth};

                                 $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "format" setting "$options->{format}" in LOCALTOC tag, line $tagLine.\n)
                                  if     exists $options->{format}
                                     and $options->{format}!~/^(bullets|enumerated|numbers)$/;

                                 $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "type" setting "$options->{type}" in LOCALTOC tag, line $tagLine.\n)
                                  if     exists $options->{type}
                                     and $options->{type}!~/^(linked|plain)$/;

                                 # set defaults, if necessary
                                 if ($ok==PARSING_OK)
                                   {
                                    $options->{depth}=0          unless exists $options->{depth};
                                    $options->{format}='bullets' unless exists $options->{format};
                                    $options->{type}='plain'     unless exists $options->{type};
                                   }

                                 # supply status
                                 $ok;
                                },
                   },


       # declare document to be complete
       READY => {
                 # no options required
                 options => TAGS_DISABLED,

                 # no body required
                 body    => TAGS_DISABLED,

                 # can be used as a standalone tag
                 standalone => 1,

                 # hook!
                 hook    => sub
                             {
                              # flag that parsing is completed
                              PARSING_COMPLETED;
                             },
                },


       # resolve a reference
       REF   => {
                 # at least one option is required
                 options => TAGS_MANDATORY,

                 # there can be a body
                 body    => TAGS_OPTIONAL,

                 # hook!
                 hook    => sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($tagLine, $options, $body, $anchors)=@_;

                              # check them (a name must be specified at least)
                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Missing "name" option in REF tag, line $tagLine.\n) unless exists $options->{name};

                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "type" setting "$options->{type}" in REF tag, line $tagLine.\n)
                                if     exists $options->{type}
                                   and $options->{type}!~/^(linked|plain)$/;

                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "valueformat" setting "$options->{valueformat}" in REF tag, line $tagLine.\n)
                                if     exists $options->{valueformat}
                                   and $options->{valueformat}!~/^(pure|pagetitle|pagenr)$/;

                              # set defaults, if necessary
                              $options->{type}='plain' unless exists $options->{type};
                              $options->{valueformat}='pure' unless exists $options->{valueformat};

                              # store a body hint
                              $options->{__body__}=@$body ? 1 : 0;

                              # format address to simplify anchor search
                              $options->{name}=~s/\s*\|\s*/\|/g if exists $options->{name};

                              # supply status
                              $ok;
                             },

                 # afterburner
                 finish =>  sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($options, $anchors)=@_;

                              # try to find an alternative, if possible
                              if (exists $options->{alt} and not $anchors->query($options->{name}))
                                {
                                 foreach my $alternative (split(/\s*(?<!\\),\s*/, $options->{alt}))
                                   {
                                    # remove guarding backslashes
                                    $alternative=~s/(?<!\\)\\//g;
                                    $alternative=~s/\\\\/\\/g;

                                    if ($anchors->query($alternative))
                                      {
                                       warn qq(\n\n[Info] Unknown link address "$options->{name}" is replaced by alternative "$alternative" in REF tag.\n);
                                       $options->{name}=$alternative;
                                       last;
                                      }
                                   }
                                }

                              # check link for being valid - finally
                              unless ($anchors->query($options->{name}))
                                {
                                 # allowed case?
                                 if (exists $options->{occasion} and $options->{occasion})
                                   {
                                    $ok=PARSING_IGNORE;
                                    warn qq(\n\n[Info] Unknown link address "$options->{name}": REF tag ignored.\n);
                                   }
                                 else
                                   {
                                    $ok=PARSING_FAILED;
                                    warn qq(\n\n[Error] Unknown link address "$options->{name}" in REF tag.\n);
                                   }
                                }
                              else
                                {
                                 # link ok, get value and chapter number
                                 @{$options}{qw(__value__ __chapter__)}=@{$anchors->query($options->{name})->{$options->{name}}};
                                }

                              # supply status
                              $ok;
                             },
                },


       # add a new sequence entry
       SEQ   => {
                 # at least one option is required
                 options => TAGS_MANDATORY,

                 # no body required
                 body    => TAGS_DISABLED,

                 # hook!
                 hook    => sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($tagLine, $options, $body, $anchors, $headlineIds, $chapterNr)=@_;

                              # check them (a sequence type must be specified, a name is optional)
                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Missing "type" option in SEQ tag, line $tagLine.\n) unless exists $options->{type};

                              # still all right?
                              if ($ok==PARSING_OK)
                                {
                                 # get a new entry, store it by option
                                 $options->{__nr__}=++$seq{$options->{type}};

                                 # if a name was set, store it together with the value
                                 $anchors->add($options->{name}, $seq{$options->{type}}, $chapterNr) if $options->{name};
                                }

                              # supply status
                              $ok;
                             },
                },


       # stop document processing by raising an syntactical error
       STOP  => {
                 # conditions are options (currently), so ...
                 options => TAGS_OPTIONAL,

                 # no body needed
                 body    => TAGS_DISABLED,

                 # hook!
                 hook    => sub
                             {
                              # enforce fatal error
                              PARSING_FAILED;
                             },
                },
      );


%sets=(
       basic => [qw(A B C I FORMAT HIDE IMAGE LOCALTOC READY REF SEQ STOP)],
      );



# INTERNAL HELPER FUNCTIONS ###########################################

sub _checkHeadlineChain
 {
  # get parameters
  my ($c1, $c2)=@_;

  # quick check
  return 1 if $c1 eq $c2;

  # declare variable
  my $rc=0;

  # split the chain strings
  $c1=[split('-', $c1)];
  $c2=[split('-', $c2)];

  # make $c1 pointing to the shorter array
  ($c1, $c2)=($c2, $c1) if @$c1>@$c2;

  # now compare all levels of @c1
  for (my $i=0; $i<@$c1; $i++)
    {
     # if there is a different element, the chains differ
     return $rc if $c1->[$i] ne $c2->[$i];
    }

  # ok, these are in the same chain
  return 1;
 }


1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 SEE ALSO

=over 4

=item B<PerlPoint::Tags>

The tag declaration base "class".

=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 1999-2004.
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

