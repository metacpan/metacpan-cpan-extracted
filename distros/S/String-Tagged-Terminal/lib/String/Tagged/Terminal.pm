#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2024 -- leonerd@leonerd.org.uk

package String::Tagged::Terminal 0.08;

use v5.14;
use warnings;

use base qw( String::Tagged );

use Carp;

use constant HAVE_MSWIN32 => $^O eq "MSWin32";
HAVE_MSWIN32 and require String::Tagged::Terminal::Win32Console;

require IO::Handle;

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

Values will be rounded down to the nearest integer by calling C<int()>. This
convenience allows things like the C<rand> function for generating random
colours:

   $st->append_tagged( "text", fgindex => 1 + rand 6 );

=head2 sizepos

I<Since version 0.06.>

(experimental)

This tag takes a value indicating an adjustment to the vertical positioning,
and possibly also size, in order to create subscript or superscript effects.

Recognised values are C<sub> for subscript, and C<super> for superscript.
These are implemented using the F<mintty>-style C<CSI 73/74/75 m> codes.

=head2 link

I<Since version 0.08.>

(experimental)

This tag takes a HASH reference, whose C<uri> key is emitted using the
C<OSC 8> hyperlink sequence.

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
         bold under italic strike blink reverse sizepos link
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

=head2 parse_terminal

   $st = String::Tagged::Terminal->parse_terminal( $str );

I<Since version 0.07.>

Returns a new instance by parsing a string containing SGR terminal escape
sequences mixed with plain string content.

The parser will only accept 7- or 8-bit encodings of the SGR escape sequence
(C<\e[ ... m> or C<\x9b ... m>). If any other escape sequences are present,
an exception is thrown.

Conversely, unrecognised formatting codes in SGR sequences are simply ignored
without warning.

=cut

my $CSI_args = qr/[0-9;:]*/;

sub parse_terminal
{
   my $class = shift;
   my ( $s ) = @_;

   my $self = $class->new;

   pos($s) = 0;

   my %tags;

   while( pos($s) < length($s) ) {
      if( $s =~ m/\G([^\e]+)/gc ) {
         $self->append_tagged( $1, %tags );
      }
      elsif( $s =~ m/\G\e\[($CSI_args)m/gc || $s =~ m/\G\x9b($CSI_args)m/gc ) {
         my $args = $1;
         length $args or $args = "0";
         foreach my $arg ( split m/;/, $args ) {
            my ( $a0, @arest ) = map { int $_ } split m/:/, $arg;

            # Reset
            if( $a0 == 0 ) { %tags = () }

            # Simple boolean attributes
            elsif( $a0 ==  1 ) { $tags{bold} = 1; }
            elsif( $a0 == 22 ) { delete $tags{bold}; }
            elsif( $a0 ==  4 ) { $tags{under} = 1; }
            elsif( $a0 == 24 ) { delete $tags{under}; }
            elsif( $a0 ==  3 ) { $tags{italic} = 1; }
            elsif( $a0 == 23 ) { delete $tags{italic}; }
            elsif( $a0 ==  9 ) { $tags{strike} = 1; }
            elsif( $a0 == 29 ) { delete $tags{strike}; }
            elsif( $a0 ==  5 ) { $tags{blink} = 1; }
            elsif( $a0 == 25 ) { delete $tags{blink}; }
            elsif( $a0 ==  7 ) { $tags{reverse} = 1; }
            elsif( $a0 == 27 ) { delete $tags{reverse}; }

            # Numerical attributes
            elsif( $a0 >= 10 && $a0 <= 19 ) {
               $a0 > 10 ? $tags{altfont} = $a0 - 10 : delete $tags{altfont};
            }

            # Colours
            elsif( $a0 >= 30 && $a0 <= 39 or $a0 >= 90 && $a0 <= 97 or
                   $a0 >= 40 && $a0 <= 49 or $a0 >= 100 && $a0 <= 107 ) {
               my $hi = $a0 >= 90 ? 8 : 0; $a0 -= 60 if $hi;
               my $attr = $a0 < 40 ? "fgindex" : "bgindex";
               $a0 %= 10;

               if   ( $a0 == 9 ) { delete $tags{$attr} }
               elsif( $a0 == 8 ) {
                  if( @arest >= 2 and $arest[0] == 5 ) {
                     $tags{$attr} = $arest[1];
                  }
                  # Else unrecognised
               }
               else              { $tags{$attr} = $a0 + $hi }
            }

            # Sub/superscript
            elsif( $a0 == 73 ) { $tags{sizepos} = "super"; }
            elsif( $a0 == 74 ) { $tags{sizepos} = "sub"; }
            elsif( $a0 == 75 ) { delete $tags{sizepos}; }

            # Else unrecognised
         }
      }
      elsif( $s =~ m/\G\e]8;/gc || $s =~ m/\G\x{9d}8;/gc ) {
         # OSC 8 hyperlink
         $s =~ m/\G.*?;/gc; # skip args

         $s =~ m/\G(.*?)\e\\/gc or $s =~ m/\G(.*?)\x07/gc or $s =~ m/\G(.*?)\x9c/gc or
            croak "Found an OSC 8 introduction that does not end with ST";

         length $1 ? $tags{link} = { uri => $1 }
                   : delete $tags{link};
      }
      else {
         croak "Found an escape sequence that is not SGR";
      }
   }

   return $self;
}

=head1 METHODS

The following methods are provided in addition to those provided by
L<String::Tagged|String::Tagged/METHODS>.

=cut

=head2 build_terminal

   $str = $st->build_terminal( %opts );

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
   my $osc8_uri;
   $self->iter_substr_nooverlap( sub {
      my ( $s, %tags ) = @_;

      my @sgr;

      # Simple boolean attributes first
      foreach (
         [ bold      =>  1, 22 ],
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
         my $val = $tags{$tag};
         $val = int $val if defined $val;

         if( defined $pen{$tag} and !defined $val ) {
            # Turn it off
            push @sgr, $base + 9;
            delete $pen{$tag};
         }
         elsif( defined $pen{$tag} and defined $val and $pen{$tag} == $val ) {
            # Leave it
         }
         elsif( defined $val ) {
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

      {
         if( defined $pen{sizepos} and !defined $tags{sizepos} ) {
            push @sgr, 75; # reset
            delete $pen{sizepos};
         }
         elsif( defined $pen{sizepos} and defined $tags{sizepos} and $pen{sizepos} eq $tags{sizepos} ) {
            # Leave it
         }
         elsif( defined( my $val = $tags{sizepos} ) ) {
            if( $val eq "sub" ) {
               push @sgr, 74;
            }
            elsif( $val eq "super" ) {
               push @sgr, 73;
            }
            $pen{sizepos} = $val;
         }
      }

      {
         my $link = $tags{link};
         my $uri  = $link ? $link->{uri} : undef;

         if( defined $osc8_uri and !defined $uri ) {
            $ret .= "\e]8;;\e\\";
            undef $osc8_uri;
         }
         elsif( defined $osc8_uri and defined $uri and $osc8_uri eq $uri ) {
            # leave it
         }
         elsif( defined $uri ) {
            $ret .= "\e]8;;" . ( $uri =~ s/[^[:print:]]//gr ) . "\e\\";
            $osc8_uri = $uri;
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
   $ret .= "\e]8;;\e\\" if defined $osc8_uri;

   return $ret;
}

=head2 as_formatting

   $fmt = $st->as_formatting;

Returns a new C<String::Tagged> instance tagged with
L<String::Tagged::Formatting> standard tags.

=cut

sub as_formatting
{
   my $self = shift;

   require Convert::Color::XTerm;

   return String::Tagged->clone( $self,
      only_tags => [qw(
         bold under italic strike blink reverse sizepos link
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

   $str->print_to_terminal( $fh );

I<Since version 0.03.>

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
   my ( $fh, %options ) = @_;

   $fh //= \*STDOUT;

   $options{win32}++ if HAVE_MSWIN32 and not exists $options{win32};

   if( $options{win32} ) {
      $self->String::Tagged::Terminal::Win32Console::print_to_console( $fh, %options );
   }
   else {
      $fh->print( $self->build_terminal( no_color => $ENV{NO_COLOR} ) );
   }
}

=head2 say_to_terminal

   $str->say_to_terminal( $fh );

I<Since version 0.03.>

Prints the string to the terminal as per L</print_to_terminal>, followed by a
linefeed.

=cut

sub say_to_terminal
{
   my $self = shift;
   my ( $fh, %options ) = @_;

   $fh //= \*STDOUT;

   $self->print_to_terminal( $fh, %options );
   $fh->say;
}

=head1 COMPATIBILITY NOTES

On Windows, the following notes apply:

=over 4

=item *

On all versions of Windows, the attributes C<bold>, C<fgindex> and C<bgindex>
are supported. The C<bold> attribute is implemented by using high-intensity
colours, so will be indistinguishable from using high-intensity colour indexes
without bold. The full 256-color palette is not supported by Windows, so it is
down-converted to the 16 colours that are.

=item *

Starting with Windows 10, also C<under> and C<reverse> are supported.

=item *

The attributes C<italic>, C<strike>, C<altfont>, C<blink> are not supported on
any Windows version.

=item *

On Windows, only a single output console is supported.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
