#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package String::Tagged::Markdown::HFM 0.04;

use v5.26;
use warnings;
use experimental 'signatures';
use base qw( String::Tagged::Markdown );

=head1 NAME

C<String::Tagged::Markdown::HFM> - parse and emit text with F<HedgeDoc Flavoured Markdown>

=head1 SYNOPSIS

   use String::Tagged::Markdown::HFM;

   my $st = String::Tagged::Markdown::HFM->parse_markdown( $markdown );

   # Conforms to the String::Tagged::Formatting API
   String::Tagged::Terminal->new_from_formatting(
      $st->as_formatting
   )->say_to_terminal;

=head1 DESCRIPTION

This subclass of L<String::Tagged::Markdown> handles all of the Markdown
syntax recognised by the base class, and in addition the inline span marker
extensions that are recognised by F<HedgeDoc Flavoured Markdown>, the version
of Markdown used on L<https://hedgedoc.org>.

=head1 TAGS

This module adds the following extra tags.

=head2 superscript, subscript, underline, highlight

Boolean values indicating superscript, subscript, underline or highlight.
These are parsed from

   ^superscript^
   ~subscript~
   ++underline++
   ==highlight==

=cut

sub markdown_markers
{
   shift->SUPER::markdown_markers,
   "++" => "underline",
   "^"  => "superscript",
   "~"  => "subscript",
   "==" => "highlight";
}

our $HIGHLIGHT_COLOUR;

=head1 METHODS

=head2 as_formatting

   $fmt = $st->as_formatting( %args );

Returns a new C<String::Tagged> instance tagged with
L<String::Tagged::Formatting> standard tags.

By default the C<highlight> tag is not handled, but optionally the caller can
specify how to handle it by setting a callback in the C<convert_tags>
argument.

   $st->as_formatting(
      convert_tags => { highlight => sub { ... } }
   );

Alternatively, this can be handled automatically by providing a colour to be
set as the value of the C<bg> tag - either by passing the C<highlight_colour>
named argument, or setting the value of the package-global
C<$HIGHLIGHT_COLOUR>. Remember that this should be an instance of
L<Convert::Color>.

   $st->as_formatting(
      highlight_colour => Convert::Color->new( "vga:yellow" )
   );

=cut

sub tags_to_formatting
{
   shift->SUPER::tags_to_formatting,
   underline   => "under",
   superscript => sub { sizepos => "super" },
   subscript   => sub { sizepos => "sub" },
}

sub as_formatting ( $self, %args )
{
   my %convert_tags = $args{convert_tags} ? $args{convert_tags}->%* : ();

   if( my $highlight_colour = delete $args{highlight_colour} // $HIGHLIGHT_COLOUR ) {
      $convert_tags{highlight} = sub { bg => $highlight_colour };
   }

   return $self->SUPER::as_formatting(
      %args,
      convert_tags => \%convert_tags,
   );
}

=head2 new_from_formatting

   $st = String::Tagged::Markdown::HFM->new_from_formatting( $fmt, %args );

Returns a new instance by converting L<String::Tagged::Formatting> standard
tags.

By default the C<highlight> tag is not generated, but optionally the caller
can specify how to generate it by setting a callback in the C<convert_tags>
argument, perhaps by inspecting the background colour.

   String::Tagged::Markdown::HFM->new_from_formatting( $orig,
      convert_tags => { bg => sub ($k, $v) { ... } }
   );

Alternatively, this can be handled automatically by providing a colour to be
matched against the C<bg> tag - either by passing the C<highlight_colour>
named argument, or setting the value of the package-global
C<$HIGHLIGHT_COLOUR>. Remember that this should be an instance of
L<Convert::Color>. If the value of the C<bg> is within 5% of this colour, the
C<highlight> tag will be applied.

   String::Tagged::Markdown::HFM->new_from_formatting( $orig,
      highlight_colour => Convert::Color->new( "vga:yellow" )
   );

=cut

sub tags_from_formatting
{
   shift->SUPER::tags_from_formatting,
   under   => "underline",
   sizepos => sub ($k, $v) {
      $v eq "super" ? ( superscript => 1 ) :
      $v eq "sub"   ? ( subscript   => 1 ) :
                      ()
   },
}

sub new_from_formatting ( $class, $orig, %args )
{
   my %convert_tags = $args{convert_tags} ? $args{convert_tags}->%* : ();

   if( my $highlight_colour = delete $args{highlight_colour} // $HIGHLIGHT_COLOUR ) {
      $highlight_colour = $highlight_colour->as_rgb;

      $convert_tags{bg} = sub ($k, $v) {
         return highlight => 1 if $highlight_colour->dst_rgb( $v ) <= 0.05;
         return ();
      };
   }

   return $class->SUPER::new_from_formatting( $orig,
      %args,
      convert_tags => \%convert_tags,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
