#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

package String::Tagged::Markdown 0.03;

use v5.26;
use warnings;
use experimental 'signatures';
use base qw( String::Tagged );

use List::Util 1.45 qw( any uniqstr );

=head1 NAME

C<String::Tagged::Markdown> - parse and emit text with Markdown inline formatting

=head1 SYNOPSIS

   use String::Tagged::Markdown;

   my $st = String::Tagged::Markdown->parse_markdown( $markdown );

   # Conforms to the String::Tagged::Formatting API
   String::Tagged::Terminal->new_from_formatting(
      $st->as_formatting
   )->say_to_terminal;

=head1 DESCRIPTION

This subclass of L<String::Tagged> handles text that contains inline markers
to give formatting hints, in the style used by Markdown. For example, text
wrapped in double-asterisks indicates it should be bold (as C<**bold**>), or
single-asterisks to indicate italics (as C<*italics*>).

This module does B<not> provide a full Markdown parser, but it does handle
enough of the simple inline markers that it could be used to handle
Markdown-style formatting hints of small paragraphs of text.

=head1 TAGS

This module provides the following tags.

=head2 bold, italic, strike, fixed

Boolean values indicating bold, italics, strike-through or fixed-width.

=head2 link

String value indicating a link. The value itself is the link target.

=cut

# Use class methods that depend on the specific tags we parse, so we can
# easily extend the syntax using a subclass

sub markdown_markers
{
   "**" => "bold",
   "*"  => "italic",
   "__" => "bold",
   "_"  => "italic",
   "~~" => "strike",
   "`"  => "fixed",
}

sub __cache_per_class ( $code )
{
   my %cache;
   return sub ( $self ) {
      my $class = ref $self || $self;
      return $cache{$class} //= $code->( $class );
   };
}

*TAG_FOR_MARKER = __cache_per_class sub ( $class ) {
   return +{ $class->markdown_markers };
};

# Reverse mapping of TAG_FOR_MARKER
*MARKER_FOR_TAG = __cache_per_class sub ( $class ) {
   my $TAG_FOR_MARKER = $class->TAG_FOR_MARKER;

   return +{ map {
      # Don't emit _ markers
      ( $_ =~ m/_/ ) ? () : ( $TAG_FOR_MARKER->{$_} => $_ ),
   } keys %$TAG_FOR_MARKER };
};

# Regexp to match any formatting marker
*MARKER_PATTERN = __cache_per_class sub ( $class ) {
   my $TAG_FOR_MARKER = $class->TAG_FOR_MARKER;

   my $re = join "|", map { quotemeta $_ }
                      sort { length $b <=> length $a }
                      keys %$TAG_FOR_MARKER;
   qr/$re/;
};

# Regexp to match any character that needs escaping
*NEEDS_ESCAPE_PATTERN = __cache_per_class sub ( $class ) {
   my $TAG_FOR_MARKER = $class->TAG_FOR_MARKER;

   my $chars = quotemeta join "", uniqstr map { substr( $_, 0, 1 ) } (
      keys %$TAG_FOR_MARKER,
      "\\", "[", "]"
   );
   my $re = "[$chars]";
   $re = qr/$re/;
};

=head1 CONSTRUCTORS

=cut

=head2 parse_markdown

   $st = String::Tagged::InlineFormatted->parse_markdown( $str )

Parses a text string containing Markdown-like formatting as described above.

Recognises the following kinds of inline text markers:

   **bold**

   *italic*

   ~~strike~~

   `fixed`

   [link](target)

   backslashes escape any special characters as \*

In addition, within C<`fixed`> width spans, the other formatting markers are
not recognised and are interpreted literally. To include literal backticks
inside a C<`fixed`> width span, use multiple backticks and a space to surround
the sequence. Any sequence of fewer backticks within the sequence is
interpreted literally. A single space on each side immediately within the outer
backticks will be stripped, if present.

   `` fixed width with `literal backticks` inside it ``

=cut

sub parse_markdown ( $class, $str )
{
   my $self = $class->new;

   my %tags_in_effect;
   my $link_start_pos;

   my $MARKER_PATTERN = $class->MARKER_PATTERN;
   my $TAG_FOR_MARKER = $class->TAG_FOR_MARKER;

   pos $str = 0;
   while( pos $str < length $str ) {
      if( $str =~ m/\G\\(.)/gc ) {
         # escaped
         $self->append_tagged( $1, %tags_in_effect );
      }
      elsif( !defined $link_start_pos and $str =~ m/\G\[/gc ) {
         # start of a link
         $link_start_pos = length $self;
      }
      elsif( defined $link_start_pos and $str =~ m/\G\]\(/gc ) {
         $str =~ m/\G(.*?)\)/gc; # TODO: if it fails?
         my $target = $1;

         $self->apply_tag( $link_start_pos, length $self, link => $target );
         undef $link_start_pos;
      }
      elsif( $str =~ m/\G($MARKER_PATTERN)/gc ) {
         my $marker = $1;
         my $tag = $TAG_FOR_MARKER->{$marker};

         if( $marker eq "`" ) {
            if( $str =~ m/\G(`)+/gc ) {
               $marker .= $1;
            }
            $str =~ m/\G(.*?)(?:\Q$marker\E|$)/gc;
            my $inner = $1;
            $inner =~ s/^ (.*) $/$1/ if length $marker > 1;
            $self->append_tagged( $inner, %tags_in_effect, $tag => 1 );
            next;
         }

         $tags_in_effect{$tag} ? delete $tags_in_effect{$tag}
                               : $tags_in_effect{$tag}++;
      }
      else {
         $str =~ m/\G(.*?)(?=$MARKER_PATTERN|\\|\[|\]|$)/gc;
         $self->append_tagged( $1, %tags_in_effect );
      }
   }

   return $self;
}

=head2 new_from_formatting

   $st = String::Tagged::Markdown->new_from_formatting( $fmt, %args )

Returns a new instance by convertig L<String::Tagged::Formatting> standard
tags.

The C<bold>, C<italic> and C<strike> tags are preserved. C<monospace> is
renamed to C<fixed>.

Supports the following extra named arguments:

=over 4

=item convert_tags => HASH

Optionally provides additional tag conversion callbacks, as defined by
L<String::Tagged/clone>.

=back

=cut

*_TAGS_FROM_FORMATTING = __cache_per_class sub ( $class ) {
   return +{ $class->tags_from_formatting };
};

sub tags_from_formatting ( $class )
{
   bold      => "bold",
   italic    => "italic",
   monospace => "fixed",
   strike    => "strike",
}

sub new_from_formatting ( $class, $orig, %args )
{
   my $CONVERSIONS = $class->_TAGS_FROM_FORMATTING;

   if( $args{convert_tags} ) {
      $CONVERSIONS = { $CONVERSIONS->%*, $args{convert_tags}->%* };
   }

   return $class->clone( $orig,
      only_tags => [ keys $CONVERSIONS->%* ],
      convert_tags => $CONVERSIONS,
   );
}

=head1 METHODS

=cut

=head2 build_markdown

   $str = $st->build_markdown

Returns a plain text string containing Markdown-like inline formatting markers
to format the tags in the given instance. Uses the notation given in the
L</parse_markdown> method above.

=cut

sub build_markdown ( $self )
{
   my $ret = "";
   my @tags_in_effect;  # need to remember the order
   my $link_target;

   my $NEEDS_ESCAPE_PATTERN = $self->NEEDS_ESCAPE_PATTERN;
   my $MARKER_FOR_TAG       = $self->MARKER_FOR_TAG;

   $self->iter_substr_nooverlap( my $code = sub ( $substr, %tags ) {
      while( @tags_in_effect and !$tags{ $tags_in_effect[-1] } ) {
         my $tag = pop @tags_in_effect;

         if( $tag eq "link" ) {
            $ret .= "]($link_target)";
         }
         else {
            my $marker = $MARKER_FOR_TAG->{$tag};
            $ret .= $marker;
         }
      }

      # TODO: It'd be great if we could apply multiple tags in length order so
      # as to minimise the need to undo them
      my @tags = exists $tags{link} ?
         # link should always be first
         ( "link", sort grep { $_ ne "link" } keys %tags ) :
         ( sort keys %tags );

      foreach my $tag ( @tags ) {
         next if any { $_ eq $tag } @tags_in_effect;

         if( $tag eq "link" ) {
            $ret .= "[";
            $link_target = $tags{link};
         }
         else {
            my $marker = $MARKER_FOR_TAG->{$tag};
            $ret .= $marker;
         }

         push @tags_in_effect, $tag;

      }

      # Inside `fixed`, markers don't need escaping
      if( $tags{fixed} ) {
         # If the interior contains literal `s then we'll have to use multiple
         # and a space to surround it
         my $more = "";
         $more .= "`" while $substr =~ m/`$more/;

         $substr = "$more $substr $more" if length $more and $substr =~ m/^`|`$/;
      }
      else {
         $substr =~ s/($NEEDS_ESCAPE_PATTERN)/\\$1/g;
      }
      $ret .= $substr;
   } );
   # Flush the final tags at the end
   $code->( "", () );

   return $ret;
}

=head2 as_formatting

   $fmt = $st->as_formatting( %args )

Returns a new C<String::Tagged> instance tagged with
L<String::Tagged::Formatting> standard tags.

The C<bold>, C<italic> and C<strike> tags are preserved, C<fixed> is renamed
to C<monospace>. The C<link> tag is currently not represented at all.

Supports the following extra named arguments:

=over 4

=item convert_tags => HASH

Optionally provides additional tag conversion callbacks, as defined by
L<String::Tagged/clone>.

=back

=cut

*_TAGS_TO_FORMATTING = __cache_per_class sub ( $class ) {
   return +{ $class->tags_to_formatting };
};

sub tags_to_formatting ( $class )
{
   bold   => "bold",
   italic => "italic",
   fixed  => "monospace",
   strike => "strike",
}

sub as_formatting ( $self, %args )
{
   my $CONVERSIONS = $self->_TAGS_TO_FORMATTING;
   if( $args{convert_tags} ) {
      $CONVERSIONS = { $CONVERSIONS->%*, $args{convert_tags}->%* };
   }

   return String::Tagged->clone( $self,
      only_tags => [ keys $CONVERSIONS->%* ],
      convert_tags => $CONVERSIONS,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
