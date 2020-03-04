
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::IIS;

@EXPORT_OK  = qw(  iis iiscur iiscirc $stdimage $iisframe saoimage ximtool PDL::PP _iis PDL::PP _iiscirc );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::IIS ;





=head1 NAME

PDL::Graphics::IIS - Display PDL images on IIS devices (saoimage/ximtool)

=head1 SYNOPSIS

 use PDL::Graphics::IIS;
 saoimage ( -geometry => '800x800' );
 iis rvals(100,100);

=head1 DESCRIPTION

This module provides an interface to any image display 'device' which support the
'IIS protocol' - viz the SAOimage and Ximtool X-windows programs, the
old SunView imtool program and presumably even the original IIS CRT itself
if they aren't all in museums!

These programs should be familiar to astronomer's - they are used by
the common IRAF system. The programs and their HTML documentation
can be obtained from the following URLs:

 SAOimage: http://tdc-www.harvard.edu/software/saoimage.html
 Ximtool:  http://iraf.noao.edu/iraf/web/projects/x11iraf/x11iraf.html

Non-astronomer's may find they quite nifty for displaying 2D data.

The Perl variable C<$stdimage> is exported from the module and controls
the frame buffer configuration currently in use. The default value
is C<imt1024> which specifies a C<1024x1024> frame buffer. Other
values supported by the module are:
 
 imt512, imt800, imt1024, imt1600, imt2048, and imt4096.

If you have a F<$HOME/.imtoolrc> you can use it to specify other frame
buffer names and configurations in exactly the same way you can in
IRAF. Here is a sample file:

 -------------------snip-------------------------
 # Format:  configno nframes width height
  1  2  512  512         # imt1|imt512
  2  2  800  800         # imt2|imt800
  3  2 1024 1024         # imt3|imt1024
  4  1 1600 1600         # imt4|imt1600
  5  1 2048 2048         # imt5|imt2048
  6  1 4096 4096         # imt6|imt4096
  7  1 8192 8192         # imt7|imt8192
  8  1 1024 4096         # imt8|imt1x4
  9  2 1144  880         # imt9|imtfs    full screen (1152x900 minus frame)
 10  2 1144  764         # imt10|imtfs35 full screen at 35mm film aspect ratio
 -------------------snip-------------------------

(Note: some versions of SAOimage may not even work if this file is not
present. If you get funny error messages about 'imtoolrc' try copying
the above to F<$HOME/.imtoolrc> or F</usr/local/lib/imtoolrc>)

The Perl variable C<$iisframe> is also exported from the module and controls
which display frame number to use in programs such as Ximtool which supports
multiple frames. This allows you to do useful things such as blink between
images.

The module communicates with the IIS device down FIFO pipes (special UNIX
files) - unlike IRAF this module does a pretty decent job of intelligently
guessing which file names to use for the pipes and will prompt for their
creating if absent. Also if SAOimage or Ximtool are started from within Perl
using the module this will guarantee correct file names!

=head1 FUNCTIONS

=cut









use PDL::Core '';
use PDL::Basic '';
use Carp;

$iisframe      = 1;                # Starting defaults
$stdimage      = "imt1024";
$last_stdimage = "";
$HOME          = $ENV{'HOME'};     # Used a lot so shorten


################ Public routines #################

# Display

=head2 iis

=for ref

Displays an image on a IIS device (e.g. SAOimage/Ximtool)

=for usage

 iis $image, [ { MIN => $min, MAX => $max,
                 TITLE => 'pretty picture',
                 FRAME => 2 } ]
 iis $image, [$min,$max]

=for sig

 (image(m,n),[\%options]) or (image(m,n),[min(),max()])

Displays image on a IIS device. If C<min()> or C<max()> are omitted they
are autoscaled. A good demonstration of PDL threading can be had
by giving C<iis()> a data *cube* - C<iis()> will be repeatedly called
for each plane of the cube resulting in a poor man's movie!

If supplied, C<TITLE> is used to label the frame, if no title is
supplied, either the C<OBJECT> value stored in the image header or a
default string is used (the title is restricted to a maximum
length of 32 characters). 

To specify which frame to draw to, either use
the package variable C<$iisframe>, or the C<FRAME> option.

=cut

sub iis {
    my $usage = 'Usage: iis ( $image, [\%hash | $min, $max] )';
    barf $usage if $#_<0 || $#_>2;

    my $image  = shift;
    my ( $min, $max );

    my $title = 'perlDL rules !';
    my $header = $image->gethdr();
    if ( defined $header and defined $$header{OBJECT} ) {
      $title = $$header{OBJECT};
      $title =~ s/^'(.*)'$/$1/;
    }

    my $frame = $iisframe;
    if ( $#_ == 1 ) { $min = $_[0]; $max = $_[1]; }
    elsif ( $#_ == 0 ) {
      barf $usage unless ref($_[0]) eq "HASH";

      my $opt = new PDL::Options( { MIN => undef, MAX => undef, TITLE => $title, FRAME => $frame } );
      $opt->options( shift );
      my $options = $opt->current;

      $min   = $$options{MIN};
      $max   = $$options{MAX};
      $title = $$options{TITLE};
      $iisframe = $$options{FRAME};
    }

    my($nx,$ny) = dims($image);
    fbconfig($stdimage) if $stdimage ne $last_stdimage;
    $min = $image->min unless defined $min;
    $max = $image->max unless defined $max;
    print "Displaying $nx x $ny image in frame $iisframe from $min to $max ...\n" if $PDL::verbose;
    PDL::_iis($image,$min,$max,$title);
    $iisframe = $frame; # restore value
    1;
}

=head2 iiscur

=for ref

Return cursor position from an IIS device (e.g. SAOimage/Ximtool)

=for usage

 ($x,$y) = iiscur($ch)

This function puts up an interactive cursor on the IIS device and returns
the C<($x,$y)> position and the character typed (C<$ch>)
by the user.

=cut

sub iiscur {
    barf 'Usage: ($x,$y) = iiscur($ch)' if $#_>=1;
    my ($x,$y,$ch) = _iiscur_int();
    $_[0] = $ch; # Pass this back in args
    return ($x,$y);
}

=head2 iiscirc

=for ref

Draws a circle on a IIS device (e.g. SAOimage/Ximtool)

=for sig

 (x(),y(),radius(),colour())

=for usage

 iiscirc $x, $y, [$radius, $colour]

Draws circles on the IIS device with specified points and colours. Because
this module uses 
L<PDL::PP|PDL::PP> threading you can supply lists of points via
1D arrays, etc.

An amusing PDL idiom is:

 pdl> iiscirc iiscur

Note the colours are the same as IRAF, viz:

 201 = cursor color (white)
 202 = black
 203 = white
 204 = red
 205 = green
 206 = blue
 207 = yellow
 208 = cyan
 209 = magenta
 210 = coral
 211 = maroon
 212 = orange
 213 = khaki
 214 = orchid
 215 = turquoise
 216 = violet
 217 = wheat

=cut

sub iiscirc {
   barf 'Usage: iiscirc( $x, $y, [$radius, $colour] )' if $#_<1 || $#_>3;
   my($x, $y, $radius, $colour)=@_;
   fbconfig($stdimage) if $stdimage ne $last_stdimage;
   $radius = 10 unless defined $radius;
   $colour = 204 unless defined $colour;
   PDL::_iiscirc($x, $y, $radius, $colour);
   1;
}

=head2 saoimage

=for ref

Starts the SAOimage external program

=for usage

 saoimage[(command line options)]

Starts up the SAOimage external program. Default FIFO devices are chosen
so as to be compatible with other IIS module functions. If no suitable
FIFOs are found it will offer to create them.

e.g.:

=for example

 pdl> saoimage
 pdl> saoimage( -geometry => '800x800' )

=cut

sub saoimage {  # Start SAOimage
   fbconfig($stdimage) if $stdimage ne $last_stdimage;
   if( !($pid = fork)) {	# error or child
      exec("saoimage", -idev => $fifo, -odev => $fifi, @_) if defined $pid;
      die "Can't start saoimage: $!\n";
   }
   return $pid;
}

=head2 ximtool

=for ref

Starts the Ximtool external program

=for usage

 ximtool[(command line options)]

Starts up the Ximtool external program. Default FIFO devices are chosen
so as to be compatible with other IIS module functions. If no suitable
FIFOs are found it will offer to create them.

e.g.

=for example

 pdl> ximtool
 pdl> ximtool (-maxColors => 64)

=cut

sub ximtool {  # Start Ximtool
   fbconfig($stdimage) if $stdimage ne $last_stdimage;
   if( !($pid = fork)) {	# error or child
      exec("ximtool", -xrm => "ximtool*input_fifo: $fifi", -xrm => "ximtool*output_fifo: $fifo", @_) if defined $pid;
      die "Can't start ximtool: $!\n";
   }
   return $pid;
}


################ Private routines #################

# Change the frame buffer configuration

sub fbconfig {
    my $name = shift;
    parseimtoolrc() unless $parsed++;
    findfifo() unless $foundfifo++;
    barf 'No frame buffer configuration "'.$name.'" found'."\n"
       unless defined $imtoolrc{$name};
    ($fbconfig, $fb_x, $fb_y ) = @{ $imtoolrc{$name} };
    print "Using $stdimage - fbconfig=$fbconfig (${fb_x}x$fb_y)\n" if $PDL::verbose;;
    $last_stdimage = $stdimage;
1;}

# Try and find user/system imtoolrc definitions

sub parseimtoolrc {
   # assoc array holds imtool configuations - init with some standard
   # ones in case imtoolrc goes missing

   %imtoolrc = (
     'imt512'  => [1,512,512],   'imt800'  => [2,800,800],
     'imt1024' => [3,1024,1024], 'imt1600' => [4,1600,1600],
     'imt2048' => [5,2048,2048], 'imt4096' => [6,4096,4096],
   );

   # Look for imtoolrc file

   $imtoolrc = "/usr/local/lib/imtoolrc";
   $imtoolrc = "$HOME/.imtoolrc" if -e "$HOME/.imtoolrc";
   if (!-e $imtoolrc) {
      warn "WARNING: unable to find an imtoolrc file in $HOME/.imtoolrc\n".
           "or /usr/local/lib/imtoolrc. Will try \$stdimage = imt1024.\n";
      return 1;
   }

   # Load frame buffer configuartions from imtoolrc file and
   # store in assoc array

   open(IMTOOLRC, $imtoolrc) || die "File $imtoolrc not found";
    while(<IMTOOLRC>) {
       if  ( /^\s*(\d+)\s+\d+\s+(\d+)\s+(\d+)\s+\#\s*(\S+)\s/ ) {
          foreach $name (split(/\|/,$4)) {
             $imtoolrc{$name} = [$1,$2,$3];
          }
      }
   }close(IMTOOLRC);
1;}

# Try a few obvious places for the FIFO pipe and create if necessary

sub findfifo {
    $fifi = ""; $fifo = "";
    if (-e "/dev/imt1i" && -e "/dev/imt1o") {
       $fifi = "/dev/imt1i"; $fifo = "/dev/imt1o";
    }
    if (-e "$HOME/dev/imt1i" && -e "$HOME/dev/imt1o") {
       $fifi = "$HOME/dev/imt1i"; $fifo = "$HOME/dev/imt1o";
    }
    if (-e "$HOME/iraf/dev/imt1i" && -e "$HOME/iraf/dev/imt1o") {
       $fifi = "$HOME/iraf/dev/imt1i"; $fifo = "$HOME/iraf/dev/imt1o";
    }
    if (defined $ENV{'IMTDEV'} && $ENV{'IMTDEV'} =~ /^fifo:(.*):(.*)$/) {
       $fifi = $1; $fifo = $2;
   }
   if ($fifi eq "" && $fifo eq "") { # Still not found use this default
       warn "WARNING: cannot locate FIFO pipes in /dev/, $HOME/dev, ".
           "$HOME/iraf/dev or environment variable \$IMTDEV\n";
       $fifi = "$HOME/dev/imt1i"; $fifo = "$HOME/dev/imt1o";
   }
   print "Using FIFO devices in:  $fifi\n".
         "                   out: $fifo\n" if $PDL::verbose;
   for $pipe ($fifi, $fifo) {
      if (!-p $pipe) {
         print "FIFO $pipe does not exist - try and create now? "; my $ans = <STDIN>;
         system "/usr/etc/mknod $pipe p" if $ans =~ /^y/i;

         if ($ans =~ /^y/i) {
            unlink $pipe if -e $pipe;
            my $path = $ENV{PATH};
            $ENV{PATH} .= ":/etc:/usr/etc";

            # Note system return value is backwards - hence 'and'

            if ( system('mknod', $pipe, 'p') and system('mkfifo',$pipe) ) {
                die "Failed to create named pipe $pipe\n";
            }
            $ENV{PATH} = $path;
         }
      }
   }
1;}






*_iis = \&PDL::Graphics::IIS::_iis;





*_iiscirc = \&PDL::Graphics::IIS::_iiscirc;



;


=head1 BUGS

None known

=head1 AUTHOR

Copyright (C) Karl Glazebrook 1997.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut






# Exit with OK status

1;

		   