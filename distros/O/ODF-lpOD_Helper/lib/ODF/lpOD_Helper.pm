# License: Public Domain or CC0 See
# https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.
# -----------------------------------------------------------------------------
# Please note that ODF::lpOD, as of v1.126, has a more restrictive license
# (your choice of GPL 3 or Apache 2.0).
# -----------------------------------------------------------------------------

use strict; use warnings;
# We only call ODF::lpOD (and hence XML::Twig), and if we get warnings
# we want to die to force immediate resolution.
# If somebody is launching a moon probe or controlling an artificial heart
# they should audit all libraries they use for 'user warnings FATAL ...'
# and remove such from their private copies of the code.
use warnings FATAL => 'all';

use feature qw(say state current_sub lexical_subs);
no warnings "experimental::lexical_subs";
use utf8;

=encoding utf8

=head1 NAME

ODF::lpOD_Helper - fix and enhance ODF::lpOD

=head1 SYNOPSIS

  use ODF::LpOD;
  use ODF::LpOD_Helper;
  use feature 'unicode_strings';

  # Find "Search Phrase" even if it is segmented or crosses span boundaries
  @matches = $context->Hsearch("Search Phrase");

  # Replace every occurrence of "Search Phrase" with "Hi Mom"
  $body->Hreplace("Search Phrase", ["Hi Mom"], multi => TRUE)
    or die "not found";

  # Replace "{famous author}" with "Stephen King" in bold, large red text.
  #
  $body->Hreplace("{famous author}",
                  [["bold", size => "24pt", color => "red"], "Stephen King"]
                 );

  # Call a callback function to control replacement and searching
  #
  $body->Hreplace("{famous author}", sub{ ... });

  # Work around bugs/limitations in ODF::lpOD::Element::insert_element
  # so that position => WITHIN works when $context is a container.
  #
  $new_elt = $context=>Hinsert_element($thing, position=>WITHIN, offset=>...)

  # Similar, but inserted segment(s) described by high-level spec
  #
  $context=>Hinsert_content([ "The author is ", ["bold"], "Stephen King"],
                            position=>WITHIN, offset => ... );

  # Work around bug in ODF::lpOD::Element::get_text(recursive => TRUE)
  # so that tab, line-break, and spacing objects are expanded correctly
  #
  $text = $context->Hget_text(); # include nested paragraphs

  # Create or reuse an 'automatic' (pseudo-anonymous) style
  $style = $doc->Hautomatic_style($family, properties...);

  # Remove problematic 'rsid' styles left by LibreOffice which interfere
  # with cloning content
  $context->Hclean_for_cloning();
  do_something( $context->clone );

  # Format a node or entire tree for debug messages
  say fmt_node($elt);
  say fmt_tree($elt);

The following functions are exported by default:

  The Hr_* constants used by the Hreplace method.
  fmt_match fmt_node fmt_tree fmt_node_brief fmt_tree_brief

=head1 DESCRIPTION

ODF::lpOD_Helper enables transparent Unicode support,
provides higher-level multi-segment text search & replace methods,
and works around ODF::lpOD bugs and limitations.

Styles and hyperlinks may be specified with a high-level notation and
the necessary span and style objects are automatically created
and fonts registered.

=cut

package ODF::lpOD_Helper;

{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} = 997.999; }
our $VERSION = '6.015'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2025-06-09'; # DATE from Dist::Zilla::Plugin::OurDate

use Carp;
use Data::Dumper::Interp 6.004 qw/visnew
     vis  viso  avis  alvis  ivis  dvis  hvis  hlvis
     visq visoq avisq alvisq ivisq dvisq hvisq hlvisq
     rvis rvisq ravis ravisq rhvis rhvisq
     rivis rivisq rdvis rdvisq
     addrvis rvis rvisq u quotekey qsh qshlist qshpath/;

our @EXPORT = qw(
  Hr_STOP Hr_SUBST Hr_RESCAN
  Hor_cond
  fmt_match fmt_node fmt_tree fmt_node_brief fmt_tree_brief
  fmt_Hreplace_result fmt_Hreplace_results
);
our @EXPORT_OK = qw(
  hashtostring arraytostring
  AUTO_PFX
  Hr_MASK
  TEXTLEAF_FILTER PARA_FILTER TEXTCONTAINER_FILTER TEXTLEAF_OR_PARA_FILTER
  ROW_FILTER COLUMN_FILTER CELL_FILTER TABLE_FILTER
  SPAN_FILTER FRAME_FILTER
);

use constant {
  Hr_STOP   => 1,
  Hr_SUBST  => 2,
  Hr_RESCAN => 4,
  Hr_MASK   => 7,
};

sub _is_Hr_valid($) { ($_[0]//"invalid") =~ /^[01236]$/ }

use ODF::lpOD;
use XML::Twig 3.53; # force version which fixes precedence warnings

#$ODF::lpOD::Common::DEBUG = TRUE;

BEGIN {
  # https://rt.cpan.org/Public/Bug/Display.html?id=97977
  no warnings 'once';
  no strict 'refs';
  *{"ODF::lpOD::Element::DESTROY"} = sub {}
    unless defined &ODF::lpOD::Element::DESTROY;
}

###############################################################

=head1 Transparent Unicode Support

By default ODF::lpOD_Helper patches ODF::lpOD so that all methods
accept and return arbitrary Perl character strings.

You will B<always> want this unless
your application really, really needs to pass un-decoded octets
directly between file/network resources and ODF::lpOD without
looking at the data along the way. This can be disabled for
legacy applications.  Please see B<< L<ODF::lpOD_Helper::Unicode> >>.

Currently this patch has global effect but might someday become
scoped; to be safe put C<use ODF::lpOD_Helper> at the top of every file which
calls ODF::lpOD or ODF::lpOD_Helper methods.

Prior to version 6.000 transparent Unicode was not enabled by default,
but required a now-deprecated ':chars' import tag.

=head1 METHODS

"Hxxx" methods are installed as methods of ODF::lpOD::Element
so they can be called the same way as native ODF::lpOD methods
('B<H>' denotes extensions from ODF::lpOD_B<H>elper).

=cut

# TODO: Can we make :bytes a pragmata which only affects it's scope?
#
#   ODF::lpOD::Common::input/output_conversion() methods would
#   need to use (caller(N))[10] to locate the user's %^H hash
#   to find out whether to decode/encode; "N" is not fixed, so
#   those methods would need to walk the stack to find the nearest
#   caller not inside ODF::lpOD::something.
#
#   If ODF::lpOD_Helper is someday merged into ODF::lpOD this would
#   be ugly but reasonably straightforward.
#
#   As a separate module ODF::lpOD_Helper might be able to patch
#   Perl's symbol table to replace those methods using
#      *ODF::lpOD::Common::input_conversion = &replacement;
#   however Perl caches method lookups, so if the user's program
#   managed to call ODF::lpOD methods before loading ODF::lpOD_Helper
#   then the overrides might not be effective.  It's better to not
#   go down that rabbit hole!

sub ODF::lpOD::Common::Huse_character_strings() {
  $ODF::lpOD::Common::INPUT_CHARSET = undef;
  $ODF::lpOD::Common::OUTPUT_CHARSET = undef;
  # It would be nicer if lpod->set_input_charset(undef) worked...
}
sub ODF::lpOD::Common::Huse_octet_strings() {
  lpod->set_input_charset("UTF-8");
  lpod->set_output_charset("UTF-8");
}

require Exporter;
use parent 'Exporter';

my $prev_import_loc;
sub import {
  my $class = shift;

  my $import_loc;
  for (my $n=0; ;++$n) {
    my ($pkg, $file, $line) = caller($n);
    unless ($file =~ /\(eval \d+/) {
      $import_loc = "$file line $line";
      last
    }
  }

  my (@my_args, @exporter_args);
  foreach (@_) {
    if (/^:(chars|bytes)$/) { push @my_args, $_; }
    else                    { push @exporter_args, $_; }
  }
  my $bytes_mode;
  foreach (@my_args) {
    if (/:chars/) {
      $bytes_mode = 0;
      use warnings::register;
      warnings::warn Carp::longmess
           "ODF::lpOD_Helper character mode is now the default",
           " and the ':chars' import tag is deprecated\n"
        #if warnings::enabled('deprecated');
        if warnings::enabled("deprecated");
    }
    elsif (/:bytes/) {
      $bytes_mode = 1;
    }
    else { die "bug" }
  }
  if ($bytes_mode) {
    # octet mode is the default for ODF::lpOD
    if (!defined($ODF::lpOD::Common::INPUT_CHARSET)
         or !defined($ODF::lpOD::Common::OUTPUT_CHARSET)) {
      confess "ERROR: ODF::lpOD_Helper was imported specifying ':bytes' at $import_loc'\n",
              "but lpOD_Helper was previously loaded without :bytes at ",
              u($prev_import_loc),
              " (or lpOD's CHARSET variables were otherwise set to undef).\n",
              "Since :bytes is global (not scoped), this is is a conflict.\n";
    }
  } else {
    lpod->Huse_character_strings();
  }
  $prev_import_loc = $import_loc;

  __PACKAGE__->export_to_level(1, $class, @exporter_args);
}

#use constant lpod_helper => 'ODF::lpOD_Helper';

# alert is from ODF::lpod and shows backtrace if lpod->debug(TRUE) was called
#sub btw(@) {
#  local $_=join("",@_); s/\n\z//s; alert('#'.(caller(0))[2].": $_"); }

sub oops(@) { @_=("\n".__PACKAGE__." oops:\n",@_,"\n"); goto &Carp::confess }
sub btwN($@) { my $N=shift; local $_=join("",@_); s/\n\z//s; printf "H%d: %s\n",(caller($N))[2],$_; }
sub btw(@) { unshift @_,0; goto &btwN }

use Scalar::Util qw/refaddr blessed reftype weaken isweak/;
use List::Util qw/min max first any all none reduce max sum0/;

# State information for generating & reusing styles is maintained per-document.
# A weakened ref to the doc object is saved; it will become undef automatically
# when the doc object is DESTROYed; this is how we know to forget previous
# state if the same memory address has been reused for a new Document object.
#
our %perdoc_state;  # "address" => [ { statehash }, $doc_weakened ]
sub _get_ephemeral_statehash($) {
  my $doc = shift;
  confess "not a Document" unless ref($doc) eq "ODF::lpOD::Document";

  my $result;
  foreach my $addr (keys %perdoc_state) {
    my ($statehash, $that_doc) = @{ $perdoc_state{$addr} };
    if (!defined $that_doc) { # that doc was destroyed
      delete $perdoc_state{$addr};
    }
    elsif ($that_doc == $doc) {
      $result = $statehash;
    }
  }
  unless ($result) {
    $perdoc_state{refaddr $doc} = my $aref = [ {}, $doc ];
    $result = $aref->[0];
    weaken($aref->[1]);
  }
  $result
}
use constant AUTO_PFX => "lpODH";

sub fmt_node(_;@); # forward
sub fmt_node_brief(_;@);
sub fmt_tree(_;@);
sub fmt_match(_;@);
sub _abbrev_addrvis($);
sub self_or_parent($$);
sub hashtostring($);

sub __is_textonly_prop(_) {
  local $_ = shift;
  state $TextStyleATTRValues
    = {map{$_ => undef} values %ODF::lpOD::TextStyle::ATTR};
  exists($ODF::lpOD::TextStyle::ATTR{$_})
  || exists($TextStyleATTRValues->{$_})
  || /^fo:(?!keep-together)/  # What are all possible fo:... ?
}

sub __is_paraonly_prop(_) {
  local $_ = shift;
  state $ParagraphStyleATTRValues
    = {map{$_ => undef} values %ODF::lpOD::ParagraphStyle::ATTR};
  exists($ODF::lpOD::ParagraphStyle::ATTR{$_})
  || exists($ParagraphStyleATTRValues->{$_})
  || /^(?:style[- ])?(?:tab|register)/
  # I wish I recorded how I came up with all these
  || /^(?:text[- ])?
       (?:align|align-last|indent|widows|orphans|together
                              |margin|margin[-\ _](?:left|right|top|bottom)
                              |border|border[-\ _](?:left|right|top|bottom)
                              |padding|padding[-\ _](?:left|right|top|bottom)
                              |shadow|keep[-\ _]with[-\ _]next
                              |break[-\ _](?:before|after)
                           )$/x;
}

## my $textorpara_prop_re = qr/(?:name|parent|clone)$/;

# Again, I wish I recorded where I found all these..
sub __is_table_prop(_) {
  local $_ = shift;
  /^(?:width|together|keep.with.next|display
                           |margin|margin[-\ _](?:left|right|top|bottom)
                           |break|break[-\ _](?:before|after)
                           |fo:.*     # assume it's ok if retrieved
                           |style:.*  # assume it's ok if retrieved
                           |table.*   # assume it's ok if retrieved
                        )$/x;
}

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
    "underlined"  =>  ["underline style" => "solid",
                       "underline width" => "normal",
                       "underline mode" => "continuous"],
    "hidden"      =>  [display => "none"],
  };
  my $input = shift;
  my $output = [];
  for(my $i=0; $i <= $#$input; ++$i) {
    local $_ = $input->[$i];
    if (my $pair=$abbr_props->{$_}) { push @$output, @$pair; }
    # N.B. percentage only allowed in common styles, relative to parent style!
    elsif (/^(\d[\.\d]*)(pt|%)$/)   { push @$output, "size" => $_; }
    elsif (/^\d[\.\d]*$/)           { push @$output, "size" => "${_}pt"; }
    elsif ($i < $#$input)           { push @$output, $_, $input->[++$i]; }
    else                            { oops(ivis 'Unrecognized abbrev prop $_ (input=$input ix=$i)') }
  }
  return $output;
}

# Get virtual text from a single node, expanding tab/newline/space
# objects to the corresponding character(s).  This *does* encode results
# into octets if ODF::lpOD has OUTPUT_CHARSET set (i.e. in :bytes mode);
# this is necessary so Hsearch can match octets in :bytes mode.
sub __leaf2vtext($) {
  my $node = shift;

  # Derived from ODF::lpOD::TextElement::get_text
  my $text;
  oops($node) unless blessed($node);
  my $tag = $node->get_tag;
  if ($tag eq '#PCDATA')
          {
          return $node->get_text(); # encoded while in :bytes mode
          }
  elsif ($tag eq 'text:s')
          {
          $text = "";
          my $c = $node->get_attribute('c') // 1;
          $text .= " " while $c-- > 0;
          }
  elsif ($tag eq 'text:line-break')
          {
          $text = $ODF::lpOD::Common::LINE_BREAK;
          }
  elsif ($tag eq 'text:tab')
          {
          $text = $ODF::lpOD::Common::TAB_STOP;
          }
  else    {
          confess "not a leaf: $tag";
          }
  ODF::lpOD::Common::output_conversion( $text );
}

###############################################################

=head2 @matches = $context->Hsearch($expr)

=head2 $match = $context->Hsearch($expr, OPTIONS)

Finds C<$expr> within the "virtual text" of paragraphs
below C<$context> (or C<$context> itself if it is a paragraph
or leaf node).

=over

B<Virtual Text>

This refers to logically-consecutive characters irrespective of how
they are stored.  They may be arbitrarily segmented, may use the special ODF
nodes for tab, newline, and consecutive spaces, and may be partly located in
different I<span>s.

By default all Paragraphs are searched, including nested paragraphs
inside B<frames> and B<tables>.
Nested paragraphs may be excluded using
option C<prune_cond =E<gt> 'text:p|text:h'>.

=back

Each match must be contained within a paragraph,
but may include any number of segments and
need not start or end on segment boundaries.

A match may encompass leaves under different I<span>s, i.e.
matching pays no attention to style boundaries.

B<$expr> may be a plain string or I<qr/regex/s>.  \n matches a line-break.
Space, tab and \n in C<$expr> match the corresponding special ODF objects
as well as regular PCDATA text.

OPTIONS may be

  offset => NUMBER  # Starting position within the combined virtual
                    # texts of all paragraphs in $context

  multi  => BOOL    # Allow multiple matches? (FALSE by default)

  prune_cond => STRING or qr/Regex/
                    # Do not descend below nodes matching the indicated
                    # condition.  See "Hnext_elt".

A match hashref is returned for each match:

 {
   match        => The matched virtual text
   segments     => [ *leaf* nodes containing the matched text ]
   offset       => Offset of match in the first segment's virtual text
   end          => Offset+1 of end of match in the last segment's v.t.

   para         => The paragraph containing the match
   para_voffset => Offset of match within the paragraph's virtual text

   voffset      => Offset of match in the combined virtual texts in $context
   vend         => Offset+1 of match-end in the combined virtual texts
 }

The following illustrates how the 'offset' OPTION works:

          Para.#1 ║ Paragraph #2 containing a match  │
          (ignored║  straddling the last two segments│
           due to ║                                  │
           offset)║                                  │
          ------------match voffset---►┊             │
          --------match vend---------------------►┊  │
                  ║                    ┊          ┊  │
                  ║              match ┊   match  ┊  │
                  ║             ║-off-►┊ ║--end--►┊  │
          ╓──╥────╥──╥────╥─────╥──────┬─╥────────┬──╖
          ║xx║xxxx║xx║xxxx║xx...║......**║*MATCH**...║
          ║xx║xxxx║xx║xxxx║xxSEA║RCHED VI║IRTUAL TEXT║
          ╙──╨────╨──╨────╨──┼──╨────────╨───────────╜
          ┊─OPTION 'offset'─►┊

Note: C<text:tab> and C<text:line-break> nodes count as one virtual character
and C<text:s> represents any number of consecutive spaces.
If the last segment is a C<text:s> then 'end' will be the number of
spaces included in the match.

RETURNS:

=over

In array context, zero or more match hashrefs.

In scalar context, a hashref or undef if there was no match
(option 'multi' is not allowed when called in scalar context).

=back

=head2 B<Regex Anchoring>

If C<$expr> is a qr/regex/ it is matched against the combined
virtual text of each paragraph.  The match logic is

   $paragraph_text =~ /\G.*?(${your_regex})/

with B<pos> set to the position implied by B<$offset>, if relevant,
or to the position following a previous match (when C<multi =E<gt> TRUE>).

Therefore B<\A> will match the start of the paragraph only on the first
match (when B<pos> is zero), provided B<$offset> is not specified or
points at or before the start of the current paragraph.

B<\z> always matches the end of the current paragraph.

=cut

sub ODF::lpOD::Element::Hsearch {
  my $context = shift;
  my $expr    = shift;
  my %opts    = @_;

  croak "Hsearch called in void context, result would be discarded"
    unless defined wantarray;
  croak "Hsearch called in scalar context but 'multi' is true"
    if $opts{multi} && !wantarray;

  my @matches;
  $context->Hreplace($expr,
                     sub{ push @matches, $_[0];
                          #btw "## callback: m=$_[0]" if $opts{debug};
                          $opts{multi} ? 0 : Hr_STOP
                        },
                     %opts, multi => undef);
  btw dvis '## Hsearch final @matches' if $opts{debug};
  return @matches
    if wantarray;
  # scalar context
  #croak "Hsearch called in scalar context\nbut  '$expr' matched ",scalar(@matches)," times\n" if @matches > 1;
  return @matches ? $matches[0] : undef;
}#Hsearch

=head2 $context->Hreplace($expr, [content], multi => bool, OPTIONS)

=head2 $context->Hreplace($expr, sub{...},  OPTIONS)

Like C<Hsearch> but replaces or calls a callback for each match.

C<$expr> is a string or qr/regex/s as with C<Hsearch>.

In the first form, the first matched substring
in the virtual text is replaced with B<[content]>;
with C<multi =E<gt> TRUE>, all instances are replaced.

In the second form, the specified sub is called for each match, passing
a I<match hashref> (see C<Hsearch>) as the only argument.  Its return
value determines whether any substitutions occur.
The sub must

 return(0)

    No substitution is done; searching continues.

 return(Hr_SUBST, [content])

    [content] is substituted for the matched text and searching continues,
    starting immediately after the replaced text.

 return(Hr_SUBST | Hr_STOP, [content])

    [content] is substituted for the matched text and then "Hreplace"
    terminates immediately.

 return(Hr_STOP)

    "Hreplace" just terminates.

C<Hreplace> returns a list of zero or more hashes describing the
substitutions which were performed:

  {
    voffset      => offset into the total virtual text of $context of the
                    the replacement (depends on preceding replacements)

    vlength      => length of the replacement content's virtual text

    para         => The paragraph where the match/replacement occurred

    para_voffset => offset into the paragraph's virtual text
  }

Note: The node following replaced text might be merged out of existence.

=head3 B<[content] Specifications>

A C<[content]> value is a ref to an array of zero or more elements,
each of which is either

=over 2

=item * A string which may include spaces, tabs and newlines, or

=item * A reference [list of format properties]

=back

Each [list of format properties] describes a I<character style>
which will be applied only to the immediately-following text string.

Format properties may be any of the S<< key => value pairs >> accepted
by C<odf_create_style>, as well as these single-item abbreviations:

  "center"      means  align => "center"
  "left"        means  align => "left"
  "right"       means  align => "right"
  "bold"        means  weight => "bold"
  "italic"      means  style => "italic"
  "oblique"     means  style => "oblique"
  "normal"      means  style => "normal", weight => "normal"
  "roman"       means  style => "normal"
  "small-caps"  means  variant => "small-caps"
  "normal-caps" means  variant => "normal", #??

  <NUM>         means  size => "<NUM>pt",   # bare number means point size
  "<NUM>pt"     means  size => "<NUM>pt",

Internally, an ODF "automatic" Style is created for
each unique combination of properties, re-using styles when possible.
Fonts are automatically registered.

To use an existing (or to-be-explicitly-created) ODF Style, use

  [style_name => "name of style"]

Additionally, a text segment may be made into a hyperlink with these
pseudo-properties, which must appear before any others:

  hyperlink       => "https://..."
  visited_style   => "stylename"     # optional
  unvisited_style => "stylename"     # optional

Regular format properties may follow (or not).

=cut

# Compose multiple XML::Twig search conditions to match any of them ("OR")
sub Hor_cond(@) {
  my @regexes;
  my @coderefs;
  my $str = "";
  foreach (@_) {
    return undef if !defined; # undef means match anything
    if    (ref eq 'CODE')   { push @coderefs, $_; }
    elsif (ref eq "Regexp") { push @regexes, $_;  }
    elsif (ref)             { croak "Unhandled ref type ",ref; }
    else                    { $str .= "|" if $str; $str .= $_; }
  }
  # Convert simple regexes into equivalent string conditions.
  # Benchmark shows that 'text:h|text:p' is 30% faster than qr/^text:[hp]$/
  foreach (@regexes) {
    if (/^ \(\?\^u?:\^ ( [:\w]+ ) \$\) $/x # ^ONESTRING$
        ||
        /^ \(\?\^u?:\^ \((?:\?:)? ( [:\w]+ (?: \| [:\w]+)* ) \) \$\) $/x # ^(A|B)$
       ) {
      $str .= "|" if $str; $str .= $1; $_ = undef;
    }
    elsif (/^ \(\?\^u?:\^ ([:\w]+) \[ ([\w]+) \] \$\) $/x) {
      # (?^u:^string[charset]$) e.g. qr/^text:[hs]$/
      my ($lhs, $rhs_chars) = ($1, $2);
      foreach (split //,$rhs_chars) {
        $str .= "|" if $str; $str .= $lhs.$_;
      }
      $_ = undef;
    }
  }
  @regexes = grep{defined} @regexes;
  if (@regexes) {
    if ($str) { push @regexes, qr/^(?:${str})$/; $str = ""; }
    if (@regexes > 1) {
      my $restr = join("|", map{ "(?:".$_.")" } @regexes);
      eval{ @regexes = (qr/$restr/) };  oops "$restr\n$@" if $@;
    }
  }
  if (@coderefs) {
    push @coderefs, sub{ $_[0] =~ qr/$regexes[0]/ } if @regexes;
    push @coderefs, sub{ $_[0]->passes($str) } if $str;
    return $coderefs[0] if @coderefs == 1;
    my $codestr =
      "sub{ ".join(" || ", map{ "&{\$coderefs[$_]}" } 0..$#coderefs)." }";
    my $code = eval $codestr || oops "$codestr\n$@";
    return $code;
  }
  return $regexes[0] if @regexes;
  return $str if $str;
  oops avis(@_);
}#Hor_cond

use constant ROW_FILTER              => ODF::lpOD::Matrix::ROW_FILTER;    # 'table:table-row'
use constant COLUMN_FILTER           => ODF::lpOD::Matrix::COLUMN_FILTER; # 'table:table-column'
use constant CELL_FILTER             => ODF::lpOD::Matrix::CELL_FILTER;   # qr'table:(covered-|)table-cell'
use constant TABLE_FILTER            => ODF::lpOD::Matrix::TABLE_FILTER;  # 'table:table'

use constant TEXTLEAF_FILTER         => '#TEXT|text:tab|text:line-break|text:s';
use constant PARA_FILTER             => 'text:p|text:h';
use constant FRAME_FILTER            => 'draw:frame';
use constant SPAN_FILTER             => 'text:span';
use constant TEXTCONTAINER_FILTER    => Hor_cond(PARA_FILTER, SPAN_FILTER);
use constant TEXTLEAF_OR_PARA_FILTER => Hor_cond(TEXTLEAF_FILTER, PARA_FILTER);

# These used to be lexical subs inside Hreplace, but a Perl bug prevented
# reentrant searches via callbacks.   The stuff in the $state hash
# used to be lexicals in Hreplace.  https://github.com/Perl/perl5/issues/18606
  sub _get_seginfo($$) {
    my ($state, $node) = @_;
    my @seginfo;
    my $vtext = "";
    # Do not descend into nested paragraphs, which are visited in outer loop
    for my $e ($node->Hdescendants_or_self(TEXTLEAF_FILTER, PARA_FILTER)) {
      my $etext = __leaf2vtext($e);
      my $textlen = length($etext);
      push @seginfo, {
        elt    => $e,
        seglen => $textlen,
        vtoff  => length($vtext),
        voff   => $state->{totlen},
      };
      $vtext .= $etext;
      $state->{totlen} += $textlen;
    }
    ($vtext, \@seginfo)
  }

  sub _first_match($$$$) {
    my ($state, $vtext, $seginfo, $node) = @_;
    oops unless @$seginfo; # truly empty paragraphs are not searched
    my ($debug, $expr) = @$state{qw/debug expr/};

    if ($state->{offset} >= $state->{totlen}) {
      btw dvis '  Hr SKIP WHOLE PARA $state->{totlen} $state->{offset}' if $debug;
      return ()
    }

    my $vtext_pos =
         $state->{offset} > $state->{para_start_offset} ? ($state->{offset} - $state->{para_start_offset}) : 0;

    oops(dvis '$vtext_pos $state->{para_start_offset} $state->{totlen} $vtext') if $vtext_pos < 0 or $vtext_pos > $state->{totlen};

    my ($vtoffset, $vtend);
    if (ref $expr) { # Regexp
      pos($vtext) = $vtext_pos;
      if ($vtext =~ /\G.*?(${expr})/s) {
        $vtoffset = $-[1];
        $vtend    = $+[1];
      }
    } else {
      if ((my $off = index($vtext, $expr, $vtext_pos)) >= 0) {
        $vtoffset = $off;
        $vtend    = $vtoffset + length($expr);
      }
    }
    if (defined $vtoffset) {

      # Find the first and last segments containing the match.
      # Empty segments at the boundaries are not included in the match
      # unless the match was zero length.
      my $fix = first{
                  $$seginfo[$_]{vtoff} + $$seginfo[$_]{seglen} > $vtoffset
                  || ($vtend==$vtoffset && $$seginfo[$_]{seglen} == 0)
                     } 0..$#$seginfo;
      oops dvis('$fix @$seginfo\n $vtend $vtoffset')
        unless defined($fix) && $$seginfo[$fix]->{vtoff} <= $vtoffset;

      my $lix = first{
                  $$seginfo[$_]{vtoff} + $$seginfo[$_]{seglen} >= $vtend
                     } $fix..$#$seginfo;
      oops(dvis('$expr $fix $lix $vtoffset $vtend seginfo:\n  ')
           .join("\n  ",map{ "vtoff=$_->{vtoff} seglen=$_->{seglen} elt:"
                             .fmt_node($_->{elt}, parent => $_->{elt}->parent)
                           } @$seginfo)
           #.join("\n  ",map{ fmt_node($$seginfo[$_]) } 0..$#$seginfo)
          )
        unless defined($lix) && $$seginfo[$lix]->{vtoff} <= $vtend
        && defined($fix) && $fix <= $lix;

      my $m = {
        match      => substr($vtext, $vtoffset, $vtend-$vtoffset),
        segments   => [ map{$_->{elt}} @$seginfo[$fix..$lix] ],
        offset     => $vtoffset - $$seginfo[$fix]->{vtoff},
        end        => $vtend    - $$seginfo[$lix]->{vtoff},
        voffset    => $state->{para_start_offset} + $vtoffset,
        vend       => $state->{para_start_offset} + $vtend,
        para       => ($node->isa("ODF::lpOD::Paragraph")
                         ? $node : $node->get_parent_paragraph),
        para_voffset => $vtoffset,
      };
      btw rdvis('  Hr MATCH $fix $lix $state->{offset} $state->{para_start_offset} $state->{totlen} $vtext_pos $vtoffset $vtend $node\n'),fmt_match($m) if $debug;
      return ($m, $state->{callback}->($m));
    }
    btw '_first_match NO MATCH, returning ()' if $debug;
    return ()
  }# _first_match

  sub _process_para($$) { # also called if context is a text leaf
    # returns 0 to continue, Hr_STOP to stop
    my ($state, $node) = @_; # paragraph or total $context if a textual leaf
    my ($debug) = @$state{qw/debug/};

    oops "seen_paras ",fmt_node($node) if $state->{seen_paras}{$node}++;

    my $para_startcount = scalar @{$state->{subst_results}};
    PARA: {
      btw "Hr PARA ",_abbrev_addrvis($node),dvis(' Top $state->{totlen}')
        if $debug;

      $state->{para_start_offset} = $state->{totlen};
      my ($vtext, $seginfo) = _get_seginfo($state, $node);

      if (@$seginfo == 0) {
        btw "Hr _no leaves_ " if $debug;
        return(0);
      }

      MATCH: {
        my ($m, $r, @args) = _first_match($state, $vtext, $seginfo, $node);

        if (defined $m) {
oops unless @{$m->{segments}};
          if ($r & Hr_SUBST) {
            croak ivis 'Extraneous return values from callback @args'
              if @args > 1;
            my $content = shift @args // confess "No [content] after Hr_SUBST";
            my $new_vlength = Hreplace_match($m, $content, debug => $debug);

            push @{$state->{subst_results}}, {
              #(excessive/unneeded?) match        => $m->{match},
              voffset      => $m->{voffset},
              vlength      => $new_vlength,
              para         => $m->{para},
              para_voffset => $m->{para_voffset},
            } ;#if defined wantarray in Hreplace();

            # Re-process the whole paragraph with $offset set appropriately.
            $state->{offset} = $m->{voffset}; # start of match
            if ($r & Hr_RESCAN) {
              croak "100 RESCANs in same paragraph" if ++$state->{rescan_count} > 100;
            } else {
              $state->{offset} += $new_vlength; # length of replacement
            }
            unless ($r & Hr_STOP) {
              btw dvis '  Hr redo PARA after substitution $state->{offset} $m->{voffset} $new_vlength' if $debug;
              if ($m->{match} eq "" && $new_vlength==0) {
                # Avoid infinite loop
                btw dvis '  Hr NULL MATCH & REPL: offset++' if $debug;
                $state->{offset}++;
              }
              $state->{totlen} -= length($vtext);
              redo PARA;
            }
          } else {
            croak ivis 'Extraneous return values from callback @args'
              if @args > 0;
            if ($m->{match} eq "") {
              # Avoid infinite loop
              btw dvis '  Hr NULL MATCH: offset++' if $debug;
              $state->{offset}++;
            } else {
              $state->{offset} = $m->{vend}; # just past end of match
            }
          }
          if ($r & Hr_STOP) {
            $node->Hnormalize() if $para_startcount != scalar @{$state->{subst_results}};
            return(Hr_STOP)
          }
          if ($state->{offset} < $state->{totlen}) {
            btw dvis '  Hr CONTINUE: new $state->{offset}, *redo MATCH*' if $debug;
            redo MATCH;
          }
        } else {
          btw '  Hr [no match] expr=',vis($state->{expr}),dvis '\n $state $vtext' if $debug;
        }
      }#MATCH
    }#PARA
    $node->Hnormalize() if $para_startcount != scalar @{$state->{subst_results}};
    return (0);
  }#_process_para()

our $recursion_level = 0;

sub ODF::lpOD::Element::Hreplace {
  my $context = shift;
  my $expr    = shift;
  my $repl    = shift;
  my %opts    = @_;
  my $debug   = $opts{debug};

  # We can not allow reentrant substitutions (i.e. via callbacks) in the
  # same paragraph because saved segment data might be invalidated
  # and crash _first_match().  However recursive search-only calls are ok,
  # such as via Hsearch.  N.B We don't know whether a substitution will occur
  # until control returns from a callback.
  #
  # Attempted modifications throw an exception if $recursion_level > 1
  # i.e. only the outer-most level is allowed to change anything.
  # This is checked in Hreplace_match (in case we ever make that public)
  local $recursion_level = $recursion_level + 1;

  btw dvis 'Hreplace Top: $context $expr $repl %opts' if $debug;

  croak "'expr'  must be a qr/regex/ or plain string\n"
    if (!defined($expr) or ref($expr) && ref($expr) ne "Regexp");

  my $callback;
  if (ref($repl) eq "CODE") {
    croak "Option 'multi' and using a callback are mutually exclusive\n"
      if defined  $opts{multi};
    $callback = $repl;
  }
  elsif (ref($repl) eq "ARRAY") {
    $callback = $opts{multi} ? sub{ (Hr_SUBST        , $repl) }
                             : sub{ (Hr_SUBST|Hr_STOP, $repl) } ;
  }
  else {
    croak "Replacement argument must be [content] aref or callback subref",
          " (not '$repl')";
  }

  #  $vtext holds the entire virtual text from the *current* paragraph
  #  even if option 'offset' points past the beginning of the paragraph.
  #  The match {offset} is the offset into the first matching segment.
  #
  #         ║                                   ║ ║
  #  Para(s)║           Paragraph 'x'           ║ ║   later Paragraph 'N'
  #   before║                                   ║ ║
  # ------------------voffset---►┊              ║ ║
  # --------------vend----------------------►┊  ║ ║
  #         ║                    ┊           ┊  ║ ║
  #         ║              match ┊    match  ┊  ║ ║ match           ║match
  #         ║             ║-off-►┊ ║--end---►┊  ║ ║offset-►┊        ║end►┊
  # ╓──╥────╥──╥────╥─────╥──────┬─╥─────────┴──╖ ╓────────┬──╥─────╥────┴──╖
  # ║XX║XXXX║XX║XXXX║XX   ║      MA║TCHED TXT┊  ║ ║        MAT║CHED ║TEXT┊  ║
  # ║XX║XXXX║XX║XXXX║XXsea║rched te║xt..........║ ║searched te║xt...║.......║
  # ╙──╨────╨──╨────╨──┴──╨────────╨────────────╜ ╙───────────╨─────╨───────╜
  # ┊─OPTION 'offset'─►┊         ┊           ┊  ║ ║                         ║
  #         ║~~~~~~~~($vtext for para x)~~~~~~~~║ ║~~~($vtext for para N)~~~║
  #         ║                    ┊           ┊  ║ ║                         ║
  #         ║◄──────$vtoff──────►┊           ┊  ║ ║                         ║
  #         ║◄────────────$vtend────────────►┊  ║ ║                         ║
  #                                             ║                           ║
  #  ──────────$totlen (@end of para x)────────►║                           ║
  #  ------------------------------------------$totlen (@end of para N)----►║

  my $state = {
    offset            => $opts{offset} // 0,
    totlen            => 0,
    para_start_offset => undef,
    subst_results     => [],
    seen_paras        => {},
    rescan_count      => undef,
    debug             => $debug,
    expr              => $expr,
    callback          => $callback,
  };

  ### MAIN BODY OF Hreplace ###

  my $stop;
  # If $context itself is a paragraph or a leaf segment, process it first
  if ($context->passes(TEXTLEAF_OR_PARA_FILTER)) {
    $stop = _process_para($state, $context); # ignores nested paras
  }
  # Now process paragraphs which are descendants.
  # _process_para will not descend into nested paragraphs, i.e. it only
  # looks at the text at that level; nested paragraphs are visited directly
  # here (after the parent paragraph was visited).
  { my $para = $context ;
    while ($para = $para->Hnext_elt($context, PARA_FILTER, $opts{prune_cond})) {
      $stop = _process_para($state, $para);
      last if $stop & Hr_STOP;
    }
  }

  if ($stop & Hr_STOP) {
    btw dvis 'Hreplace STOP.' if $debug;
  }

  btw ivis 'Hreplace RETURNING @{$$state{subst_results}}' if $debug;
  return @{$$state{subst_results}};
}#Hreplace

###sub _nonempty_content($) { any{! ref($_) && length($_) != 0} @{shift @_} }

# Replace matched virtual text with new content.
#
# RETURNS: The virtual length of the replacement content
#
# Any sibilings after the I<match segments> MAY BE DELETED if merged with the
# end of the replacement content.
#
# Currently, siblings before the I<match segments> will remain untouched
# even if they could be merged with the first match segment.
#
# This is currently an undocumented internal function which may change.

=for Pod::Coverage Hreplace_match

=cut

sub Hreplace_match($$@) { # *FUNCTION*
  my %match = %{ shift @_ };  #copy
  my $content = shift;
  my %opts    = @_;
  my $debug = $opts{debug};
  btw 'Hrep_m match=',fmt_match(\%match),dvis '\n $content' if $debug;
oops unless @{ $match{segments} };

  croak "Recursive substitutions are not permitted to avoid confusing Hreplace\n" if $recursion_level > 1;

  # INITIALLY:
  #     $m->{segments}[0]     ...       $m->{...}[-1]
  #     ┌────────────┐    ┌──────────┐  ┌────────────┐ ┌───┐
  #     │  A  ┊MMMMMM│    │MMMMMMMMMM│  │MMMMMM┊  B  │ │(C)│
  #     └────────────┘    └──────────┘  └────────────┘ └───┘
  #     ┌────────────────┐ ┌───┐
  # OR  │  A  ┊MMMM┊  B  │ │(C)│  (single-segment case)
  #     └────────────────┘ └───┘
  my $did_splits;
  if ($match{offset}) {
    # Split off the before-residue ("A"), moving "MMM..." to a new segment
    # which becomes the new segment 0.
    my $rhs = $match{segments}[0]->Hsplit_element_at($match{offset});
    btw dvis 'Hrep_m : Split off pre-residue before $match{offset}, rhs=$rhs'
      if $debug;
    if (@{$match{segments}}==1) {
      $match{end} -= $match{offset};  oops if $match{end} < 0;
    }
    $match{offset} = 0;
    $match{segments}[0] = $rhs;

    $did_splits = 1;
  }
  if ($match{end} < length($match{segments}[-1]->Hget_text//"")) {
    # Split off the after-residue ("B"), moving it to a new segment
    () = $match{segments}[-1]->Hsplit_element_at($match{end});
    btw dvis 'Hrep_m post-residue at $match{end} has been split off' if $debug;
    $did_splits = 1;
  }
  if ($debug && $did_splits) {
    btw "Hrep_m After Split(s) para=",fmt_tree($match{para},wi=>1),
        " next_sib=", fmt_node($match{segments}[-1]->{next_sibling},wi=>1);
  }
  # ┌───┐ ┌───────────────┐ ┌──────┐ ┌───────────┐ ┌───┐
  # │ A │ │MMMMMMMMMMMMMMM│ │MMMMMM│ │MMMMMMMMMMM│ │ B │
  # └───┘ └───────────────┘ └──────┘ └───────────┘ └───┘

  # To facilitate cutting the match data ("MMM") without allowing merging,
  # put the new content into a temporary paragraph and insert the para
  # immediately after the last old segment
  state $temp_para = odf_create_paragraph;
  $temp_para->paste_after( $match{segments}[-1] );
  my $vlength = $temp_para->Hinsert_content($content,
                                            debug=>$debug, _nocleanup => TRUE
                                           )->{vlength};
  # ┌───┐ ┌───────────────┐ ┌──────┐ ┌───────────┐ ┌─────────┐ ┌───┐
  # │ A │ │M1MMMMMMMMMMMMM│ │M2MMMM│ │M3MMMMMMMMM│ │temp_para│ │ B │
  # └───┘ └───────────────┘ └──────┘ └───────────┘ └─────────┘ └───┘

  # Delete all but the first old segment in right-to-left order; then, if
  # the temp para isn't already the next sibling of M1, move it there
  # (this occurs when M1 is in a span; we want the substituted result
  # to always get whatever formatting the first character of the
  # replaced text had).
  my @nodes;
  my $seg_count = @{$match{segments}};
  for my $e (reverse @{$match{segments}}[1..$seg_count-1]) {
    my $p = $e->parent // oops;
    push @nodes, $p;  # in case it's now an empty span.
    $e->delete();
  }
  unless (($match{segments}[0]->next_sibling//0) == $temp_para) {
    btw "Hrep_m (moving temp_para into first seg's style)" if $debug;
    $temp_para->move(after=>$match{segments}[0]);
  }
  # Now delete the remaining (0th) old segment
  $match{segments}[0]->delete;

  # No need to normalize here because Hreplace will do an overall normalize
  #$temp_para->Hnormalize();

  # Move the new content out of the temp_para and cut the para
  oops unless length($temp_para->Hget_text//"") == $vlength;
  for my $e ($temp_para->cut_children()) {
    $e->paste_before($temp_para);
    push @nodes, $e;
  }
  # *merging* can occur between the last new segment and what follows ('B')
  $temp_para->cut;

  _cleanup_spans(\@nodes, %opts);
  return $vlength
}#Hreplace_match

# =head2 ($node, $offset_within) = $container->Hoffset_into_vtext($offset, $prune_cond)
#
# Locate the position given by B<$offset> within the virtual text
# of a container, returning the specific leaf node containing the indicated
# character and the offset within that node of the character.
#
# If $offset exactly equals the length of the virtual text, then
# undef is returned in $offset_with; in that case $node will be
# the last textual leaf or undef if there are no text leaves in $context.
#
# Croaks if $offset is greater than the length of the virtual text.
#
# "Virtual text" means characters irrespective of how they are stored,
# which may be arbitrarily segmented, may use PCDATA and/or the special
# ODF nodes used for tab, newline, and consecutive spaces, and may
# be located under nested containers (spans, etc.)
#
# If B<$offset> points to a space stored in a I<text:s> node
# (which can represent multiple consecutive spaces), then the returned
# B<$offset_within> is the number of spaces "used" within that node.
#
# For other types of nodes $offset_within has the obvious meaning
# (0 if $node is a tab or newline object, which represent a single character).
#
# C<$prune_cond> allows ignoring text inside frames or other nested objects
# (see C<Hdescendants>).  If absent or undef then everything is collected.

# Currently Hoffset_in_vtext is not public and may change without notice.

=for Pod::Coverage Hoffset_into_vtext

=cut

sub ODF::lpOD::Element::Hoffset_into_vtext {
  my ($context, $offset, $prune_cond) = @_;
  confess ivis 'Invalid offset $offset' if ($offset//-1) < 0;
  my $remaining = $offset;
  my $elt = $context->passes(TEXTLEAF_FILTER)
              // $context->Hnext_elt($context, TEXTLEAF_FILTER, $prune_cond);
  my $last_leaf;
  while ($elt) {
    my $text = __leaf2vtext($elt);
    if ($remaining >= length($text)) {
      $remaining -= length($text);
      $last_leaf = $elt;
      $elt = $elt->Hnext_elt($context, TEXTLEAF_FILTER, $prune_cond);
      next
    }
    return ($elt, $remaining);
#    my $para = $elt->parent(PARA_FILTER);
#    my $poffset = 0;
#    my $ptxt = $para;
#    for(;;) {
#      $ptxt = $ptxt->Hnext_elt($para,TEXTLEAF_FILTER,$prune_cond) // oops;
#      last if $ptxt == $elt;
#      $poffset += length(__leaf2vtext($ptxt));
#    }
#    return ($elt, $remaining, $para, $poffset);
  }
  return ($last_leaf, undef) if $remaining==0;  # points just past the end
  confess "Offset $offset exceeds total virtual text length of ",
          fmt_node($context);
}

=head2 $node = $context->Hinsert_element($elem_to_insert, OPTIONS)

This is an enhanced version of C<ODF::lpOD::Element::insert_element()>.

=over 2


=item *

B<$context> may be any node, including a textual leaf,
a text container (paragraph, heading or span),
or an ancestor of a text container such as the document body or a frame.

If option B<position =E<gt> WITHIN> then B<offset> refers to the
combined I<Virtual Text> of $context; the appropriate textual leaf
is located and split if appropriate.

=over 2

If offset==0 then a PREV_SIBLING is inserted before the first existing
leaf if one exists (which may be $context itself, which
ODF::lpOD 1.015 does not handle correctly);
otherwise a FIRST_CHILD is inserted into $context
if it is a text container, otherwise the first descendant which is a
text container (which must exist).

If offset > 0 and equals the total existing virtual length then
a NEXT_SIBLING is inserted after the last existing leaf.

=back

If B<position =E<gt> NEXT_SIBLING> or B<PREV_SIBLING>
then $context must be a textual leaf or a span.

If B<position =E<gt> FIRST_CHILD> or B<LAST_CHILD>
then $context must be a text container.

In all cases, no segment merging occurs.

=item *

The special ODF textual nodes (text:s, text:tab, text:line-break)
are handled and the characters they imply are counted by B<$offset>
when inserting WITHIN $context.   If a text:s node representing multiple
spaces must be split then another text:s node is created
to "contain" the spaces to the right of B<$offset>.

=item *

Option C<prune_cond =E<gt> ...> may be used to ignore text
in nested paragraphs, frames, etc. when counting 'offset'
with C<position =E<gt> WITHIN> (see C<Hnext_elt>).

=back

=cut

sub ODF::lpOD::Element::Hinsert_element {
  my $context = shift;
  my $to_insert   = shift;
  my %opts    = (position => 'FIRST_CHILD', @_);

  my $position = uc( $opts{position} // "" );
  if ($position ne 'WITHIN' || $opts{before} || $opts{after}) {
    confess "context must be a leaf or span for position => $position"
      if $position =~ /^(NEXT|PREV)/
           && !$context->His_textual() && $context->tag() ne "text:span";
    confess "context must be a text conainer (paragraph, heading, or span)",
            " for position => $position"
      if $position =~ /^(FIRST|LAST)/ && !$context->His_text_container();
    # insert_element works ok in these cases
    return $context->insert_element($to_insert, %opts);
  }
  #
  # Re-implement position => WITHIN
  #
  my $offset = $opts{offset} // 0;
  my ($elt, $offset_within)
                    = $context->Hoffset_into_vtext($offset, $opts{prune_cond});

  btw "Hinsert_element c=",_abbrev_addrvis($context)," elt=",_abbrev_addrvis($elt),dvis ' $offset $offset_within' if $opts{debug};

  if (! defined $offset_within) {
    # offset points just beyond the end of the (possibly empty) vtext
    if (defined $elt) { # the last existing textual leaf
      oops if $offset==0;
      return $elt->insert_element($to_insert, position => NEXT_SIBLING)
    }
    # There are _no_ textual leaves.  Insert as FIRST_CHILD of container
    oops unless $offset==0;
    oops if $context->passes(TEXTLEAF_FILTER);
    my $container = $context->passes(TEXTCONTAINER_FILTER)
                         ? $context : $context->next_elt(TEXTCONTAINER_FILTER);
    confess "context is not a/has no text container" unless $container;
    return $container->insert_element($to_insert, position => FIRST_CHILD)
  }
  () = $elt->Hsplit_element_at($offset_within); # splits PCDATA or text:s
  return $elt->insert_element($to_insert, position => NEXT_SIBLING);
}#Hinsert_element

# Scan some nodes for spans which are children of other spans,
# and hoist them up as many levels as necessary to eliminated nested spans
# (dividing the parent spans).  Empty spans are simply deleted.
sub _cleanup_spans($@) {
  my ($nodes, %opts) = @_;
  NODE:
  foreach my $lowerspan (@$nodes) {
#btw "##processing ",fmt_node($lowerspan);
    next unless $lowerspan->tag eq "text:span";
    if (! $lowerspan->first_child) {
      btw dvis '_cleanup_spans: Deleting empty $lowerspan' if $opts{debug};
      $lowerspan->delete;
      next
    }
    for(;;) {
      my $p = $lowerspan->parent;
      next NODE unless $p->tag eq "text:span";

      my $right_span = $p->clone;
      $_->delete() foreach ($right_span->cut_children); # kinda gross

      $right_span->paste_after($p);

      # Move items from left to right partition.  Cut lowerspan last to
      # prevent adjacents from merging.
      my $lowerspan_ix;
      { my $ix = 0;
        for my $child ($p->children) {
          if (defined $lowerspan_ix) { $child->move(last_child=>$right_span); }
          elsif ($child == $lowerspan) { $lowerspan_ix = $ix }
          # else leave child in left partition
          ++$ix
        }
        oops unless defined $lowerspan_ix;
      }
      $lowerspan->cut;
      $lowerspan->paste_after($p); # hoisted position

      if ($lowerspan_ix == 0) {
        $p->delete
      }

      if (! $right_span->first_child) {
        btw dvis '_cleanup_spans: DELETING EMPTY $right_span' if $opts{debug};
        $right_span->delete();
      }
      btw '_cleanup_spans: Hoisted ', fmt_node($lowerspan) if $opts{debug};
    }
  }
}

=head2 $context->Hinsert_content([content], OPTIONS)

This is similar to C<Hinsert_element()> except
that multiple segments may be inserted and they are described by
a high-level B<[content]> specification.

B<[content]> is the same as with C<Hreplace>.

If C<[content]> includes format specifications, the affected text
will be stored inside a I<span> using an "automatic" style.

If a new span would be nested under an existing span, the existing span
is partitioned and the new span hoisted up to the same level.

The first new node will be inserted at the indicated I<position>
relative to C<$context> and others will follow as siblings.

OPTIONS may contain:

  position => ...  # default is FIRST_CHILD.  Always relative to $context.
                   # See Hinsert_content herein and ODF::lpOD::Element.

  offset   => ...  # Used when position is 'WITHIN', and counts characters
                   # in the virtual text of $context

  prune_cond => qr/^text:[ph]$/
                   # (for example) ignore, i.e. skip over nested paragraphs

  chomp => BOOL    # remove \n, if present, from the end of content

Returns a hashref:

  {
    vlength => total virtual length of the new content
    # (currently no other public fields are defined)
  }

To facilitate further processing, pre-existing segments are never merged;
C<Hnormalize()> should later be called on $context or the nearest
ancestral container.

=cut

sub ODF::lpOD::Element::Hinsert_content {
  my $context = shift;
  my $what = shift;
  my %opts = (position => FIRST_CHILD, @_);
  my $debug = $opts{debug};

  my sub _show_context {
    my $msg = join("", @_);
    $msg .= "context="._abbrev_addrvis($context);
    my $item = $context;
    if ($opts{position} =~ /WITHIN|SIBLING|PARENT/) {
      my $p = $context->parent(qr/^text:[ph]$/);
      unless (defined($p)) {
        oops unless $context == $context->document->get_body;
      } else {
        $item = $p;
        $msg .= " (showing ancestor para)";
      }
    }
    $msg .= " :\n".fmt_tree($item);
    btwN 1,$msg;
  }

  # Hinsert_content might become a superset (i.e. drop-in replacement
  # for) ODF::lpOD::TextElement::insert_element by allowing $what to be
  # an element hashref or "tag name" instead of [content], calling
  # Hinsert_element in those cases.
  #
  # But for now, to avoid confusion between a "content string" argument
  # and "tag name", Hinsert_content only accepts an arrayref to a high-level
  # content specification.
  confess "[content] must be an array ref" unless ref($what) eq "ARRAY";

  my @content = @$what;

  _show_context(dvis '##Hi_c TOP %opts\n @content\n') if $debug;

  croak "option 'Chomp' was renamed 'chomp'" if exists $opts{Chomp};
  if ($opts{chomp} && @content) {
    chomp $content[-1];
    if ($content[-1] eq "") {
      pop @content;
      pop @content if ref($content[-1]);
    }
  }

  # ODF::lpOD::TextElement .pod warns that spans must not cover "breaking" text
  # such as tab, newline, multiple spaces.  However the ODF v1.2 spec seems to
  # allow text:{s,tab,line-break} inside a text:span, see
  # http://docs.oasis-open.org/office/v1.2/cs01/OpenDocument-v1.2-cs01-part1.html#element-text_s
  #
  # I'm assuming the above warning was mistaken, no longer applies w/ODF 1.2,
  # or described an ODF::lpOD limitation rather than a spec restriction.
  #
##  my $nonflat_found;
##  for (my $ix = 0; $ix <= $#content; ++$ix)
##    next unless ref(my $styledesc = $content[$ix]);
##    my $text = $content[$ix+1];
##    if ($text =~ /[\t\n]| {2,}/) {
##      my $nonflat = $&;
##      $nonflat_found = 1;
##      if ((my $offset = $-[0]) > 0) {
##        my $left = substr($text, 0, $offset, "");
##        splice(@content, $ix, 0, ($styledesc, $left);
##        $ix += 2;
##      }
##      if (length($nonflat) == length($text)) {
##        # The remaining string is un-spanable, so just drop the style
##        splice(@content, $ix, 1, ());
##        redo
##      }
##      my $right = substr($text, length($nonflat));
##      splice(@content, $ix, 2, ($nonflat, $styledesc, $right));
##    }
##  }
##  btw dvis '[content] modified to move non-flat chars out of styles:\n@content'
##    if $debug && $nonflat_found;

  my $doc = $context->get_document;

  # First insert all the content into an orphan paragraph container,
  # then move to the final position.  This lets us normalize the new content
  # and, because the orphan $container_para does not need to be cut,
  # no merging with the surroundings will occur.
  state $container_para = odf_create_paragraph;

  while (@content) {
    local $_ = shift @content;
    if (ref) {
      my $props = $_;
      my ($stylename, %hyperlink_params);
      # Sort of a hack: The hyperlink options must preceed all others!
      # (because we don't know what the single-item abbreviations are here)
      while (@$props) {
        if ($props->[0] eq "hyperlink") {
          $hyperlink_params{url} = (splice @$props, 0, 2)[1];
          next;
        }
        if ($props->[0] =~ /^visited([-_ ])style\g{-1}name$/) {
          $hyperlink_params{"visited style name"} = (splice @$props, 0, 2)[1];
          next;
        }
        if ($props->[0] =~ /^unvisited([-_ ])style\g{-1}name$/) {
          $hyperlink_params{"style name"} = (splice @$props, 0, 2)[1];
          next;
        }
        if ($props->[0] eq "title") {
          $hyperlink_params{"title"} = (splice @$props, 0, 2)[1];
          next;
        }
        if ($props->[0] eq "name") {
          $hyperlink_params{"name"} = (splice @$props, 0, 2)[1];
          next;
        }
        if ($props->[0] =~ /^style[-_ ]name$/) {
          $stylename = (splice @$props, 0, 2)[1];
          croak "Other properties not allowed with 'style-name'"
            if @$props;
        }
        last;
      }
      unless ($stylename) {
        my $ts = $doc->Hautomatic_style('text', @$props) // oops;
        $stylename = $ts->get_name;
      }
      my $vtext = shift(@content)
        // croak "[style spec] not followed by anything";
      if (ref($vtext)) { croak "[style spec] not followed by plain text" }

      my $span = $container_para->insert_element('text:span', position => LAST_CHILD);
      $span->set_attribute('style-name', $stylename);
      $span->ODF::lpOD::TextElement::set_text($vtext);
      if (%hyperlink_params) {
        my $url = delete $hyperlink_params{url} // croak "No hyperlink 'url'";
        # Example in ODF::lpOD::TextElement
        $span->set_hyperlink(filter => '.*', url => $url);
      }
    } else {
      my $vtext = $_;
      # Create a temporary orphan paragraph so we can use
      # ODF::lpOD::TextElement::set_text to populate it with PCDATA, tab, etc.
      # Then move the children out into the main temp container_para.
      state $local_tpara = odf_create_paragraph;
      $local_tpara->ODF::lpOD::TextElement::set_text($vtext);
      foreach my $e ( $local_tpara->cut_children() ) {
        $e->paste_last_child($container_para);
      }
    }
  }
  # Now all the new content has been added to $container_para
  $container_para->Hnormalize();

  # get_text(recursive => FALSE) will descend through spans
  # because spans are an ODF::lpOD::TextElement, but not
  # into enclosed Frames, drawing boxes, etc.  This is currently not
  # a problem because $content never generates those things.
  my $vlength = length($container_para->get_text); #undef if no leaves

  btw dvis '##Hi_c $vlength container_para = ', fmt_tree($container_para) if $debug;

  my @nodes = $container_para->cut_children();
  my $prev_sib;
  foreach my $e (@nodes) {
    # Insert the first segment wherever the caller said the content should go,
    # with subsequent segs as siblings.
    if (! $prev_sib) {
      $context->Hinsert_element($e, %opts);
    } else {
      $e->paste_after($prev_sib);
    }
    $prev_sib = $e;
  }

  # Remove now-empty spans and hoist spans-under-spans
  _cleanup_spans(\@nodes, %opts) unless $opts{_nocleanup};

  my $result = { vlength => $vlength // 0 };
  _show_context(dvis '##Hi_c RESULT: $result\n') if $opts{debug};

  confess "Hinsert_content() returns a scalar (a hashref)\n" if wantarray;
  $result;
}#Hinsert_content

####################################################

=head2 $boolean = $elt->His_textual()

Returns TRUE if C<$elt> is a leaf node which represents text,
either PCDATA/CDATA or one of the special ODF nodes representing tab,
line-break or consecutive spaces.

=head2 $boolean = $elt->His_text_container()

Returns TRUE if C<$elt> is a paragraph, heading or span.

=head2 $newelt = $elt->Hsplit_element_at($offset)

C<Hsplit_element_at> is like XML::Twig's C<split_at> but also knows how
to split text:s nodes.

If C<$elt> is a textual leaf (PCDATA, text:s, etc.) it is split, otherwise
it's first textual child is split.  Even a single-character leaf may be "split"
if $offset==0 or 1, see below.

The "right half" is moved to a new next sibling node, which is returned.

$offset must be between 0 and the existing length, inclusive.
If $offset is 0 then all existing content is moved to the new sibling
and the original node will be empty upon return.
if $offset equals the existing length then the new sibling will be empty.

If a text:s node is split then the new node will also be a text:s node
"containing" the appropriate number of spaces.  The 'text:c' attribute will
be zero if the node is "empty".

If a text:tab or text:line-break node is split then if $offset==0 the new node
will be an empty PCDATA node,
or if $offset==1 the original will be transmuted in-place to become
an empty PCDATA node.

=cut

sub ODF::lpOD::Element::His_textual {
  my $elt = shift;
  $elt->passes(TEXTLEAF_FILTER)
}
sub ODF::lpOD::Element::His_text_container {
  my $elt = shift;
  $elt->passes(TEXTCONTAINER_FILTER)
}

sub ODF::lpOD::Element::Hsplit_element_at {
  my ($elt, $offset) = @_;
  confess "Wrong number of arguments" unless @_==2;
  # see XML::Twig::split_at
  my $text_elt= $elt->His_textual() ? $elt
                                    : $elt->first_child(TEXTLEAF_FILTER)
                                        || confess("no textual leaf found");
  if ($text_elt->tag eq 'text:s') {
    my $existing_count = $text_elt->get_attribute('c') // 1;

    my $right_count = $existing_count - $offset;
    confess ivis 'offset $offset exceeds existing text:s count($existing_count)'
      if $right_count < 0;
    $text_elt->set_attribute('c', $offset); # possibly zero
    my $result = $text_elt->insert_element("text:s", position => NEXT_SIBLING);
    $result->set_attribute('c', $right_count); # possibly zero
    return $result
  }
  elsif ($text_elt->tag eq '#PCDATA') {
    my $existing_len = length($text_elt->text);
    confess ivis 'offset $offset exceeds existing pcdata length ($existing_len)'
      if $offset > $existing_len;
    return $text_elt->split_at($offset);
  }
  elsif ($offset == 0) {
#my $para = $elt->passes(PARA_FILTER) ? $elt : $elt->parent(PARA_FILTER);
#btw dvis 'BEFORE TRANSMUTE $para = ',fmt_tree($para);
#btw dvis 'BEFORE TRANSMUTE $elt = ',fmt_tree($elt);
    my $result =
         $text_elt->insert_element($text_elt->clone, position => NEXT_SIBLING);
#btw dvis '$result ',fmt_tree($result);
    # *TRANSMUTE* the original node to an empty PCDATA node
    $text_elt->del_atts();
    if (defined $text_elt->atts) {
      delete($text_elt->{att}) // oops; # Peeking into XML::Twig internals!
    }
    my @unhandled = grep{
                      ! /^(?:next_|prev_|first_|last_|parent|gi|empty|former)/
                    } keys %$text_elt;
    oops "unhandled left-over member(s) @unhandled" if @unhandled;
    $text_elt->set_tag("#PCDATA");
    # unpleasantly looking into ODF::lpOD internals...
    my $class = $ODF::lpOD::Element::CLASS{'#PCDATA'} // oops;
    bless $text_elt, $class;
    $text_elt->set_text("");
    return $result;
  }
  elsif ($offset == 1) {
    my $result = $text_elt->insert_element('#PCDATA', position=>NEXT_SIBLING);
    $result->set_text(""); # unnecessary?
    return $result;
  }
  else {
    confess "Hsplit_element_at : invocant $elt has no textual leaf"
  }
}# Hsplit_element_at

=head2 $context->Hget_text()

=head2 $context->Hget_text(prune_cond => COND)

Gets the combined "virtual text" in or below C<$context>,
by default including in nested paragraphs (e.g. in Frames or Tables).
The special nodes which represent tabs, line-breaks and
consecutive spaces are expanded to the corresponding characters.

Option B<prune_cond> may be used to omit text below specified node types
(see C<Hnext_elt>).

=head3 B<Note>

C<ODF::lpOD::TextElement::get_text()> with option I<recursive -E<gt> TRUE>
looks like it should do the same thing as C<Hget_text()>, but it has bugs:

=over 4

=item 1.

The special nodes for tab, etc. are expanded only when they are the
immediate children of $context.  With the 'recursive'
option #PCDATA nodes in nested paragraphs are expanded but tabs, etc.
are ignored.

=item 2.

If $context is itself a text leaf, it is expanded only if it is
a #PCDATA node, not if it is a tab, etc. node.

=back

I think get_text's "recursive" option was probably intended to include text from
paragraphs in possibly-nested frames and tables, and it was an oversight
that that special text nodes are not always handled correctly.

Note that B<Hget_text> is "recursive" by default; the 'prune_cond'
option is the only way to restrict recursion.

=cut

sub ODF::lpOD::Element::Hget_text {
  my ($self, %opt) = @_;
  croak "Hget_text has no 'recursive' option" if exists $opt{recursive};

  # The output_conversion cruft supports the old encoded-binary API used
  # by ODF::lpOD, and now does nothing unless our ':bytes' tag is imported.
  ODF::lpOD::Common::output_conversion(
    join "", map{ __leaf2vtext($_) }
             $self->Hdescendants_or_self(TEXTLEAF_FILTER, $opt{prune_cond})
  )
}


###################################################

=head2 $context->Hnormalize();

Similar to XML::Twig's C<normalize()> method but also "normalizes" text:s
usage.

Nodes are edited so that spaces are represented with the first or only
space in a #PCDATA node and subsequent consecutive spaces in a text:s node.
Adjacent nodes of the same type are merged, and empties deleted.

$context may be any text container or ancestor up to the document body.

=cut

sub ODF::lpOD::Element::Hnormalize {
  my $context = shift;
  my $debug = 0;
  my @descendants= $context->descendants('#PCDATA|text:s');
btw dvis 'Hnormalize TOP ',fmt_tree_brief($context,wi=>1) if $debug;

  # Relocate spaces between #PCDATA and text:s so that only single spaces are
  # in #PCDATA and text:s only represents 2nd and subsequent consecutive spaces
  DESCENDANT:
  for (my $i=0; $i <= $#descendants; ++$i) {
    my $desc = $descendants[$i];
    my $desc_tag = $desc->tag;
    my $desc_text = $desc->Hget_text;
    if ($desc_tag eq "#PCDATA" && $desc_text =~ /  +/) {
      # Move consecutive spaces after the first into a text:s
      my ($offset, $len) = ($-[0], $+[0]-$-[0]);
      my $s = $desc->insert_element("text:s",
                        position => WITHIN, offset => $offset+1);
      $s->set_attribute("text:c", $len-1);
      my $rfrag = $s->{next_sibling}; oops if grep{$rfrag==$_} @descendants;
      my $rfrag_text = $rfrag->text;
      substr($rfrag_text, 0, $len-1, "") eq (" " x ($len-1)) or oops;
      $rfrag->set_text($rfrag_text);
      splice @descendants, $i+1, 0, $s, $rfrag;
      redo;
    }
    if ($desc_tag eq "text:s" && length($desc_text) > 0) {
      # !! This might not be correct if the last preceding PCDATA has a
      # !! trailing space but it is isolated from $desc by span boundaries.
      # AFAIK ODF 1.2 permits text:s to hold all spaces without the first
      #   being in a preceding text segment, although it is recommended
      #   that the first space be sparate.   So for now, I'm leaving text:s
      #   unchanged if a span boundary or something else intervenes.
      my $prev = $desc;
      while ($prev = $prev->{prev_sibling}) {
        last unless $prev->tag eq "#PCDATA";
        my $prev_text = $prev->text//"";
        next if length($prev_text) == 0;
        last unless substr($prev_text, -1) ne " ";
        # Previous (non-empty) #PCDATA doesn't end with a space.
        # Move the first text:s space to the end of the #PCDATA segment
        $prev->set_text($prev_text." ");
        $desc->set_attribute('c', ($desc->get_attribute('c') // 1) - 1);
        next DESCENDANT
      }
      if (! $prev) {
        # text:s not preceded by PCDATA.  Move the first space to a new PCDATA.
        ##my $newelt = $desc->insert_element('#PCDATA', position=>PREV_SIBLING);
        ##$newelt->set_text(" ");
        ##$desc->set_attribute('c', ($desc->get_attribute('c') // 1) - 1);
        ##splice @descendants, $i, 0, $newelt;
        ##redo;
      }
    }
  }

btw dvis 'Hn before cleanup @descendants\n context:',fmt_node($context,wi=>1) if $debug;
  # Now cleanup any empties and merge adjacents
  while( my $desc= shift @descendants) {
    my $desc_len = length($desc->Hget_text);
    if( ! $desc_len) { $desc->delete; next; }
    while( @descendants
           && ((my $next_sib = $desc->{next_sibling})//0) == $descendants[0] ) {
      if (! length $next_sib->Hget_text) {
        shift(@descendants)->delete;
        next
      }
      my $to_merge= shift @descendants;
      my $desc_tag = $desc->tag;
      if ($desc_tag eq $next_sib->tag) {
        if ($desc_tag eq "text:s") {
          my $to_merge_count = $to_merge->get_attribute('c') // 1;
          $desc->set_attribute("text:c", $desc_len + $to_merge_count);
          $to_merge->delete;
          $desc_len += $to_merge_count;
        } else {
          $desc_len += length($to_merge->text);
          $desc->merge_text( $to_merge);
        }
      }
    }
  }

btw dvis 'Hnormalize FINAL ',fmt_tree($context,wi=>1) if $debug;
  return $context
}

###################################################

=head2 $next_elt = $prev_elt->Hnext_elt($subtree_root, $cond, $prune_cond);

This are like the "next_elt" method in L<XML::Twig> but
accepts an additional argument giving a "prune condition", which
if present suppresses descendants of matching nodes.

A pruned node is itself returned if it also matches the primary condition.

C<$subtree_root> is never pruned, i.e. it's children are always visited.

If C<$prune_cond> is undef then Hnext_elt works exactly
like XML::Twig's next_elt.

=head2 @elts = $context->Hdescendants($cond, $prune_cond);

=head2 @elts = $context->Hdescendants_or_self($cond, $prune_cond);

These are like the similarly-named non-B<H> methods of L<XML::Twig>
but can suppress descendants of nodes matching a "prune condition".

EXAMPLE 1: In an ODF document, paragraphs may contain frames which in turn
contain encapsulated paragraphs.  To find only top-level paragraphs and
treat frames as opaque:

    # Iterative
    my $body = $doc->get_body;
    my $elt = $body;
    while($elt = $elt->Hnext_elt($body, qr/^text:[ph]$/, 'draw:frame'))
    { ...process paragraph $elt }

    # Same thing but getting all the paragraphs at once
    @paras = $body->Hdescendants(qr/^text:[ph]$/, 'draw:frame');

EXAMPLE 2: Get all the leaf nodes representing ODF text in a paragraph
(including under spans), and also any top-level frames;
but not any content stored inside a frame:

    $para = ...
    my $elt = $para;
    while ($elt = $elt->Hnext_elt(
                       $para,
                      '#TEXT|text:tab|text:line-break|text:s|draw:frame',
                      'draw:frame')
          )
    { ...process PCDATA/CDATA/tab/line-break/spaces or frame $elt  }

If the B<$prune_cond> parameter is omitted or undef then these methods
work exactly like the corresponding non-B<H> methods.

C<Hnext_elt>, C<Hdescendants> and C<Hdescendants_or_self>
C<Hparent> and C<Hself_or_parent>
are installed as methods of I<XML::Twig::Elt>.

=cut

sub XML::Twig::Elt::Hnext_elt {
  my ($elt, $subtree_root, $select_cond, $prune_cond) = @_;
  confess "Hnext_elt: Wrong arg count" unless @_==4 || @_==3;
  confess "Hnext_elt: subtree_root is required"
    unless defined($subtree_root);

  my $have_prune_cond = defined($prune_cond);

  my sub _skipover($) {
    my $e = shift;
    # Unlike the code in XML::Twig::Elt::next_elt
    # we ignore any children and know that initially $e != $subtree_root
    until( $e->{next_sibling} ) {
      return undef if $e == $subtree_root;
      $e = $e->{parent} || return undef;
    }
    return undef if $e == $subtree_root;  #bugfix 8/22/23
    return $e->{next_sibling}
  }

  while(1) {
    if ($elt !=$subtree_root && $have_prune_cond && $elt->passes($prune_cond)) {
      $elt = _skipover($elt);
    } else {
      $elt = $elt->next_elt($subtree_root);
    }
    return $elt
      if !$elt || !defined($select_cond) || $elt->passes($select_cond);
  }
}
sub XML::Twig::Elt::Hdescendants {
  my ($subtree_root, $select_cond, $prune_cond) = @_;

  # Chain to descendants() if no prune_cond because it optimizes many cases
  goto &XML::Twig::Elt::descendants if !defined $prune_cond;

  my @descendants;
  my $elt = $subtree_root;
  while ($elt = $elt->Hnext_elt($subtree_root, $select_cond, $prune_cond)) {
    push @descendants, $elt;
  }
  @descendants;
}
sub XML::Twig::Elt::Hdescendants_or_self {
  my ($subtree_root, $select_cond, $prune_cond) = @_;
  # N.B. $subtree_root is not subject to pruning
  my @descendants = $subtree_root->passes($select_cond) ? ($subtree_root) : ();
  push @descendants, &XML::Twig::Elt::Hdescendants;
  @descendants;
}

=head2 $node->Hparent($cond, [$stop_cond])

Returns the nearest ancestor which matches condition C<$cond>.

If C<$stop_cond> is defined, then 0 is returned if the search would
ascend above the nearest ancestor matching the stop condition.
Undef is returned if no ancestor matches either $cond or $stop_cond.

For example,

  my $row = $elt->Hparent("table:table-row", "draw:frame");

would locate the table row containing $elt but return false if $elt was
encapsulated in a frame within an enclosing table row (0 result)
or not in a table at all (undef result).

=head2 $node->Hself_or_parent($cond, [$stop_cond])

Like C<Hparent> but returns $node itself if it matches $cond.

=cut

sub XML::Twig::Elt::Hparent($$;$) {
  my ($elt, $cond, $stop_cond) = @_;
  for(;;) {
    $elt = $elt->{parent} || return undef;
    return $elt if $elt->passes($cond);
    return 0 if $stop_cond && $elt->passes($stop_cond);
  }
}

sub XML::Twig::Elt::Hself_or_parent($$;$) {
  my ($elt, $cond, $stop_cond) = @_;
  return $elt if $elt->passes($cond);
  goto &XML::Twig::Elt::Hparent;
}

###################################################

=head2 $cond = Hor_cond(COND, ...)

This function combines multiple L<XML::Twig> search conditions into
a condition which matches any of the input conditions (hence "or").
The inputs may be any mixture of string, regex, or code-ref conditions.

Example:

  use ODF::lpOD_Helper qw(:DEFAULT PARA_FILTER);
  use constant MY_PARAORFRAME_FILTER => Hor_cond(PARA_FILTER, 'draw:frame');
  ...
  @elts = $context->descendants(MY_PARAORFRAME_FILTER)

This would collect all paragraphs or frames below $context.
Note that C<PARA_FILTER> might be C<'text:p|text:h'> or C<qr/^text:[ph]$/>
or C<sub{ $_[0] eq 'text:p' || $_[0] eq 'text:h' }> etc.

C<Hor_cond> optimizes a few regex forms into equivalent string conditions,
measured to be 30% faster.

=cut

###################################################

=head2 $context->Hgen_style_name($family, SUFFIX)

=head2 $context->Hgen_table_name(SUFFIX)

Generate a style or table name not currently in use.

In the case of a I<style>, the C<$family> must be specified
("text", "table", etc.).

SUFFIX is an optional string which will be appended to a generated
unique name to make recognition by humans easier.

C<$context> may be the document itself or any Element.

=cut

sub _gen_name($$$) {
  my ($doc, $family, $name_suffix) = @_;
  my $sh = _get_ephemeral_statehash($doc);
  my $counters = ($sh->{sn_counters} //= {});
  my $name = AUTO_PFX
                 .$family
                 .(++$counters->{$family})
                 .($name_suffix ? "_$name_suffix" : "");
  $name =~ s/ /-/g;
  # Avoid unknown unknowns about arbitrary chars
  $name =~ s/[^-._A-Za-z0-9]/./g; # ^allowed by OASIS for naming resources
  $name
}

sub ODF::lpOD::Element::Hgen_style_name {
  my ($context, $family, $name_suffix) = @_;
  my $doc = $context->get_document;
  for(;;) {
    my $name = _gen_name($doc, $family, $name_suffix);
    return $name unless defined($doc->get_style($family, $name));
  }
}

sub ODF::lpOD::Element::Hgen_table_name {
  my ($context, $name_suffix) = @_;
  my $doc = $context->get_document;
  for(;;) {
    my $name = _gen_name($doc, "Table", undef);
    return $name unless defined($context->get_table_by_name($name));
  }
}

sub ODF::lpOD::Document::Hgen_style_name {
  my ($doc, $family, $name_suffix) = @_;
  &ODF::lpOD::Element::Hgen_style_name($doc->get_body(), $family, $name_suffix);
}

=head2 $doc->Hautomatic_style($family, PROPERTIES...)

Find or create an 'automatic' (i.e. functionally anonymous) style
with the specified high-level properties (see C<Hreplace>).

Styles are re-used when possible, so the returned style object
should not be modified because it might be shared.

C<$family> must be "text" or another supported style family name (TODO: specify)

When family is "paragraph", PROPERTIES may include recognized 'text area'
properties, which are internally segregated and put into the
required 'text area' sub-style. Fonts are registered.

The invocant must be the document object.

=head2 $doc->Hcommon_style($family, PROPERTIES...)

Create a 'common' (i.e. named by the user) style from high-level properties.

The name, which must not name an existing style,
is given by C<< name => "STYLENAME" >> somewhere in PROPERTIES.

=cut

# (Internal) Create a style with specified properties.
# The caller must specify 'name' (except with default => TRUE).
#
# The caller should specify 'automatic'.
#
# 'part' defaults appropriately (to CONTENT or STYLES), but
# theoretically could be specified to, for example, force an automatic style
# into the STYLES part so it can later be referenced elsewhere in the STYLES
# part (The ODF::lpOD Style pod mentions this but I can't think of any
# actual example of an automatic style being referenced by another style,
# since inheriting from an automatic style is prohibited).
#
# Any fonts mentioned are globally registered (i.e. in both CONTENT and
# STYLES parts, via ODF::lpOD::Document::set_font_declaration()).
sub __create_style($$@) {
  my ($doc, $family, %opt) = @_;

  confess "Style 'name' must be specified" unless $opt{name};

  my $object;
  if ($family eq 'paragraph') {
    my (@popt, @topt);
    while(my ($key, $val) = each %opt) {
      if (__is_textonly_prop($key)) {
        push @topt, $key, $val;
      }
      elsif (__is_paraonly_prop($key) || $key =~ /^(?:part|name|automatic)$/) {
        push @popt, $key, $val;
      }
      else { croak "Unrecognized paragraph property '$key'" }
    }
    $object = odf_create_style('paragraph', @popt);
    if (@topt) {
      push @topt, (part => $opt{part}) if $opt{part};
      my $ts = $doc->Hautomatic_style('text', @topt);
      $object->set_properties(area => 'text', clone => $ts);
    }
  }
  elsif ($family eq 'text') {
    while(my ($key, $val) = each %opt) {
      confess "Unk text prop '$key'\n"
        unless __is_textonly_prop($key) || $key =~ /^(?:part|name|automatic)$/;
      if ($key eq "font") {
        unless ($doc->get_font_declaration($val)) {
          $doc->set_font_declaration($val);
        }
      }
    }
    $object = odf_create_style('text', %opt);
  }
  elsif ($family eq 'table') {
    while(my ($key, $val) = each %opt) {
      croak "Unk table prop '$key'\n"
        unless __is_table_prop($key) || $key =~ /^(?:part|name|automatic)$/;
    }
    $object = odf_create_style('table', %opt);
  }
  else {
    confess "style family '$family' not (yet) supported"
      unless $family =~ /^(table|table-cell)$/;
    # ROLL THE DICE!  this might or might not work...
    oops if grep /font/, keys %opt;
    $family =~ s/-/ /g;
    $object = odf_create_style($family, %opt);
  }

  return $doc->insert_style($object, %opt);
}# __create_style

sub ODF::lpOD::Document::Hautomatic_style {
  my ($doc, $family, @input_props) = @_;
  my %props = @{ __unabbrev_props(\@input_props) };

  my $sh = _get_ephemeral_statehash($doc);
  my $style_caches = ($sh->{style_caches} //= {});

  my $cache = ($style_caches->{$family} //= {});

  # FIXME: Allow clone => clonee ?
  #   ...maybe not needed.  But if we do allow 'clone', we might have to
  #   unconditionally create the style (cloning the clonee), extract
  #   the properties and construct a cache_key, and discard the new style
  #   and use the cached style if appropriate.
  #
  #   The necessary style-to-cache_key logic would be also used when pre-loading
  #   the cache with existing styles, should that be implemented (see below).

  # Currently only styles created in the current session are re-used, so
  # repeated runs on the same document might accumulate identical twins.
  #
  # If this turns out to be unacceptable, then we could load the cache
  # the first time by finding existing styles with names beginning with
  # AUTO_PFX and deriving the correspojnding cache_keys.  This would be
  # complex -- see logic in ODF::lpOD::Document::insert_style.

  my $cache_key = hashtostring(\%props); # unique only within family
  my $stylename = $$cache{$cache_key};
  if (defined $stylename) {
    return $doc->get_style($family, $stylename);
  } else {
    my $suffix =
      $ODF::lpOD::Common::DEBUG
        ? join("_", map{ "$_=".u($props{$_}) } keys %props)
        : join("_", grep{defined}
                           map{$props{$_}}
                           qw/align weight style variant size/);
    $stylename = $doc->Hgen_style_name($family, $suffix);
    $$cache{$cache_key} = $stylename;

    __create_style($doc, $family,
                   %props, automatic => TRUE, part => CONTENT,
                   name => $stylename);
  }
}

sub ODF::lpOD::Document::Hcommon_style($$@) {
  my ($doc, $family, @input_props) = @_;
  my %props = @{ __unabbrev_props(\@input_props) };
  __create_style($doc, $family,
                 %props, automatic => FALSE, part => STYLES);
}

###################################################

###################################################

=head2 arraytostring($arrayref)

=head2 hashtostring($hashref)

Returns a signature string uniquely representing the members
(keys and values in the case of a hash).

References are not recursively examined, but are represented
using their 'refaddr'.  Signatures of different structures
will match only if corresponding first-level non-ref values are 'eq'
and refs are exactly the same refs.

=cut

sub _item_rep(_) {
  local $_ = $_[0];
  return("~".refaddr($_)) if ref;
  s/([\~\!\\])/\\$1/g; # so a string can not fake something else
  $_
}

sub hashtostring($) {
  my $href = shift;
  return join( "!", map{ _item_rep($_)."="._item_rep($href->{$_}) }
                    sort keys %$href );
}

sub arraytostring($) {
  my $aref = shift;
  return join( "!", map{ _item_rep } @$aref );
}

###################################################

=head2 fmt_node($node, OPTIONS)

Format a single ODF::lpOD (really XML::Twig) node for
debug messages, without a final newline.

C<wi =E<gt> NUM> may be given in OPTIONS
to indent wrapped lines by the indicated number of spaces.

=head2 fmt_tree($subtree_root, OPTIONS)

Format a node and all of it's children (sans final newline).

=for Pod::Coverage TEXTLEAF_FILTER PARA_FILTER TEXTCONTAINER_FILTER
=for Pod::Coverage fmt_node_brief fmt_tree_brief fmt_match
=cut

sub _abbrev_addrvis($) {  # like DDI::addrvis() but elides ODF::lpOD:: prefix
  my $node = shift;
  my $result = addrvis($node);
  $result =~ s/ODF::lpOD:://;
  $result
}

# fmt_tree($subtree) output is like
#
#   tag Class<address> {
#     att={key => value, ... }  # attributes
#     parent=Class<address>
#     "text content"
#     (first child)
#     ...
#     (last child)
#   }
#
# fmt_node($node) is similar but omits children, however if the node is a
# container the collected text from any children is shown.
#
# The optional option parent => $somenode gives the expected {parent} value;
# {parent} is not shown unless it is something else.
#
sub fmt_node(_;@) {  # sans final newline
  my $node = shift;
  my %opts = (showlevel => FALSE, showaddr => TRUE, showlen => TRUE, showisa => TRUE, @_);
  return "undef" unless defined($node);
  oops unless ref($node);
  $opts{wi} //= 0;  # wi = "wrap indent"
  my $wrapspace = " " x $opts{wi};

  state $indent_incr = 2;
  state $indent_incr_space = " " x $indent_incr;

  $opts{_seen} //= {};
  oops if $opts{_seen}->{$node}++;  # sanity check

  my $tag  = eval{ $node->tag };

  #ref($node) =~ /ODF::lpOD::(\w+)/;
  #my $class = $1 // ref($node) || confess("not a ref");

  my $tagopen = "";
  if (defined $tag) {
    $tag =~ s/^#/\\#/; # don't confuse vim syntax with unescaped #
    $tagopen .= "${tag} ";
  }
  if ($opts{showaddr}) {
    $tagopen .= _abbrev_addrvis($node);
    my $class = blessed($node);
    if ($opts{showisa} && $class && $class ne "ODF::lpOD::Element") {
      no strict 'refs';
      foreach (@{"${class}::ISA"}) {
        (my $base = $_) =~ s/ODF::lpOD:://;
        $tagopen .= "(isa $base)"
      }
    }
    $tagopen .= " ";
  }
  $tagopen .= "{";
  if ($opts{showlevel}) {
    $tagopen .= $opts{_level};
    ++$opts{_level};
  }

  my @middle_parts;
  my $mid_foldwidth = visnew->Foldwidth() - (($opts{wi}//0) + $indent_incr);
  my $mid_visobj = visnew->Pad($wrapspace.$indent_incr_space)
                         ->Foldwidth($mid_foldwidth);

  if (defined($opts{parent})) {
    push @middle_parts,
         "**UNEXPECTED {parent}="._abbrev_addrvis($node->{parent})
         ." EXPECTING "._abbrev_addrvis($opts{parent})
      if refaddr($opts{parent}) != refaddr($node->{parent});
  } else {
    push @middle_parts, "{parent}="._abbrev_addrvis($node->{parent})
      if $opts{showaddr};
  }
  if (defined(my $att  = $node->get_attributes)) {
    if (($tag//"") =~ /^(table-cell|sequence)/ && !$opts{showall}) {
      push @middle_parts, "att={...}"; # voluminous & uninteresting
    } else {
      my %edited_att = map{ ($_ => $att->{$_}) }
                       grep{ !/^#lpod:/ }  # e.g. #lpod:part circular reference
                       keys %$att;
      push @middle_parts,
           #"att=".$mid_visobj->visq(\%edited_att);
           "att=".$mid_visobj->Foldwidth1($mid_foldwidth-4)->visq(\%edited_att);
    }
  }

  if ($opts{internals}) {
    for my $key (sort keys %$node) {
      next if $key =~ /^(?:parent|first_child|last_child
                           |prev_sibling|next_sibling
                           |att)$/x;

      push @middle_parts,
           "{${key}}=".$mid_visobj->Maxdepth(1)->vis($node->{$key});
    }
  }

  my ($text_pfx, $text_suf) = ("", "");
  my $text = eval{ __leaf2vtext($node) }; # undef (throws) if not a leaf
  unless ($opts{_leaftextonly}) {
    if (! defined $text) {
      local $ODF::lpOD::Common::OUTPUT_CHARSET = undef; # always get characters
      $text = $node->get_text;
      $text_suf .= "[non-leaf]" if defined($text);

    }
    if (! defined $text) {
      $text = $node->text(); # Twig primitive
      $text_suf .= "[Frame? Table?]" if defined($text);
    }
  }
  if (defined $text) {
    $text_suf = "(len=".length($text).")" . $text_suf
      if $opts{showlen} && length($text) > 4;
    if (defined(my $_vtoref = $opts{_vtoref})) {
      $text_pfx .= $$_vtoref.":";
      $$_vtoref += length($text);
    }
    push @middle_parts, $text_pfx
                        .visnew->Useqq("unicode:controlpic")->vis($text)
                        .$text_suf;
  }

  my @children = $node->children;
  { if ($opts{_recursive}) {
      local $opts{wi} = $opts{wi} + $indent_incr;
      local $opts{parent} = $node;
      foreach my $child (@children) {
        push @middle_parts, __SUB__->($child, %opts);
      }
    } else {
      if (@children > 0 && (!defined($text) || @children > 1)) {
        push @middle_parts, "(" . scalar(@children)
                            . (@children==1 ? " child)" : " children)");
      }
    }
  }

  my $tagclose = "}";
  if ($opts{showlevel}) {
    --$opts{_level};
    if (@children > 2) {
      my $pfx = $node->ns_prefix;
      (my $abbrtag = $tag) =~ s/^\Q${pfx}\E://;
      $tagclose .= $opts{_level}."($abbrtag)"
    }
  }

  # Format as a single line if possible, otherwise as
  # tag {
  #   parent= ...
  #   att={ ... }
  #   [vtoffset]"text"
  #   first child
  #   ...
  #   last child
  # }

  my $minlen = $opts{wi}
               + length($tagopen) + 1
               + sum0(map{1 + length} @middle_parts)
               + 1 + length($tagclose);
  my $maxwidth = $opts{maxwidth} // $ENV{COLUMNS} // 80;
  if ($minlen <= $maxwidth or $maxwidth == 0) {
    return join(" ", $tagopen, @middle_parts, $tagclose);
  }

  return join("",
              $tagopen,
                #visnew->dvis1('AAA«$wrapspace @middle_parts $tagclose»'),
                "\n$wrapspace",
              (map { $indent_incr_space . $_ . "\n${wrapspace}" }
                   @middle_parts),
              $tagclose);
}#fmt_node
sub fmt_node_brief(_;@) {
  fmt_node($_[0], showaddr=>FALSE, showlen=>FALSE, showoff=>FALSE, @_[1..$#_])
}

sub fmt_tree(_;@) { # sans final newline
  my $top = shift;
  my %opts = (showoff => TRUE, showlevel => TRUE, @_);
  my $indent = $opts{indent} // 0;
  my $string = "";
  my $parent;
  if ($opts{ancestors} and ref $top) {
    my @a = reverse $top->ancestors;
    $parent = shift @a; # don't show the document container
    foreach my $e (@a) {
      $string .= ("<"x$indent)
                 .fmt_node($e,_leaftextonly => 1,parent => $parent)
                 ."\n";
      $parent = $e;
      $indent++;
    }
  }
  my $vtoffset = 0;
  $opts{_vtoref} = \$vtoffset if $opts{showoff};
  $opts{_level} = 0;
  fmt_node($top, %opts, _leaftextonly => 1, _recursive => 1);
}
sub fmt_tree_brief(_;@) {
  fmt_tree($_[0], showaddr=>FALSE, showlen=>FALSE, showoff=>FALSE, @_[1..$#_])
}

#######################################################3

# Format a match structure as returned by Hsearch (not search)
sub fmt_match(_;@) { # sans final newline
  my $href = shift;
  my %opts = @_;

  return "undef" unless defined $href;

  my %h = %$href;
  my $s = "{";

  my sub _vis_with_len($) {
    my $item = shift;
    my $result = vis($item);
    if ($result =~ /^"/) { # a string or stringified object
      $result .= " (len=".length($item).")" if length($item) > 4;
    }
    $result
  }
  my sub _collect(@) {
    my $ss = "";
    foreach my $key (@_) {
      $ss .= " $key="._vis_with_len(delete $h{$key})
        if exists ($h{$key});
    }
    $ss # "" if none of the keys exist
  }
  my sub _append_new_line(@) {
    my $ss = _collect(@_);
    $s .= "\n ".$ss if $ss ne "";
  }

  my $segments;
  if (exists $h{segments}) {
    $segments = [ map {
                    my $t = __leaf2vtext($_);
                    $_->tag." ".addrvis(refaddr $_)." "._vis_with_len($t)
                  } @{ delete $h{segments} }
                ];
  }

  _append_new_line(qw/match/);
  _append_new_line(qw/voffset vend vlength/);
  if (exists $h{para}) {
    local $opts{wi} += 2;
    $s .= "\n  para => ".fmt_node(delete $h{para}, %opts)."\n ";
  }
  $s .= _collect("para_voffset");
  _append_new_line(qw/offset end/);
  for my $key (sort keys %h) {
    $s .= _collect($key);
  }
  $s .= "\n  segments => [\n    ".join("\n    ",@$segments)."\n  ]"
    if defined $segments;

  return $s."\n}";
}#fmt_match
sub fmt_Hreplace_results(@) {
  my $results = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? $_[0] : \@_;
  "(".(join ",\n", map{fmt_match($_)} @$results).")";
}
sub fmt_Hreplace_result(_) {
  goto &fmt_match
}

=head1 LIBRE OFFICE 'RSID' WORK-AROUND

LibreOffice tracks revisions by installing special spans
using "rsid" styles which interfere with cloning.
One problem is that LO expects these styles to be referenced exactly
once.  The C<Hclean_for_cloning()> method will remove them.

An old 2015 bug report said a "no rsids" feature was added to Libre Office
4.5.0 but this author could not find such a feature.
See L<https://bugs.documentfoundation.org/show_bug.cgi?id=68183>.

=head2 $doc->Hclean_for_cloning();

This unpleasant hack removes all "rsid" properties from all styles the document.

C<Hclean_for_cloning> should be called before cloning anything
in a document if the cloned items might have been edited by Libre Office.
It may be called multiple times; second and subsequent calls do nothing.

In detail:
Every style in the document is examined and any
B<officeooo:rsid> and B<officeooo:paragraph-rsid> attributes are deleted.
Then every span in the document body is examined and if the span's
style is a style which no longer has any properties (i.e. it existed
only to record an rsid property), then the span is erased, moving up the
span's children, and the empty style is deleted.

=cut

# Hack to remove officeooo:rsid text properties from text styles,
# which if cloned or otherwise used for multiple spans cause Libre Office
# to hang or crash.
#
sub ODF::lpOD::Document::Hclean_for_cloning {
  my ($doc, %opts) = @_;

  my $sh = _get_ephemeral_statehash($doc);
  return if $sh->{cleaned_for_cloning}++;

  my %rsid_styles; # stylename => style
  {
    # Find all children of style:style
    # (namely style:{paragraph,text}-properties) containing an rsid property
    # and delete the property from the style.

    my $xp = '//style:style/[@officeooo:paragraph-rsid or @officeooo:rsid]';
    my @items=($doc->get_elements(STYLES,$xp), $doc->get_elements(CONTENT,$xp));
    foreach my $item (@items) {
      # style:paragraph-properties or style:text-properties
      my $atts = $item->atts;  # XML::Twig
      # DELETE the rsid property
      my @attnames = grep{ /rsid/ } keys %$atts;
      oops unless @attnames;
      delete @$atts{@attnames};
      $item->set_atts($atts); # XML::Twig
      my $style = $item->parent('style:style') // oops;
      $rsid_styles{$style->get_name} = $style;
    }

    my @items2=($doc->get_elements(STYLES,$xp), $doc->get_elements(CONTENT,$xp));
    oops if @items2;
  }

  # The body is still littered with spans which use now-zero-effect styles
  # (now that the rsid properties are gone).

  # Check every span in the document body
  my $body = $doc->get_body;
  my $span = $body;
  my @to_be_erased;
  while ($span = $span->next_elt($body, 'text:span')) {
    my $tsname = $span->get_attribute('style') // oops;
    my $style = $rsid_styles{$tsname};
    unless ($style) {
#btw dvis 'MM0 $tsname not in rsid_styles' if $opts{debug};
      next;
    }
#btw dvis 'MM1 $span $tsname $style' if $opts{debug};
    if (ref $style) { # not (yet) deleted
      oops unless $style->{parent};
      my $props_remain;
      foreach my $ch ($style->children) {
         oops unless $ch->tag() =~ /^style:.*properties$/;
         #my $atts = $item->atts;  # XML::Twig
         my $atts = $ch->get_attributes;
         ($props_remain=1,last) if keys %$atts;
      }
      if (! $props_remain) {
        btw "$tsname : Deleting rsid-only style ",fmt_tree($style, internals=>1)
          if $opts{debug};
        $style->delete;
        $rsid_styles{$tsname} = $style = "DELETED";
      } else {
        btw "$tsname : KEEPING style ",fmt_tree($style, internals=>1) if $opts{debug};
      }
    }
    push @to_be_erased, $span if $style eq "DELETED";
  }
  foreach my $span (@to_be_erased) {
    btw "Erasing rsid-only span ",fmt_node($span) if $opts{debug};
    $span->erase; # XML::Twig
  }
}#Hclean_for_cloning

=head1 HISTORY

The original ODF::lpOD_Helper was written in 2012 and used privately.
In early 2023 the code was released to CPAN.
In Aug 2023 a major overhaul was released as rev 6.000 with API changes.

As of Feb 2023, the underlying ODF::lpOD is not actively maintained
(last updated in 2014, v1.126), and is unusable as-is.
However with ODF::lpOD_Helper, ODF::lpOD is once again an
extremely useful tool.

B<Motivation:> ODF::lpOD by itself can be inconvenient because

=over

=item 1.

Method arguments must be passed as encoded binary bytes,
rather than character strings.  See L<ODF::lpOD_Helper::Unicode>
for why this is a problem.

=item 2.

I<search()> can not match segmented strings, and so
can not match text which was internally fragmented by LibreOffice
(e.g. for rsids), or which crosses style boundaries;
nor can searches match tab, newline or consecutive spaces, which
are represented by specialized elements.
I<replace()> has analogous limitations.

=item 3.

Nested paragraphs (which can occur via frames and tables) are difficult
or impossible to deal with because of various limitations of L<ODF::lpOD>
(notably with C<get_text()>).

=item 4.

"Unknown method DESTROY" warnings occur without a patch.
L<https://rt.cpan.org/Public/Bug/Display.html?id=97977>

=back

=head2 Why not just fix ODF::lpOD ?

Ideally L<ODF::lpOD> bugs would be fixed
and enhancements added in a compatible way, with
a single integrated documentation set for everything.

However the author of L<ODF::lpOD>, Jean-Marie Gouarne,
is no longer active and some bugs (notably with C<get_text>) seem to
require non-trivial changes across the class hierarchy.
ODF is a complex subject and ODF::lpOD encodes deep knowledge about it.
It seems unwise at this point in history to risk de-stabilizing ODF::lpOD.

ODF::lpOD_Helper introduced higher-level features which might
better be done by extending ODF::lpOD in a compatible way.
That is still a distant goal, but would involve
major surgery on ODF::lpOD and careful regression testing
against unknown legacy applications of ODF::lpOD.

=head1 SEE ALSO

ODF::MailMerge

=head1 AUTHOR

Jim Avera  (jim.avera AT gmail)

=head1 LICENSE

ODF::lpOD_Helper is in the Public Domain or CC0 license.
However it requires ODF::lpOD to function so as a practical matter
you must comply with ODF::lpOD's license.

ODF::lpOD (as of v1.126) may be used under the GPL 3 or Apache 2.0 license.

=for Pod::Coverage oops btw btwN
=for Pod::Coverage fmt_node_brief fmt_tree_brief fmt_match
=for Pod::Coverage fmt_Hreplace_result fmt_Hreplace_results

=cut

1;
