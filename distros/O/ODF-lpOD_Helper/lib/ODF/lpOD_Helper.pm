# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and 
# related or neighboring rights to the content of this file.  
# Attribution is requested but is not required.
# -----------------------------------------------------------------------------
# Please note that ODF::lpOD v1.126 has a more restrictive license 
# (your choice of GPL 3 or Apache 2.0).
# -----------------------------------------------------------------------------

use strict; use warnings; use feature qw(switch state say);

# We only call ODF::lpOD (and hence XML::Twig).  If we get warnings from
# them, or we have left-over debug printouts, we want to die to force
# immediate resolution. 
use warnings FATAL => 'all'; 

=encoding utf8

=head1 NAME

ODF::lpOD_Helper - ease-of-use wrapper for ODF::lpOD

=head1 SYNOPSIS

  use ODF::LpOD;
  use ODF::LpOD_Helper qw/:chars :DEFAULT/;

  Sorry, no examples yet... TODO TODO FIXME

  The following APIs are exported by default:

    Hsearch -- find a possibly-segmented string
    Hsubstitute -- find and replace strings
    fmt_match fmt_node fmt_tree -- debug utilities for "match" data structures
    self_or_parent
    gen_table_name
    automatic_style
    common_style

=head1 DESCRIPTION

ODF::lpOD_Helper provides higher-level Unicode-enabled search and replace
(or insert) of text which may span segments, may contain newlines, 
tabs, or multiple spaces, using ordinary Perl character strings.

Styles may be specified with a high-level notation and
the necessary ODF styles are automatically managed and fonts registered.

ODF::lpOD by itself is not convenient for text operations because

=over

=item 1.

C<ODF::lpOD> requires text to be passed as encoded binary octets,
rather than as Perl characters (see 'man perlunicode').

=item 2.

I<Search> can not match strings which span segments, such as
those created automatically by LibreOffice to support
it's "record changes" function.

=item 3.

I<Search> can not match strings containing newlines, tabs, or repeated spaces,
nor can those things be easily inseted.

=back

C<ODF::lpOD_Helper>
also works around a bug causing S<"Unknown method DESTROY"> warnings
(see L<https://rt.cpan.org/Public/Bug/Display.html?id=97977>)

=head1 PRIMARY METHODS

The "Hxxx" methods are installed into the appropriate ODF::lpOD packages
so they can be called on the same objects as related native methods
(the 'B<H>' in the names denote extensions supplied by ODF::lpOD_B<H>elper).  

=cut

package ODF::lpOD_Helper;

our $VERSION = '2.000'; # VERSION
our $DATE = '2023-03-13'; # DATE

our @EXPORT = qw(
  __disconnected_style
  automatic_style common_style
  self_or_parent
  fmt_match fmt_node fmt_tree
  gen_table_name
);
our @EXPORT_OK = qw(
  hashtostring
  $auto_pfx
);

use ODF::lpOD;
BEGIN {
  # https://rt.cpan.org/Public/Bug/Display.html?id=97977
  no warnings 'once';
  no strict 'refs';
  *{"ODF::lpOD::Element::DESTROY"} = sub {}
    unless defined &ODF::lpOD::Element::DESTROY;
}

require Exporter;
use parent 'Exporter';
sub import {
  my $class = shift;
  if (grep{$_ eq ":chars"} @_) {
    @_ = grep{$_ ne ":chars"} @_;
    lpod->Huse_character_strings();
  }
  __PACKAGE__->export_to_level(1, $class, @_);
}

use constant lpod_helper => 'ODF::lpOD_Helper';

our $auto_pfx = "auto";  # used for style & table names

use Carp;
sub oops(@) { unshift @_, "oops! "; goto &Carp::confess; }
use Data::Dumper::Interp qw/ivis ivisq vis visq dvis/;

sub fmt_node(_;$); # forward
sub fmt_tree(_@);
sub fmt_match(_);
sub self_or_parent($$);
sub hashtostring($);

my $textonly_prop_re = qr/^(?:font|size|weight|style|variant|color
                              |underline[-\ _](?:color|width|mode|style)
                              |underline|display|language|country
                              |style:font-name|fo-.*
                           )$/x;
my $paraonly_prop_re = qr/^(?:align|align-last|indent|widows|orphans|together
                              |margin|margin[-\ _](?:left|right|top|bottom)
                              |border|border[-\ _](?:left|right|top|bottom)
                              |padding|padding[-\ _](?:left|right|top|bottom)
                              |shadow|keep[-\ _]with[-\ _]next
                              |break[-\ _](?:before|after)
                           )$/x;
my $textorpara_prop_re = qr/^(?:name|parent|clone)$/;

my $text_prop_re = qr/${textorpara_prop_re}|${textonly_prop_re}/;
my $para_prop_re = qr/${textorpara_prop_re}|${paraonly_prop_re}/;

my $table_prop_re = qr/^(?:width|together|keep.with.next|display
                           |margin|margin[-\ _](?:left|right|top|bottom)
                           |break|break[-\ _](?:before|after)
                           |fo:.*     # assume it's ok if retrieved
                           |style:.*  # assume it's ok if retrieved
                           |table.*   # assume it's ok if retrieved
                        )$/x;

# Translate some single-item abbreviated properties
sub __unabbrev_props($) {
  state $abbr_props = {
    "center"      =>  [align => "center"],
    "left"        =>  [align => "left"],
    "right"       =>  [align => "right"],
    "bold"        =>  [weight => "bold"],
    "italic"      =>  [style => "italic"],
    "oblique"     =>  [style => "oblique"],
    "normal"      =>  [style => "normal", weight => "normal"],
    #?? "normal"      =>  [style => "normal", weight => "normal", variant => "normal"],
    "roman"       =>  [style => "normal"],
    "small-caps"  =>  [variant => "small-caps"],
    "normal-caps" =>  [variant => "normal"], #???
  };
  my $input = shift;
  my $output = [];
  for(my $i=0; $i <= $#$input; ++$i) {
    local $_ = $input->[$i];
    if (my $pair=$abbr_props->{$_}) { push @$output, @$pair; }
    elsif (/^(\d[\.\d]*)(pt|%)$/)   { push @$output, "size" => $_; }
    elsif (/^\d[\.\d]*$/)           { push @$output, "size" => "${_}pt"; }
    elsif ($i < $#$input)           { push @$output, $_, $input->[++$i]; }
    else                            { oops(ivis 'Unrecognized abbrev prop $_ (input=$input ix=$i)') }
  }
  return $output;
}

# Create a style.  Paragraph properties may include recognized text
# style properties, which are internally segregated and put into the
# required 'area' property and text style.  Fonts are registered as needed.
sub __disconnected_style($$@) {
  my ($context, $family, @input_props) = @_;
  my %props = @{ __unabbrev_props(\@input_props) };

  # Work around ODF::lpOD::odf_create_style bug which deletes {parent} in
  # a cloned style
  if (my $clonee = $props{clone}) {
    if (my $clonee_parent = $clonee->get_parent_style) {
      oops if $props{parent};
      $props{parent} = $clonee_parent;
    }
  }

  my $doc = $context->get_document;
  my $object;
  if ($family eq 'paragraph') {
    my (@pprops, @tprops);
    while(my ($key, $val) = each %props) {
      if    ($key =~ /${textonly_prop_re}/) { push @tprops, $key, $val; }
      elsif ($key =~ /${para_prop_re}/)     { push @pprops, $key, $val; }
      else { croak "Unrecognized paragraph pseudo-property '$key'" }
    }
    $object = odf_create_style('paragraph', @pprops);
    if (@tprops) {
      my $ts = automatic_style($context, 'text', @tprops);
      $object->set_properties(area => 'text', clone => $ts);
    }
  }
  elsif ($family eq 'text') {
    while(my ($key, $val) = each %props) {
      croak "Unk text prop '$key'\n"
        unless $key =~ /${text_prop_re}/ || $key eq "name";
      if ($key eq "font") {
        unless ($context->get_document_part()->get_font_declaration($val)) {
          $doc->set_font_declaration($val);
        }
      }
    }
    $object = odf_create_style('text', %props);
  }
  elsif ($family eq 'table') {
    while(my ($key, $val) = each %props) {
      croak "Unk table prop '$key'\n"
        unless $key =~ /${table_prop_re}/ || $key eq "name";
    }
    $object = odf_create_style('table', %props);
  }
  else { die "style family '$family' not (yet) supported" }
  return $object;
}

# Like ODF::lpOD get_text methods except:
#   Tab, line break and space objects are translated
#   The result is a normal Perl string, not octets.
# (this is a function, not a method)

# FIXME: The main purpose of this is return the text as Perl characters
# rather than octets, but it behaves differently
# than e.g. ODF::lpOD::TextElement::get_text in another way: It looks only
# at the top node, not it's children.
# Why can't this just be
#    return ODF::lpOD::Common::input_conversion( $node->get_text() );
# ???

sub _my_get_text_func($) {
  my $node = shift;
  ##local $ODF::lpOD::Common::INPUT_CHARSET = undef;
  #local $ODF::lpOD::Common::OUTPUT_CHARSET = undef;
  
  # Derived from ODF::lpOD::TextElement::get_text
  my $text;
  if ($node->get_tag eq 'text:tab')
          {
          $text = $ODF::lpOD::Common::TAB_STOP;
          }
  elsif ($node->get_tag eq 'text:line-break')
          {
          $text = $ODF::lpOD::Common::LINE_BREAK;
          }
  elsif ($node->get_tag eq 'text:s')
          {
          $text = "";
          my $c = $node->get_attribute('c') // 1;
          $text .= " " while $c-- > 0;
          }
  else
          {
          #$text = ODF::lpOD::Common::input_conversion( $node->get_text() );
          $text = $node->get_text();
          }
  return $text;
}

###############################################################

=head2 lpod->Huse_character_strings()   # or import the :chars tag

Make all methods accept and return 
Perl character strings rather than encoded binary octets
(see "UNICODE ISSUES" below).  The :chars import tag has the same effect.

You will B<always> want to use this unless your application really, really 
needs to pass un-decoded octets directly between file/network resources
and ODF::lpOD without your Perl script looking at the data along the way.
In that exceptional situation, see the "Character sets handling"
section of C<ODF::lpOD::Common>. 

=cut

sub ODF::lpOD::Common::Huse_character_strings() {
  $ODF::lpOD::Common::INPUT_CHARSET = undef;
  $ODF::lpOD::Common::OUTPUT_CHARSET = undef;
}

###############################################################

=head2 $context->Hsearch($expr)   # method of ODF::lpOD::Element

Locates all occurences of C<$expr> in the given C<$context>, returning
a match hash for each.

<$expr> may be a qr/regex/ or plain string, which may
match text which spans segments within the same paragraph
and may include repeated spaces, tabs and/or newlines.

RETURNS: 

  In array context: A list of match hashrefs, one for each match
  In scalar context: undef or a match hashref (dies if multiple matches)

Each match hash contains:

  {
    match           => The matched text
    offset          => Offset in the virtual string (including \t etc.)
    segments        => [ list of text nodes containing the match ]
    fseg_offset     => offset into the first node of the start of match
    lseg_end_offset => offset of end+1 of the match in the last node
  }

=head2 $context->Hsubstitute([content], [OPTIONS]) # ODF::lpOD::Element method

Replace all or some the text in or below an object, optionally inserting new
character style spans.  Elements which end up with empty text are removed.

$context may be a leaf (#PCDATA) or a container 
or ancestor (paragraph, table cell, or even the document body)
of the node(s) to search.

Leaves are always deleted and possibly replaced with other nodes.

[content] is a (ref to a) list of items which specifies the new content,
which may include formatting specified in a "high level" form
(an example is in the SYNOPSIS).

Each C<content> element is either 

=over

=item * A reference to a [list of format PROPs]

=item * A character string, possibly including spaces, tabes and newlines.

=back

Each [list of format PROPs] specifies a I<character style>
which will be applied only to the immediately-following text string.

Each PROP is itself either a [key => value] sublist,
or a string holding one of the following abbreviations:

  "center"      means  [align => "center"]
  "left"        means  [align => "left"]
  "right"       means  [align => "right"]
  "bold"        means  [weight => "bold"]
  "italic"      means  [style => "italic"]
  "oblique"     means  [style => "oblique"]
  "normal"      means  [style => "normal", weight => "normal"]
  "roman"       means  [style => "normal"]
  "small-caps"  means  [variant => "small-caps"]
  "normal-caps" means  [variant => "normal"], #?

  <NUM>         means  [size => "<NUM>pt],   # bare number means point size
  "<NUM>pt"     means  [size => "<NUM>pt],
  "<NUM>%"      means  [size => "<NUM>%],

Internally, an ODF "automatic" Style is created for 
each unique [list of format PROPs], re-using styles when possible.
Fonts are automatically registered.

An existing (or to-be-created) ODF Style may be used by specifying 
a single PROP of the form

  [style-name => (name of style)]

[OPTIONS] may contain:

=over 2

=item Search => string or qr/regex/

=over 2

Find an existing string and replace it, preserving existing spans.
The string must be contained within one paragraph but may be segmented.
(Without 'Search' the entire text content is replaced) (??**VERIFY THIS**)

=back

=item Chomp => TRUE

=over 2

Remove any trailing newline from the last new text string

=back

=back

RETURNS:

  In list context:   A list of 0 or more match hashrefs (see Hsearch)
  In scalar context: A match hashref; dies if there was not exactly one match
  In null context:   Nothing, but dies if there was not exactly one match

Note: C<Hsubstitute> is conceptually like a
combination of ODF::lpOD's C<search()>
and C<replace()> or C<set_text()>, and C<set_span()>
but the search can match segmented text including spaces/tabs/newlines
and may be invoked directly on a leaf node.

=cut

# $context->Hsubstitute([content], [OPTIONS])
sub ODF::lpOD::Element::Hsubstitute {
  #local $ODF::lpOD::Common::INPUT_CHARSET = undef;
  my ($context, $content_arg, $options_arg) = @_;
  my @content = @$content_arg;
  my %opts    = @$options_arg;

  my $Chomp        = delete $opts{Chomp};
  my $Search_only  = delete $opts{Search_only};
  my $Search       = delete $opts{Search} // $Search_only // qr/.+/s;
  my $Starting_pos = delete $opts{Starting_pos};
  my $debug        = delete $opts{debug};
  # my $Onceonly    = delete $opts{Onceonly}; # future
  croak "Invalid option ",avis(keys %opts) if %opts;

  while (@content and !ref($content[$#content]) and $content[$#content] eq "") {
    pop @content;
  }
  if ($Chomp and @content and !ref $content[$#content]) {
    $content[$#content] =~ s/\n\z//s;
  }

  $Search = qr/\Q${Search}\E/s unless ref($Search) eq 'Regexp';

my $show = $debug || 0; #("@content" =~ /NOTES|OTHER.*INFO/);

  my @rlist;
  # N.B. Paragraphs can be indirectly nested (via frames), so we
  # need to avoid visiting the same leaf text node more than once.
  # TODO: Re-write this to explicitly traverse the tree using XML::Twig
  #   and directly visit text nodes only once.
  my %seen_text_nodes;
  PARA:
  foreach my $para ($context->descendants_or_self(qr/text:(p|h)/)) {
    my @segments;
    my $oldtext = "";
    my @elements
      = $para->descendants_or_self(qr/^(#PCDATA|text:tab|text:line-break|text:s)$/);
    foreach my $e (@elements) {
      next if $seen_text_nodes{$e}; # incremented below after possible re-visit
      my $etext = _my_get_text_func($e);
      push @segments, { obj => $e,
                        offset => length($oldtext),
                        length => length($etext),
                        ix     => scalar(@segments),
                      };
      $oldtext .= $etext;
    }
    next unless @segments;

    my $prev_repl;

    if (defined $Starting_pos) {
      oops if $Starting_pos > length($oldtext);
      pos($oldtext) = $Starting_pos;
    }
    while ($oldtext =~ /\G.*?(${Search})/mgsc) {
      my $start_off = $-[1];
      my $end_off   = $+[1];
      my ($fsi, $lsi);
      foreach (@segments) {
        $fsi = $_->{ix} if (! defined $fsi) &&
          $_->{offset} <= $start_off && $start_off < $_->{offset}+$_->{length};
        $lsi = $_->{ix} if (! defined $lsi) &&
          $_->{offset} < $end_off && $end_off <= $_->{offset}+$_->{length};
      }
      oops unless defined $fsi and defined $lsi;
      my %r = (
               match           => $1,
               offset          => $start_off,
               segments        => [ map{$_->{obj}} @segments[$fsi..$lsi] ],
               fseg_offset     => $start_off - $segments[$fsi]->{offset},
               lseg_end_offset => $end_off - $segments[$lsi]->{offset},
              );
      unless ($Search_only) {
        if ($prev_repl) {
          # This is the second match within a paragraph...
          # @segments may have become invalid when we inserted replacement
          # content for the previous match; so re-get the text anew and
          # search again, starting immediately after the replaced content
          # from the previous match.
          my $repl_length = 0;
          foreach(@content) { $repl_length += length($_) if ! ref }
          $Starting_pos = $rlist[$#rlist]->{offset} + $repl_length;
          redo PARA;
        }
        # Insert all the new content (possibly multiple nodes) in place of
        # the segment containing the start of the match, and delete the
        # other segments as well.
        # Anything before or after the match in the deleted segments is
        # saved and put back with the new content.
        my $before = substr($oldtext,
                            $segments[$fsi]->{offset},
                            $r{fseg_offset});
        my $after  = substr($oldtext,
                            $end_off,
                            $segments[$lsi]->{length} - $r{lseg_end_offset});

if ($show) {
  warn dvis('### BEFORE: $Search @content $fsi $lsi $start_off $end_off $before $after $oldtext\n');
  for my $i (0..$#segments) {
    my %h = %{ $segments[$i] };
    $h{obj} = fmt_node($h{obj});
    warn ivisq "     segments[$i] = \%h\n";
  }
}

        $r{segments} = [
          $segments[$fsi]->{obj}->Hinsert_multi(
                                    [$before, @content, $after],
                                    [position => NEXT_SIBLING] )
        ];
        for my $i (reverse $fsi .. $lsi) {
          $segments[$i]->{obj}->delete;
        }
        if (@{$r{segments}} == 0) {
          # No content - the node was deleted with no replacement.
          # Return the containing paragraph so the caller can use it to
          # find the context, e.g. a containing table cell.
          #
          # However if the paragraph is now completely empty, delete it
          # too and return *its* parent.
          if (($para->get_text//"") eq "") {
            @{$r{segments}} = ( $para->parent // oops );
            $para->delete;
          } else {
            @{$r{segments}} = ( $para // oops );
          }
        }
if ($show) {
  warn "### AFTER :",
  map{ " segment: ".fmt_node($_)."\n" } @{ $r{segments} };
}
        $prev_repl = 1;
      }
      push @rlist, \%r;
    }
    foreach my $e (@elements) { ++$seen_text_nodes{$e} }
  }

  return @rlist if wantarray;
  croak "'$Search' matched ",scalar(@rlist)," times\n" unless @rlist==1;

  return $rlist[0];
}

# $context->Hsearch($expr, OPTIONS...)
# $context->Hsearch($expr, [OPTIONS...]) # for solidarity with Hsubstutute
sub ODF::lpOD::Element::Hsearch {
  my ($context, $expr, @opts) = @_;
  @opts = @{$opts[0]} if (@opts==1 && ref($opts[0]) eq "ARRAY");
  $context->Hsubstitute([], [Search_only => $expr, @opts]);
}

###############################################################

=head2 $context->Hinsert_multi([content...], [OPTIONS])

Insert the I<content> at the location relative to C<$context> given by

=over 6

=item position => <location>

=back

in I<OPTIONS>.  C<< <location> >> is one of the constants
used by C<ODF::lpOD::Element::insert_element>, 
for example B<FIRST_CHILD>, or B<NEXT_SIBLING>.

The I<content> is specified as a list of character strings 
and [PROP...] styles as described for C<Hsubstitute()>.  

Nothing is inserted if all text is "".

RETURNS: List of node(s) inserted

=cut

# $context->Hinsert_multi([content...], [options...])
sub ODF::lpOD::Element::Hinsert_multi($$) {
  #local $ODF::lpOD::Common::INPUT_CHARSET = undef;
  my ($context, $content_arg, $options_arg) = @_;
  my @content = @$content_arg;
  my %opts = (
    position => FIRST_CHILD,  # the default
    @$options_arg
  );
  my $position = $opts{position};

  my $root = $context->get_root;

  # Ignore extraneous initial ""s
  while (@content and ! ref $content[0] and $content[0] eq "") { 
    shift @content 
  }

  my @nodes;
  while (@content) {
    local $_ = shift @content;
    if (ref) {
      my $tprops = $_;
      my $text = shift @content
        // croak "[text style] not followed by a string\n";
      ! ref($text)
        // croak "consecutive [text style]s (no strings inbetween)\n";

      my $stylename;
      if (@$tprops == 2 && $tprops->[0] =~ /^style[-_ ]name$/) {
        $stylename = $tprops->[1];
      } else {
        my $ts = automatic_style($root, 'text', @$tprops) // oops;
        $stylename = $ts->get_name;
      }

      my $node = ODF::lpOD::Element->create('text:span')->set_class;
      $node->set_attributes({style => $stylename});
      $node->set_text($text);
      $context->insert_element($node, position => $position);
      $context = $node; 
      $position = NEXT_SIBLING; 
      push @nodes, $node;
    } else {
      while (@content && ! ref $content[0]) {
        $_ .= shift @content;  # concatenate adjacent texts
      }
      while ($_ ne "") {
        my $node;
        if (s/^(  +)//) {
          $node = ODF::lpOD::Element->create('text:s')->set_class;
          $node->set_attribute('a',length($1));
        }
        elsif (s/^\t//) {
          $node = ODF::lpOD::Element->create('text:tab')->set_class;
        }
        elsif (s/^\n//s) {
          $node = ODF::lpOD::Element->create('text:line-break')->set_class;
        }
        elsif (s/^((?:[^\t\n ]|(?<! ) (?! ))+)//s) {
          $node = ODF::lpOD::Element->create('#PCDATA')->set_class;
          $node->set_text($1);
        }
        else { oops }
        oops unless $node;
        $context->insert_element($node, position => $position);
        $context = $node; 
        $position = NEXT_SIBLING; 
        push @nodes, $node;
      }
    }
  }

  return @nodes;
}

=head1 MISC. UTILITIES

=cut

###################################################

=head2 self_or_parent($node, $tag)

Returns $node or it's nearest ancestor which matches a gi

Currently this throws an exception if neither $node or an ancestor
matches $tag.

=cut

sub self_or_parent($$) {
  my ($node, $tag) = @_;
  my $e = $node->passes($tag) ? $node : $node->parent($tag);
  # Should we return undef instead of croaking??
  croak "Neither node nor ancestors match ",vis($tag),"\n" unless $e;
  return $e;
}

###################################################

=head2 automatic_style($context, $family, PROP...)

Find or create an 'automatic' (i.e. functionally anonymous) style and
return the object.  Styles are re-used when possible, so a style should
not be modified because it might be shared.

PROPs are as described for C<Hsubstitute>.

=head2 common_style($context, $family, PROP...)

Create a 'common' (i.e. named by the user) style.

The name must be given by [name => "STYLENAME"] somewhere in PROPs.

=cut

sub automatic_style($$@);
sub automatic_style($$@) {
  my ($context, $family, @input_props) = @_;
  my $doc = $context->get_document // oops;
  my %props = @{ __unabbrev_props(\@input_props) };

  state %style_caches;  # family => { digest_of_props => stylename }
  state %counters;
  my $cache = ($style_caches{$family} //= {});
  my $cache_key = hashtostring(\%props);
  my $stylename = $$cache{$cache_key};
  if (! defined $stylename) {
    for (;;) {
      $stylename = $auto_pfx.uc(substr($family,0,1)).(++$counters{$family});
      last
        unless defined (my $s=$doc->get_style($family, $stylename));
      my $existing_key = hashtostring(scalar $s->get_properties);
      $$cache{$existing_key} //= $stylename;
    }
    $$cache{$cache_key} = $stylename;
    my $object = __disconnected_style($context,$family, %props, name=>$stylename);
    return $doc->insert_style($object, automatic => TRUE);
  } else {
    return $doc->get_style($family, $stylename);
  }
}

sub common_style($$@) {
  my ($context, $family, @input_props) = @_;
  my %props = @{ __unabbrev_props(\@input_props) };
  croak "common_style must specify 'name'\n" unless $props{name};
  my $object = __disconnected_style($context, $family, %props);
  return $context->get_document->insert_style($object, automatic => FALSE);
}

###################################################

=head2 gen_table_name($context)

Generate a table name not currently used of the form "Table<NUM>".

=cut

sub gen_table_name($) {
  my $context = shift;
  state $table_names = { map{ ($_->get_name() => 1) }
                            $context->get_document->get_body->get_tables };
  state $seq = 1;
  my $name;
   do { $name=$auto_pfx."Table".$seq++ } while exists $table_names->{$name};
  $table_names->{$name} = 1;
  return $name;
}

###################################################

=head2 hashtostring($hashref)

Returns a single string representing the keys and values of a hash

=cut

sub hashtostring($) {
  my $href = shift;
  return join("!", map{ "$_=>$href->{$_}" } sort keys %$href);
}

###################################################

=head2 fmt_node($node)

Format a single node for debug messages, without a final newline.

=head2 fmt_tree($top)

Format a node and all of it's children for debug messages.

=head2 fmt_match($matchhash)

Format a match hashreffor debug messages.

=cut

sub fmt_node(_;$) {  # for debug prints
  my ($node, $tailtextonly) = @_;
  if (! ref $node) {
    return "(invalid node: ".vis($node).")";
  }
  my $text = eval{ $node->get_text };
  $text = ODF::lpOD::Common::input_conversion($text) if defined($text);
  # FIXME: What about _my_get_text_func($)  ???
  my $tag  = eval{ $node->tag };
  my $att  = eval{ $node->get_attributes };
  my $s = "$node";
  $s =~ s/ODF::lpOD:://;
  $s =~ s/=HASH//;   # ref($node)
  $s .=  " $tag" if defined $tag;
  $s .= " ".(%$att && $tag =~ /^(table-cell|sequence)/ ? "{...}" : vis($att))
    if defined $att;

  $s .= " text=".vis($text)
    if defined($text) && (!$tailtextonly
                            || $tag !~ /text:(box|span|text|p)|office:/);
  return $s;
}
sub _fmt_tree($$$);
sub _fmt_tree($$$) {
  my ($obj,$indent,$sref) = @_;
  $indent //= 0;
  $$sref .= " "x$indent.fmt_node($obj,1)."\n";
  return unless ref $obj;
  foreach my $e ($obj->children) {
    my $oldtext = $e->get_text;
    _fmt_tree($e,$indent+1,$sref);
  }
}
sub fmt_tree(_@) { # for debugging
  my $top = shift;
  my %opts = (indent => 0, @_);
  my $indent = $opts{indent};
  my $string = "";
  if ($opts{ancestors} and ref $top) {
    $opts{indent} ||= 1;
    my @a = reverse $top->ancestors;
    shift @a; # don't show the document container
    foreach my $e (@a) {
      $string .= "<"x$indent.fmt_node($e,1)."\n";
      $indent++;
    }
  }
  _fmt_tree($top, $indent, \$string);
  return "------------\n".$string."------------\n";
}

sub fmt_match(_) { # for debugging
  my $href = shift;
  my %r = %$href;
  my @segments = map { "$_ with text ".vis(_my_get_text_func($_)) } @{$r{segments}};
  delete $r{segments};
  local $_ = ivis('%r'); s/\)$// or oops;
  return $_.", segments => [".join("\n   ",@segments)."])";
}

###################################################

=head1 UNICODE ISSUES

The usual Perl paradigm is to *decode* character data immediately when
fetching it from the outside world, process the data as Perl character 
strings, and finally *encode* results while sending them out.
Often this can done automatically by calling
C<open> or C<binmode> with an ":encoding()" specification. 

For historical reasons
ODF::lpOD is incompatible with the above paradigm out of the box
because it's methods encode result strings (into UTF-8 by default) before 
returning them to you, and attempts to decode strings you pass in before
using them.  Therefore your program must work with encoded binary and not
normal character strings, and can not use regex matching, 
substr(), length(), etc. unless only ASCII characters are present
(ASCII slides by because C<encode> and C<decode> are essentially no-ops
for those code-points).
An additional gotcha is that C<get_text> (for example) is implemented 
by C<XML::Twig> and always works with character strings, 
unlike ODF::lpOD methods.

This messy situation goes awy after calling
B<C<Huse_character_strings>>, which uses an undocumented feature 
to disable ODF::lpOD's internal encodes and decodes.
Then all methods speak and listen in characters, not octets.

If the above discussion seems bewildering, you are not alone; start with
'man perlunicode' and keep reading until the concepts are clear.  
It's a tricky subject but essential to making your programs work
with international characters.

Note: The C<< lpod->set_input_charset() >> 
and C<< lpod->set_output_charset() >> documented in C<ODF::lpOD::Common>
conflict with C<< lpod->Huse_character_strings >>.

=head1 BUGS

Only one document can ever be processed (per run) because of the use
of global state, namely the cache of automatic style objects
and information used to construct unique names.

This may someday be fixed by keeping separate state for each
unique value of C<< $context->get_document() >>.

Note: This manual was written several years after the code, and
a few uncertain details are denoted by "??" in the descriptions.

=head1 HISTORY

ODF::lpOD_Helper was first written in 2012 when ODF::lpOD was most likely
at v1.118.  At that time the author of ODF::lpOD was not available or
could not substantively respond to the problem of generalized
text search over segmented strings and white-space.

As of this writing (Feb 2023), 
ODF::lpOD seems to be no longer maintained (the most recent
release is v1.126 from 2014).  
Changes to Perl in the interim have made ODF::lpOD unusable as-is 
because S<"Unknown method DESTROY"> warnings appear
(L<https://rt.cpan.org/Public/Bug/Display.html?id=97977>).
However with C<ODF::lpOD_Helper> ODF::lpOD is once again a
useful tool.

=head1 AUTHOR

Jim Avera  (jim.avera AT gmail dot com)

=head1 LICENSE

ODF::lpOD (v1.126) may be used under your choice of the GPL 3 or Apache 2.0
license.

ODF::lpOD_Helper itself is in the Public Domain (or CC0 license) but
it requires ODF::lpOD to function and so as a practical matter usage
is restricted to ODF::lpOD's license.

=for Pod::Coverage oops

=cut

1;
