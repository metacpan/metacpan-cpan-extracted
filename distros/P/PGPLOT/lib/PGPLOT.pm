package PGPLOT;

use strict;
use warnings;
use Exporter;
use DynaLoader;

our $VERSION="2.35";

our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw( pgarro pgask pgaxis pgband pgbbuf pgbeg pgbegin pgbin pgbox
pgcirc pgclos pgconb pgconf pgconl pgcons pgcont pgconx pgctab pgcurs pgcurse pgdraw
pgebuf pgend pgenv pgeras pgerrb pgerr1 pgerrx pgerry pgetxt pgfunt pgfunx
pgfuny pggray pghi2d pghist pgiden pgimag pglab pglabel pglcur pgldev
pglen pgline pgmove pgmtxt pgmtext pgncur pgncurse pgnumb pgolin pgopen pgpage
pgadvance pgpanl pgpap pgpaper pgpixl pgpnts pgpoly pgpt pgpt1 pgpoint pgptxt
pgptext pgqah pgqcf pgqch pgqci pgqclp pgqcir pgqcol pgqcr pgqcs pgqdt pgqfs pgqhs
pgqid pgqinf pgqitf pgqls pgqlw pgqndt pgqpos pgqtbg pgqtxt pgqvp pgqvsz pgqwin
pgrect pgrnd pgrnge pgsah pgsave pgunsa pgscf pgsch pgsci pgscir pgsclp pgscr
pgscrl pgscrn pgsfs pgshls pgshs pgsitf pgslct pgsls pgslw pgstbg pgsubp pgsvp
pgvport pgswin pgwindow pgtbox pgtick pgtext pgupdt pgvect pgvsiz pgvsize
pgvstd pgvstand pgwedg pgwnad
pggapline pgcolorpnts
);

if($^O =~ /mswin32/i) {
  local $DynaLoader::dl_dlext = 'xs.dll';
  bootstrap PGPLOT $VERSION;
  }

else {bootstrap PGPLOT $VERSION}

# return OK status

1;

__DATA__

=head1 NAME

PGPLOT - allow subroutines in the PGPLOT graphics library to be called from Perl.

=head1 SYNOPSIS

 use PGPLOT;

 pgbegin(0,"/xserve",1,1);
 pgenv(1,10,1,10,0,0);
 pglabel('X','Y','My plot');
 pgpoint(7,[2..8],[2..8],17);

 # etc...

 pgend;

=head1 DESCRIPTION

This module provides an interface to the PGPLOT graphics library. To
obtain the library and its manual, see L</OBTAINING PGPLOT>.

For every PGPLOT function the module provides an equivalent Perl
function with the same arguments. Thus the user of the module should
refer to the PGPLOT manual to learn all about how to use PGPLOT and
for the complete list of available functions.  Note that PGPLOT is at
its heart a Fortran library, so the documentation describes the
Fortran interface.

Also refer to the extensive set of test scripts (F<t/t*.t>) included
in the module distribution for examples of usage of all kinds of
PGPLOT routines.

How the function calls map on to Perl calls is detailed below.

=head2 Argument Mapping - Simple Numbers And Arrays

This is more or less as you might expect - use Perl scalars
and Perl arrays in place of FORTRAN/C variables and arrays.

Any FORTRAN REAL/INTEGER/CHARACTER* scalar variable maps to a
Perl scalar (Perl doesn't care about the differences between
strings and numbers and ints and floats).

Thus you can say:

To draw a line to point (42,$x):

 pgdraw(42,$x);

To plot 10 points with data in Perl arrays C<@x> and C<@y> with plot symbol
no. 17. Note the Perl arrays are passed by reference:

 pgpoint(10, \@x, \@y, 17);

You can also use the old Perl4 style:

 pgpoint(10, *x, *y, 17);

but this is deprecated in Perl5.

Label the axes:

 pglabel("X axis", "Data units", $label);

Draw ONE point, see how when C<N=1> C<pgpoint()> can take a scalar as well as
a array argument:

  pgpoint(1, $x, $y, 17);


=head2 Argument Mapping - Images And 2d Arrays

Many of the PGPLOT commands (e.g. C<pggray>) take 2D arrays as
arguments. Several schemes are provided to allow efficient use
from Perl:

=over 4

=item 1.

Simply pass a reference to a 2D array, e.g:

  # Create 2D array

  $x=[];
  for($i=0; $i<128; $i++) {
     for($j=0; $j<128; $j++) {
       $$x[$i][$j] = sqrt($i*$j);
     }
  }
  pggray( $x, 128, 128, ...);

=item 2.

Pass a reference to a 1D array:

  @x=();
  for($i=0; $i<128; $i++) {
     for($j=0; $j<128; $j++) {
       $x[$i][$j] = sqrt($i*$j);
     }
  }
  pggray( \@x, 128, 128, ...);

Here @x is a 1D array of 1D arrays. (Confused? - see perldata(1)).
Alternatively @x could be a flat 1D array with 128x128 elements, 2D
routines such as C<pggray()> etc. are programmed to do the right thing
as long as the number of elements match.

=item 3.

If your image data is packed in raw binary form into a character string
you can simply pass the raw string. e.g.:

   read(IMG, $img, 32768);
   pggray($img, $xsize, $ysize, ...);

Here the C<read()> function reads the binary data from a file and the
C<pggray()> function displays it as a grey-scale image.

This saves unpacking the image data in to a potentially very large 2D
perl array. However the types must match. The string must be packed as a
C<"f*"> for example to use C<pggray>. This is intended as a short-cut for
sophisticated users. Even more sophisticated users will want to download
the C<PDL> module which provides a wealth of functions for manipulating
binary data.


I<Please Note>: As PGPLOT is a Fortran library it expects its images to be
be stored in row order. Thus a 1D list is interpreted as a sequence of
rows end to end. Perl is similar to C in that 2D arrays are arrays of
pointers thus images end up stored in column order.

Thus using perl multidimensional arrays the coordinate ($i,$j) should be
stored in $img[$j][$i] for things to work as expected, e.g:

   $img = [];
   for $j (0..$nx-1) for $i (0..$ny-1) {
      $$img[$j][$i] = whatever();
   }}
   pggray($$img, $nx, $ny, ...);

Also PGPLOT displays coordinate (0,0) at the bottom left (this is
natural as the subroutine library was written by an astronomer!).


=back

=head2 Argument Mapping - Function Names

Some PGPLOT functions (e.g. C<pgfunx>) take functions as callback
arguments. In Perl simply pass a subroutine reference or a name,
e.g.:

 # Anonymous code reference:

 pgfunx(sub{ sqrt($_[0]) },  500, 0, 10, 0);

 # Pass by ref:

 sub foo {
   my $x=shift;
   return sin(4*$x);
 }

 pgfuny(\&foo, 360, 0, 2*$pi, 0);

 # Pass by name:

 pgfuny("foo", 360, 0, 2*$pi, 0);


=head2 Argument Mapping - General Handling Of Binary Data

In addition to the implicit rules mentioned above PGPLOT now provides
a scheme for explicitly handling binary data in all routines.

If your scalar variable (e.g. C<$x>) holds binary data (i.e. 'packed')
then simply pass PGPLOT a reference to it (e.g. C<\$x>). Thus one can
say:

   read(MYDATA, $wavelens, $n*4);
   read(MYDATA, $spectrum, $n*4);
   pgline($n, \$wavelens, \$spectrum);

This is very efficient as we can be sure the data never gets copied
and will always be interpreted as binary.

Again see the L<PDL> module for sophisticated manipulation of
binary data, since it takes great advantage of these facilities.
See in particular L<PDL::Graphics::PGPLOT>.

Be VERY careful binary data is of the right size or your segments
might get violated.

=head1 DEBUGGING

As of 2.34, there is a C<PGPLOT::set_debugging> function (not
exported). It takes an integer argument, and returns the previous value.
When any PGPLOT function is called, if that level is >= 1, the name of
the function will be printed to standard error.

=head1 HISTORY

Originally developed in the olden days of Perl4 (when it was known
as 'pgperl' due to the necessity of making a special perl executable)
PGPLOT is now a dynamically loadable perl module which interfaces
to the FORTRAN graphics library of the same name.

=head1 OBTAINING PGPLOT

PGPLOT is a FORTRAN library with C bindings, While the Perl module
uses the latter, a FORTRAN compiler is still required to build the library.

The official library and the manual are available from
L<http://astro.caltech.edu/~tjp/pgplot/>

Building the library using the official distribution is arcane, tedious,
and error-prone. Additionally, the official distribution lacks a number
of bug fixes and additions provided by the community over the years.

A modern packaging (using the GNU autotools) of the more up-to-date
code base is available from L<https://bitbucket.org/djerius/pgplot-autotool/downloads>

The packaging has been tested on Linux and Mac OS X.

Source code is available at either of these sites

=over

=item L<https://github.com/djerius/pgplot-autotool>

=item L<https://bitbucket.org/djerius/pgplot-autotool/src>

=back

=head2 Cygwin

Build the pgplot library and install as above, but with these notes in mind.

Edit drivers.list to enable the drivers you wish but
uncommenting desired drivers by removing the leading ! on the
line. Here are the ones used by a previous PDL maintainer:

  $ grep -v '^!' drivers.list
    LXDRIV 0 /LATEX     LaTeX picture environment
    NUDRIV 0 /NULL      Null device (no output)                           Std F77
    PPDRIV 1 /PPM       Portable Pixel Map file, landscape
    PPDRIV 2 /VPPM      Portable PIxel Map file, portrait
    PSDRIV 1 /PS        PostScript printers, monochrome, landscape        Std F77
    PSDRIV 2 /VPS       Postscript printers, monochrome, portrait         Std F77
    PSDRIV 3 /CPS       PostScript printers, color, landscape             Std F77
    PSDRIV 4 /VCPS      PostScript printers, color, portrait              Std F77
    TTDRIV 5 /XTERM     XTERM Tektronix terminal emulator                 Std F77
    WDDRIV 1 /WD        X Window dump file, landscape
    WDDRIV 2 /VWD       X Window dump file, portrait
    XWDRIV 1 /XWINDOW   Workstations running X Window System              C
    XWDRIV 2 /XSERVE    Persistent window on X Window System              C

  $ vi sys_cygwin/g77_gcc.conf

  # This diff command shows the lines that need changing
  $ diff g77_gcc.conf*
  12c12
  <    XINCL="-I/usr/X11R6/include"
  ---
  >    XINCL="-I/usr/X11R6.4/include"
  48c48
  <    FFLAGD="-fno-backslash -I/usr/include"
  ---
  >    FFLAGD="-fno-backslash"
  58c58
  <    CFLAGC="-DPG_PPU -O2 -DNOMALLOCH -I. -I/usr/include"
  ---
  >    CFLAGC="-DPG_PPU -O2 -DNOMALLOCH -I."
  75c75
  <    LIBS="-L/usr/X11R6/lib -lX11 -lpng -lz"
  ---
  >    LIBS="-L/usr/X11R6.4/lib -lX11"

  $ ~/pgplot/makemake ~/pgplot cygwin
  $ make
  $ make clean
  $ make cpg
  $ PGPLOT_DIR="/usr/local/pgplot/"; export PGPLOT_DIR

Be sure to add C<PGPLOT_DIR> to your environment and add it to
your PATH as well.

NOTE: if problems occur, you may need to C<rebaseall> your libraries.

=head1 PNG OUTPUT

If PGPLOT does not write out PNG files, check these things.
First, when compiling the pgplot libraries, make sure you uncomment the PNG
entries in the F<drivers.list> file. Then when running 'make' you
probably got an error like

  C<make: *** No rule to make target `png.h', needed by `pndriv.o'.  Stop.>

To fix this, find the line in the 'makefile' that starts with
'pndriv.o:' (it's near the bottom). Change, for example, ./png.h to
/usr/include/png.h, if that is where your header files are (you do
have the libpng and libz devel packages, don't you?).  Do this for all
four entries on that line, then go back and run C<make>.

Second, if you already have the PGPLOT Perl module and PDL installed,
you probably tried to write out a PNG file and got fatal error message
like:

  C<undefined symbol: png_create_write_struct>

This is because the PGPLOT Perl module does not automatically link
against the png and z libraries. So when you are installing the PGPLOT
Perl module (version 2.19) from CPAN, don't do C<install PGPLOT>, but
just do C<get PGPLOT>. Then exit from CPAN and manually install
PGPLOT, calling the makefile thusly:

  C<perl Makefile.PL EXLIB=png,z EXDIR=/usr/lib>

assuming that there exist files such as /usr/lib/libpng.so.*,
/usr/lib/libz.so.*. Then do the standard C<make;make test;make
install;> sequence. Now you can write png files from PDL!

=head1 AUTHORS

Karl Glazebrook E<lt>kgb@aaoepp.aao.gov.auE<gt>
