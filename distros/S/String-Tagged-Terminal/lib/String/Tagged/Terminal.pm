#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package String::Tagged::Terminal;

use strict;
use warnings;

use base qw( String::Tagged );

our $VERSION = '0.03';

=head1 NAME

C<String::Tagged::Terminal> - format terminal output using C<String::Tagged>

=head1 SYNOPSIS

 use String::Tagged::Terminal;

 my $st = String::Tagged::Terminal->new
    ->append( "Hello my name is " )
    ->append_tagged( $name, bold => 1, fgindex => 4 );

 $st->say_to_terminal;

=head1 DESCRIPTION

This subclass of L<String::Tagged> provides a method, C<build_terminal>,
for outputting the formatting tags embedded in the string as terminal escape
sequences, to render the the output in the appropriate style.

=head1 TAGS

The following tag names are recognised:

=head2 bold, under, italic, strike, blink, reverse

These tags take a boolean value. If the value is true then the corresponding
terminal rendering attribute is enabled.

=head2 altfont

This tag takes an integer value. If defined it uses the "alternate font
selection" sequence.

=head2 fgindex, bgindex

These tags take an integer value in the range 0 to 255. These select the
foreground or background colour by using VGA, high-brightness extended 16
colour, or xterm 256 palette mode attributes, depending on the value.

The ECMA-48-corrected string encoding form of C<CSI 38:5:nnn m> is used to set
the 256 palette values.

=cut

=head1 CONSTRUCTORS

=cut

=head2 new_from_formatting

   $st = String::Tagged::Terminal->new_from_formatting( $fmt )

Returns a new instance by converting L<String::Tagged::Formatting> standard
tags.

Foreground and background colours are converted to their nearest index in the
xterm 256 colour palette. The C<monospace> Formatting attribute is rendered by
selecting the first alternate font using C<altfont>.

=cut

sub new_from_formatting
{
   my $class = shift;
   my ( $orig ) = @_;

   require Convert::Color::XTerm;

   return $class->clone( $orig,
      only_tags => [qw(
         bold under italic strike blink reverse
         monospace
         fg bg
      )],
      convert_tags => {
         monospace => sub { $_[1] ? ( altfont => 1 ) : () },

         fg => sub { fgindex => $_[1]->as_xterm->index },
         bg => sub { bgindex => $_[1]->as_xterm->index },
      },
   );
}

=head1 METHODS

The following methods are provided in addition to those provided by
L<String::Tagged|String::Tagged/METHODS>.

=cut

=head2 build_terminal

   $str = $st->build_terminal( %opts )

Returns a string containing terminal escape sequences mixed with string
content to render the string to a terminal.

As this string will contain literal terminal control escape sequences, care
should be taken when passing it around, printing it for debugging purposes, or
similar.

Takes the following additional named options:

=over 4

=item no_color

If true, the C<fgindex> and C<bgindex> attributes will be ignored. This has
the result of performing some formatting using the other attributes, but not
setting colours.

=back

=cut

sub build_terminal
{
   my $self = shift;
   my %opts = @_;

   my $ret = "";
   my %pen;
   $self->iter_substr_nooverlap( sub {
      my ( $s, %tags ) = @_;

      my @sgr;

      # Simple boolean attributes first
      foreach (
         [ bold      =>  1, 21 ],
         [ under     =>  4, 24 ],
         [ italic    =>  3, 23 ],
         [ strike    =>  9, 29 ],
         [ blink     =>  5, 25 ],
         [ reverse   =>  7, 27 ],
      ) {
         my ( $tag, $on, $off ) = @$_;

         push( @sgr, $on  ), $pen{$tag} = 1    if  $tags{$tag} and !$pen{$tag};
         push( @sgr, $off ), delete $pen{$tag} if !$tags{$tag} and  $pen{$tag};
      }

      # Numerical attributes
      foreach (
         [ altfont => 10, 9 ],
      ) {
         my ( $tag, $base, $max ) = @$_;

         if( defined $pen{$tag} and !defined $tags{$tag} ) {
            push @sgr, $base;
            delete $pen{$tag};
         }
         elsif( defined $pen{$tag} and defined $tags{$tag} and $pen{$tag} == $tags{$tag} ) {
            # Leave it
         }
         elsif( defined $tags{$tag} ) {
            my $val = $tags{$tag};
            $val = $max if $val > $max;
            push @sgr, $base + $val;
            $pen{$tag} = $val;
         }
      }

      # Colour index attributes
      foreach (
         [ fgindex => 30 ],
         [ bgindex => 40 ],
      ) {
         my ( $tag, $base ) = @$_;

         if( defined $pen{$tag} and !defined $tags{$tag} ) {
            # Turn it off
            push @sgr, $base + 9;
            delete $pen{$tag};
         }
         elsif( defined $pen{$tag} and defined $tags{$tag} and $pen{$tag} == $tags{$tag} ) {
            # Leave it
         }
         elsif( defined $tags{$tag} ) {
            my $val = $tags{$tag};
            if( $val < 8 ) {
               # VGA 8
               push @sgr, $base + $val;
            }
            elsif( $val < 16 ) {
               # Hi 16
               push @sgr, $base + 60 + ( $val - 8 );
            }
            else {
               # Xterm256 palette 5 = 256 colours
               push @sgr, sprintf "%d:%d:%d", $base + 8, 5, $val;
            }
            $pen{$tag} = $val;
         }
      }

      if( @sgr and %pen ) {
         $ret .= "\e[" . join( ";", @sgr ) . "m";
      }
      elsif( @sgr ) {
         $ret .= "\e[m";
      }

      $ret .= $s;
   },
      ( $opts{no_color} ? ( except => [qw( fgindex bgindex )] ) : () ) );

   $ret .= "\e[m" if %pen;

   return $ret;
}

=head2 as_formatting

   $fmt = $st->as_formatting

Returns a new C<String::Tagged> instance tagged with
L<String::Tagged::Formatting> standard tags.

=cut

sub as_formatting
{
   my $self = shift;

   require Convert::Color::XTerm;

   return String::Tagged->clone( $self,
      only_tags => [qw(
         bold under italic strike blink reverse
         altfont
         fgindex bgindex
      )],
      convert_tags => {
         altfont => sub { $_[1] == 1 ? ( monospace => 1 ) : () },

         fgindex => sub { fg => Convert::Color::XTerm->new( $_[1] ) },
         bgindex => sub { bg => Convert::Color::XTerm->new( $_[1] ) },
      },
   );
}

=head2 print_to_terminal

   $str->print_to_terminal( $fh )

Prints the string to the terminal by building a terminal escape string then
printing it to the given IO handle (or C<STDOUT> if not supplied).

This method will pass the value of the C<NO_COLOR> environment variable to the
underlying L</build_terminal> method call, meaning if that has a true value
then colouring tags will be ignored, yielding a monochrome output. This
follows the suggestion of L<http://no-color.org/>.

=cut

sub print_to_terminal
{
   my $self = shift;
   my ( $fh ) = @_;

   $fh //= \*STDOUT;

   $fh->print( $self->build_terminal( no_color => $ENV{NO_COLOR} ) );
}

=head2 say_to_terminal

   $str->say_to_terminal( $fh )

Prints the string to the terminal as per L</print_to_terminal>, followed by a
linefeed.

=cut

sub say_to_terminal
{
   my $self = shift;
   my ( $fh ) = @_;

   $fh //= \*STDOUT;

   $self->print_to_terminal( $fh );
   $fh->say;
}

=head1 TODO

=over 4

=item *

Consider a C<< ->parse_terminal >> constructor method, which would attempt to
parse SGR sequences from a given source string.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
