#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2016 -- leonerd@leonerd.org.uk

package String::Tagged::IRC;

use strict;
use warnings;
use 5.010; #  //
use base qw( String::Tagged );
String::Tagged->VERSION( '0.11' ); # ->clone

our $VERSION = '0.03';

use Convert::Color::mIRC;
use Convert::Color::RGB8;

=head1 NAME

C<String::Tagged::IRC> - parse and format IRC messages using C<String::Tagged>

=head1 TAGS

This module provides the following tags, conforming to the
L<String::Tagged::Formatting> API specification.

=head2 bold, under, italic, reverse

Boolean values indicating bold, underline, italics, or reverse-video.

=head2 fg, bg

L<Convert::Color> objects encoding the color. These will likely be instances
of L<Convert::Color::mIRC>, unless a full RGB triplet colour code has been
provided; in which case it will be an instance of L<Convert::Color::RGB8>.

=cut

# IRC [well, technically mIRC but other clients have adopted it] uses Ctrl
# characters to toggle formatting
#  ^B = bold
#  ^U = underline
#  ^_ = underline
#  ^R = reverse or italic - we'll use italic
#  ^V = reverse
#  ^] = italics
#  ^O = reset
#  ^C = colour; followed by a code
#     ^C      = reset colours
#     ^Cff    = foreground
#     ^Cff,bb = background
#
# irssi uses the following
#  ^D$$ = foreground/background, in chr('0'+$colour),
#  ^Db  = underline
#  ^Dc  = bold
#  ^Dd  = reverse or italic - we'll use italic
#  ^Dg  = reset colours
#
# As a side effect we'll also strip all the other Ctrl chars

# We'll also look for "poor-man's" highlighting
#   *bold*
#   _underline_
#   /italic/

=head1 METHODS

=cut

=head2 $st = String::Tagged::IRC->parse_irc( $raw, %opts )

Parses a text string containing IRC formatting codes and returns a new
C<String::Tagged::IRC> instance.

Takes the following named options:

=over 8

=item parse_plain_formatting => BOOL

If true, also parse "poor-man's" plain-text formatting of B<*bold*>,
I</italic/> and _underline_. In this case, formatting tags are added but the
original text formatting is preserved.

=back

=cut

sub _parse_colour_mirc
{
   shift;
   my ( $colcode ) = @_;

   # RRGGBB hex triplet
   $colcode =~ m/^#([0-9a-f]{6})/i and
      return Convert::Color::RGB8->new( $1 );

   # RGB hex triplet
   $colcode =~ m/^#([0-9a-f])([0-9a-f])([0-9a-f])/i and
      return Convert::Color::RGB8->new( "$1$1$2$2$3$3" );

   # mIRC index
   $colcode =~ m/^(\d\d?)/ and $1 < 16 and
      return Convert::Color::mIRC->new( $1 );

   return undef;
}

my @termcolours =
   map { chomp; Convert::Color::RGB8->new( $_ ) } <DATA>;
close DATA;

sub _parse_colour_ansiterm
{
   shift;
   my ( $idx ) = @_;

   $idx >= 0 and $idx < @termcolours and
      return $termcolours[$idx];

   return undef;
}

sub parse_irc
{
   my $class = shift;
   my ( $text, %opts ) = @_;

   my $self = $class->new( "" );

   my %format;

   while( length $text ) {
      if( $text =~ s/^([\x00-\x1f])// ) {
         my $ctrl = chr(ord($1)+0x40);

         if( $ctrl eq "B" ) {
            $format{bold} ? delete $format{bold} : ( $format{bold} = 1 );
         }
         elsif( $ctrl eq "U" or $ctrl eq "_" ) {
            $format{under} ? delete $format{under} : ( $format{under} = 1 );
         }
         elsif( $ctrl eq "R" or $ctrl eq "]" ) {
            $format{italic} ? delete $format{italic} : ( $format{italic} = 1 );
         }
         elsif( $ctrl eq "V" ) {
            $format{reverse} ? delete $format{reverse} : ( $format{reverse} = 1 );
         }
         elsif( $ctrl eq "O" ) {
            undef %format;
         }
         elsif( $ctrl eq "C" ) {
            my $colourre = qr/#[0-9a-f]{6}|#[0-9a-f]{3}|\d\d?/i;

            if( $text =~ s/^($colourre),($colourre)// ) {
               $format{fg} = $self->_parse_colour_mirc( $1 );
               $format{bg} = $self->_parse_colour_mirc( $2 );
            }
            elsif( $text =~ s/^($colourre)// ) {
               $format{fg} = $self->_parse_colour_mirc( $1 );
            }
            else {
               delete $format{fg};
               delete $format{bg};
            }
         }
         elsif( $ctrl eq "D" ) {
            if( $text =~ s/^b// ) { # underline
               $format{under} ? delete $format{under} : ( $format{under} = 1 );
            }
            elsif( $text =~ s/^c// ) { # bold
               $format{bold} ? delete $format{bold} : ( $format{bold} = 1 );
            }
            elsif( $text =~ s/^d// ) { # revserse/italic
               $format{italic} ? delete $format{italic} : ( $format{italic} = 1 );
            }
            elsif( $text =~ s/^g// ) {
               undef %format
            }
            else {
               $text =~ s/^(.)(.)//;
               my ( $fg, $bg ) = map { ord( $_ ) - ord('0') } ( $1, $2 );
               if( $fg > 0 ) {
                  $format{fg} = $self->_parse_colour_ansiterm( $fg );
               }
               if( $bg > 0 ) {
                  $format{bg} = $self->_parse_colour_ansiterm( $bg );
               }
            }
         }
      }
      else {
         $text =~ s/^([^\x00-\x1f]+)//;
         my $piece = $1;

         # Now scan this piece for the text-based ones
         while( length $piece and $opts{parse_plain_formatting} ) {
            # Look behind/ahead asserts to ensure we don't capture e.g.
            # /usr/bin/perl by mistake
            $piece =~ s/^(.*?)(?<!\w)(([\*_\/])\w+\3)(?!\w)// or
               last;

            my ( $pre, $inner, $flag ) = ( $1, $2, $3 );

            $self->append_tagged( $pre, %format ) if length $pre;

            my %innerformat = %format;

            $innerformat{
               { '*' => "bold", '_' => "under", '/' => "italic" }->{$flag}
            } = 1;

            $self->append_tagged( $inner, %innerformat );
         }

         $self->append_tagged( $piece, %format ) if length $piece;
      }
   }

   return $self;
}

=head2 $raw = $st->build_irc

Returns a plain text string containing IRC formatting codes built from the
given instance. When outputting a colour index, this method always outputs it
as a two-digit number, to avoid parsing ambiguity if the coloured text starts
with a digit.

Currently this will only output F<mIRC>-style formatting, not F<irssi>-style.

Takes the following options:

=over 8

=item default_fg => INT

Default foreground colour to emit for extents that have only the C<bg> tag
set. This is required because F<mIRC> formatting codes cannot set just the
background colour without setting the foreground as well.

=back

=cut

sub build_irc
{
   my $self = shift;
   my %opts = @_;

   my $default_fg = $opts{default_fg} // 0;

   my $ret = "";
   my %formats;

   $self->iter_extents_nooverlap( sub {
      my ( $extent, %tags ) = @_;

      $ret .= "\cB" if !$formats{bold}    != !$tags{bold};
      $ret .= "\c_" if !$formats{under}   != !$tags{under};
      $ret .= "\c]" if !$formats{italic}  != !$tags{italic};
      $ret .= "\cV" if !$formats{reverse} != !$tags{reverse};
      $formats{$_} = $tags{$_} for qw( bold under italic reverse );

      my $fg = $tags{fg} ? $tags{fg}->as_mirc->index : undef;
      my $bg = $tags{bg} ? $tags{bg}->as_mirc->index : undef;

      if( ( $fg//'' ) ne ( $formats{fg}//'' ) or ( $bg//'' ) ne ( $formats{bg}//'' ) ) {
         if( defined $bg ) {
            # Can't set just bg alone, so if fg isn't defined, use the default
            $fg //= $default_fg;

            $ret .= sprintf "\cC%02d,%02d", $fg, $bg;
         }
         elsif( defined $fg ) {
            $ret .= sprintf "\cC%02d", $fg;
         }
         else {
            $ret .= "\cC";
         }
      }

      $formats{fg} = $fg;
      $formats{bg} = $bg;

      # TODO: colours

      $ret .= $extent->plain_substr;
   });

   # Be polite and reset colours at least
   $ret .= "\cC" if defined $formats{fg} or defined $formats{bg};

   return $ret;
}

sub new_from_formatted
{
   my $class = shift;
   my ( $orig ) = @_;

   return $class->clone( $orig,
      only_tags => [qw( bold under italic reverse fg bg )]
   );
}

sub as_formatted
{
   my $self = shift;
   return $self;
}

=head1 TODO

=over 4

=item *

Define a nicer way to do the ANSI terminal colour space of F<irssi>-style
formatting codes.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

# Palette used for irssi->RGB8 conversion

__DATA__
000000
aa0000
00aa00
aaaa00
0000aa
aa00aa
00aaaa
aaaaaa
999999
ff6666
66ff66
ffff66
6666ff
ff66ff
66ffff
ffffff
