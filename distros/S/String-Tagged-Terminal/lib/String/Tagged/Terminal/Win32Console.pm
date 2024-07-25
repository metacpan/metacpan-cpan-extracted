#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package String::Tagged::Terminal::Win32Console 0.08;

use v5.14;
use warnings;

use Win32::Console;
use List::Util qw( max );

=head1 NAME

C<String::Tagged::Terminal::Win32Console> - Windows-specific code for L<String::Tagged::Terminal>

=head1 SYNOPSIS

   # No user serviceable parts inside
   use String::Tagged::Terminal;

=head1 DESCRIPTION

This module provides support for L<String::Tagged::Terminal> to print to the
console on C<MSWin32>. It is not intended to be used directly.

=cut

use constant {
   ATTR_BLUE          => 0x0001,
   ATTR_GREEN         => 0x0002,
   ATTR_RED           => 0x0004,
   ATTR_INTENSITY     => 0x0008,
   ATTR_REVERSE_VIDEO => 0x4000, # Windows 10 onwards
   ATTR_UNDERSCORE    => 0x8000, # Windows 10 onwards
};

# We can only ever allocate a single console on Windows
our $WIN32_CONSOLE;

my %color_to_attr; # a cache

sub print_to_console
{
   my $self = shift;
   my ( $fh, %opts ) = @_;

   # Convert filenos to native Win32 file handles, this should also try
   # Win32API::File::FdGetOsFHandle( $fh );
   my $fileno = {
       1 => Win32::Console::STD_OUTPUT_HANDLE(),
       2 => Win32::Console::STD_ERROR_HANDLE(),
   }->{ $fh->fileno } || $fh->fileno;

   my %output_options = (
      ( $opts{no_color} ? ( except => [qw( fgindex bgindex )] ) : () ),
      only => [qw( fgindex bgindex bold under reverse )], # only process what we can handle
   );

   if( $fileno < 0 ) {
      # This looks like a Perl-internal FH, let's not output any formatting
      $fh->print( $self->build_terminal( %opts ) );
   }
   else {
      my $console = $opts{console} || do { $WIN32_CONSOLE ||= Win32::Console->new( $fileno ); };
      my $saved = $console->Attr();
      my $attr = $saved;

      $self->iter_substr_nooverlap( sub {
         my ( $s, %tags ) = @_;

         # Simple boolean attributes first
         foreach (
            # bold is handled at the end
            [ under     =>  ATTR_UNDERSCORE ], # Rendering is flakey under Windows 10
            # Windows console doesn't support italic, strike, blink
            [ reverse   =>  ATTR_REVERSE_VIDEO ],
         ) {
            my ( $tag, $on ) = @$_;
            $attr &= ~$on;

            $attr |= $on if $tags{$tag};
         }

         # Colour index attributes
         foreach (
            [ fgindex => 0, ],
            [ bgindex => 4, ],
         ) {
            my ( $tag, $shift ) = @$_;
            my $mask = 0x000F << $shift;
            $attr &= ~$mask;

            if( defined $tags{$tag} ) {
               my $idx = $tags{$tag};
               $attr |= ( $color_to_attr{$idx} //= _color_to_attr( $idx ) ) << $shift;
            }
            else {
               # Restore to previous
               $attr |= $saved & $mask;
            }
         }

         $attr |= ATTR_INTENSITY if $tags{bold};

         $console->Attr($attr);
         $console->Write($s);
      }, %output_options );

      $console->Attr( $saved );
   }
}

sub _color_to_attr
{
   my ( $idx ) = @_;

   my $attr = 0;

   if( $idx >= 16 ) {
      # Attempt to convert xterm256 range into RGB+I
      require Convert::Color;
      my $color = Convert::Color->new( "xterm:$idx" )->as_rgb;

      my ( $red, $green, $blue ) = $color->rgb;
      my $max = max( $red, $green, $blue );

      $attr |= ATTR_RED   if $red   > 0.5;
      $attr |= ATTR_GREEN if $green > 0.5;
      $attr |= ATTR_BLUE  if $blue  > 0.5;
      $attr |= ATTR_INTENSITY if $max > 0.75;
      $attr = ATTR_INTENSITY if $attr == 0 and
         $red == $green and $red == $blue and $max > 0.25; # dark grey
   }
   else {
      # The bits are swapped between ANSI and Win32 console
      $attr |= ATTR_RED   if $idx & 1;
      $attr |= ATTR_GREEN if $idx & 2;
      $attr |= ATTR_BLUE  if $idx & 4;
      $attr |= ATTR_INTENSITY if $idx & 8;
   }
   return $attr;
}

=head1 COMPATIBILITY NOTES

On Windows before Windows 10, only C<fgindex>, C<bgindex> and C<bold> are supported.

Starting with Windows 10, also C<under> and C<reverse> are supported.

On Windows, only a single output console is supported.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>,
Max Maischein <corion@corion.net>

=cut

0x55AA;
