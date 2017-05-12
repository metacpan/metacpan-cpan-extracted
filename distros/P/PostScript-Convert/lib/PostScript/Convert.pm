#---------------------------------------------------------------------
package PostScript::Convert;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: November 9, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Use Ghostscript to convert PostScript or PDF to other formats
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.03';          ## no critic

use strict;
use warnings;
use Carp qw(croak verbose);
use File::Spec ();
use Scalar::Util qw(blessed openhandle reftype);


use Exporter 5.57 'import';     # exported import method

our @EXPORT = qw(psconvert);

#=====================================================================
# Package PostScript::Convert:

our $Debug;  # Set this to a true value for debugging output to STDERR

our %default = (
  ghostscript => ($^O =~ 'MSWin32' ? 'gswin32c.exe' : 'gs'),
);

our %format = do {
  my @png_param = (
    extension    => 'png',
    format_param => [qw(-dTextAlphaBits=4 -dGraphicsAlphaBits=4)],
  );

  my @pdf_param  = (
    device      => 'pdfwrite',
    extension   => 'pdf',
    format_code => [qw(-c .setpdfwrite)],
    'format_param' # => VALUE
  );

  (
    png     => { device => 'png16m',  @png_param },
    pnggray => { device => 'pnggray', @png_param },
    pngmono => { device => 'pngmono', extension => 'png' },
    jpeggray=> { device => 'jpeggray', extension => 'jpeg' },
    jpeg    => { device => 'jpeg', extension => 'jpeg' },
    jpg     => { device => 'jpeg', extension => 'jpg' },
    pdf14   => { @pdf_param => ['-dCompatibilityLevel=1.4'] },
    pdf13   => { @pdf_param => ['-dCompatibilityLevel=1.3'] },
    pdf12   => { @pdf_param => ['-dCompatibilityLevel=1.2'] },
  );
}; # end %format

$format{pdf} = $format{pdf14};

our %paper_size = (
  executive           => [522, 756],
  folio               => [595, 935],
  'half-letter'       => [612, 397],
  letter              => [612, 792],
  legal               => [612, 1008],
  tabloid             => [792, 1224],
  superb              => [843, 1227],
  ledger              => [1224, 792],

  'comm #10 envelope' => [297, 684],
  'envelope-monarch'  => [280, 542],
  'envelope-c5'       => [459.21260, 649.13386],
  'envelope-dl'       => [311.81102, 623.62205],

  a0  => [2383.93701, 3370.39370],
  a1  => [1683.77953, 2383.93701],
  a2  => [1190.55118, 1683.77953],
  a3  => [ 841.88976, 1190.55118],
  a4  => [ 595.27559,  841.88976],
  a5  => [ 419.52756,  595.27559],
  a6  => [ 297.63780,  419.52756],
  a7  => [ 209.76378,  297.63780],
  a8  => [ 147.40157,  209.76378],
  a9  => [ 104.88189,  147.40157],
  a10 => [  73.70079,  104.88189],

  b0  => [2834.64567, 4008.18898],
  b1  => [2004.09449, 2834.64567],
  b2  => [1417.32283, 2004.09449],
  b3  => [1000.62992, 1417.32283],
  b4  => [ 708.66142, 1000.62992],
  b5  => [ 498.89764,  708.66142],
  b6  => [ 354.33071,  498.89764],
  b7  => [ 249.44882,  354.33071],
  b8  => [ 175.74803,  249.44882],
  b9  => [ 124.72441,  175.74803],
  b10 => [  87.87402,  124.72441],
);

$paper_size{"us-$_"} = $paper_size{$_} for qw(letter legal);
$paper_size{europostcard} = $paper_size{a6};

#---------------------------------------------------------------------
sub psconvert
{
  my $ps = shift;

  unshift @_, 'filename' if @_ % 2;
  my %opt = (%default, @_);

  return convert_fh( openhandle $ps, \%opt) if openhandle $ps;
  return convert_object($ps, \%opt) if blessed $ps;
  return convert_ref(   $ps, \%opt) if ref $ps;
  convert_filename(     $ps, \%opt);
} # end psconvert

#---------------------------------------------------------------------
sub convert_object
{
  my ($obj, $opt) = @_;

  return convert_psfile($obj, $opt) if $obj->isa('PostScript::File');

  return convert_psfile($obj->get__PostScript_File, $opt)
      if $obj->can('get__PostScript_File');

  croak "Don't know how to handle a " . blessed($obj);
} # end convert_object


#---------------------------------------------------------------------
sub convert_psfile
{
  my ($ps, $opt) = @_;

  # Check version of PostScript::File:
  my $v = PostScript::File->VERSION;
  croak "Must have PostScript::File 2.00 or later, this is only $v"
      unless $v >= 2;


  # Get paper size, if necessary:
  $opt->{paper_size} ||= [ $ps->get_width, $ps->get_height ];

  # Save old filename:
  my $oldFN  = $ps->get_filename;
  $opt->{input} ||= "$oldFN.ps" if defined $oldFN;

  require File::Temp; File::Temp->VERSION(0.19); # need newdir method

  if ($ps->get_eps and $ps->get_pagecount > 1) {
    # Compute output filename:
    apply_format($opt);
    my ($outVol, $outDir, $outFN) =
        File::Spec->splitpath( guess_output_filename($opt) );

    $outFN =~ s/(\.\w+)$// or croak "No extension in $outFN";
    my $ext = $1;


    my $dir = File::Temp->newdir;

    my $oldExt = $ps->get_file_ext;
    $ps->set_filename($outFN, $dir);
    $ps->set_file_ext(undef);

    # Process the file(s):
    my @files = $ps->output;

    foreach my $fn (@files) {
      $outFN = (File::Spec->splitpath($fn))[2];
      $outFN =~ s/\.\w+$/$ext/ or die "Expected extension in $outFN";

      $opt->{filename} = File::Spec->catpath( $outVol, $outDir, $outFN );

      convert_filename($fn, $opt);
    } # end foreach $fn in @files

    # Restore settings:
    $ps->set_filename($oldFN);
    $ps->set_file_ext($oldExt);
  } # end if EPS with multiple pages
  else {
    # Only one file, we don't need a temporary directory:
    my $fh = File::Temp->new;

    $ps->output($fh);

    seek($fh, 0,0) or croak "Can't seek temporary file: $!";

    convert_fh($fh, $opt);
  } # end else only one PostScript file to process
} # end convert_psfile

#---------------------------------------------------------------------
sub convert_ref
{
  my ($ref, $opt) = @_;

  my $type = reftype $ref;

  croak "Don't know how to handle a $type ref"
      unless $type eq 'SCALAR' or $type eq 'ARRAY';


  require File::Temp;

  my $fh = File::Temp->new;

  if ($type eq 'ARRAY') { print $fh @$ref }
  else                  { print $fh $$ref }

  seek($fh, 0,0) or croak "Can't seek temporary file: $!";

  convert_fh($fh, $opt);
} # end convert_ref

#---------------------------------------------------------------------
sub convert_filename
{
  my ($filename, $opt) = @_;

  $opt->{input} ||= $filename;
  open(my $in, '<:raw', $filename) or croak "Unable to open $filename: $!";


  convert_fh($in, $opt);
} # end convert_filename

#---------------------------------------------------------------------
sub check_options
{
  my ($opt) = @_;

  my @cmd = ($opt->{ghostscript} || croak "ghostscript not defined");


  foreach my $dir (@{ $opt->{include} || [] }) {
    push @cmd, "-I$dir";
  } # end foreach $dir

  push @cmd, qw(-q -sstdout=%stderr -dBATCH -dNOPAUSE);
  push @cmd, ($opt->{unsafe} ? '-dNOSAFER' : '-dSAFER');

  apply_format($opt);

  push @cmd, "-sOutputFile=" . guess_output_filename($opt);

  my $device = $opt->{device};
  croak "No output device supplied" unless defined $device and length $device;
  push @cmd, "-sDEVICE=$device";

  if (defined(my $size = $opt->{paper_size})) {
    unless (ref $size) {
      if ($paper_size{lc $size}) {
        $size = $paper_size{lc $size};
      } elsif ($size =~ /\A(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)\Z/i) {
        $size = [ $1 * 72, $2 * 72 ];
      } else {
        croak "Unknown paper size '$size'";


      }
    } # end unless ref $size
    push @cmd, '-dDEVICEWIDTHPOINTS='  . $size->[0],
               '-dDEVICEHEIGHTPOINTS=' . $size->[1];
  } # end if $opt->{paper_size}

  push @cmd, "-r$opt->{resolution}"    if $opt->{resolution};
  push @cmd, @{ $opt->{format_param} } if $opt->{format_param};
  push @cmd, @{ $opt->{gs_param} }     if $opt->{gs_param};
  push @cmd, @{ $opt->{format_code} }  if $opt->{format_code};

  print STDERR "@cmd\n" if $Debug;

  @cmd;
} # end check_options

#---------------------------------------------------------------------
sub apply_format
{
  my ($opt) = @_;

  unless ($opt->{format}) {
    my $outFN = $opt->{filename};

    croak "No output format or filename supplied"
        unless defined $outFN and length $outFN;

    $outFN =~ /\.([^.\s]+)$/ or croak "Unable to determine format from $outFN";
    $format{ $opt->{format} = lc $1 } or croak "Unknown extension .$1";
  }

  my $fmt = $format{ $opt->{format} } or croak "Unknown format $opt->{format}";


  while (my ($key, $val) = each %$fmt) {
    $opt->{$key} = $val unless defined $opt->{key};
  }
} # end apply_format

#---------------------------------------------------------------------
sub guess_output_filename
{
  my ($opt) = @_;

  my $fn = $opt->{filename};

 CHOICE: {
    last CHOICE if defined $fn;

    $fn = $opt->{input};
    last CHOICE unless defined $fn and length $fn;

    my $ext = $opt->{extension};
    croak "No extension defined for format $opt->{format}" unless $ext;

    $fn =~ s/(?:\.\w*)?$/.$ext/;
  }


  croak "No output filename supplied" unless defined $fn and length $fn;

  $fn;
} # end guess_output_filename

#---------------------------------------------------------------------
sub convert_fh
{
  my ($fh, $opt) = @_;

  my @cmd = (check_options($opt), '-_');

  open(my $oldin, '<&STDIN') or croak "Can't dup STDIN: $!";
  open(STDIN, '<&', $fh)     or croak "Can't redirect STDIN: $!";
  system @cmd;
  open(STDIN, '<&', $oldin)  or croak "Can't restore STDIN: $!";


  if ($?) {
    my $exit   = $? >> 8;
    my $signal = $? & 127;
    my $core   = $? & 128;

    my $err = "Ghostscript failed: exit status $exit";
    $err .= " (signal $signal)" if $signal;
    $err .= " (core dumped)"    if $core;

    croak $err;
  } # end if ghostscript failed
} # end convert_fh

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

PostScript::Convert - Use Ghostscript to convert PostScript or PDF to other formats

=head1 VERSION

This document describes version 0.03 of
PostScript::Convert, released March 15, 2014.

=head1 SYNOPSIS

    use PostScript::Convert;

    psconvert($filename, $output_filename);

    # Base output filename on input filename:
    psconvert($filename, format => 'pdf');

    my $postscript = "%!PS-Adobe-3.0 ...";
    psconvert(\$postscript, $output_filename);

    my $ps = PostScript::File->new;
    $ps->add_to_page(...);
    psconvert($ps, filename => $output_filename, format => 'pnggray');

=head1 DESCRIPTION

PostScript::Convert uses Ghostscript to convert PostScript or PDF to other
formats.  You will need to have Ghostscript installed.

It exports a single function:

=head2 psconvert

  psconvert($input, [$output_filename], [options...])

This takes the PostScript code or PDF file pointed to by C<$input> and processes
it through Ghostscript.  The return value is not meaningful.  It
throws an exception if an error occurs.

=head3 Input specifications

C<$input> must be one of the following:

=over

=item A string

This is interpreted as a filename to open.

=item A scalar reference

This must be a reference to a string containing a PostScript document.

=item An array reference

This must be a reference to an array of strings, which when joined
together form a PostScript document.  No newlines are added when joining.

=item An open filehandle

Any argument accepted by L<Scalar::Util/openhandle> is interpreted as
a filehandle to read from.

=item A PostScript::File object

Note: in C<eps> mode, this will generate multiple output files if the
document has multiple pages.

=item Any other object

The object must implement a C<get__PostScript_File> method that
returns a PostScript::File object.
(Note: there are 2 underscores after C<get>)

=back

=head3 Output options

The remaining arguments after C<$input> are key-value pairs that
control the output.  If there are an odd number of arguments following
C<$input>, then the first one is the C<filename>.

Options added since version 0.01 are marked with the
version they were added in (e.g. "(v0.02)").

=over

=item C<filename>

This is the output filename.  If omitted, it will be calculated from
C<input> and C<format>.

=item C<format>

This is the output format.  If omitted, it will be taken from the
extension of C<filename>.  Accepted formats are:

=over

=item C<png>

24-bit color PNG

=item C<pnggray>

8-bit grayscale PNG

=item C<pngmono>

1-bit monochrome PNG

=item C<pdf>

The preferred PDF version (currently 1.4, but subject to change).

=item C<pdf14>

PDF version 1.4 (Acrobat 5.0 - 2001)

=item C<pdf13>

PDF version 1.3 (Acrobat 4.0 - 1999)

=item C<pdf12>

PDF version 1.2 (Acrobat 3.0 - 1996)

=item C<jpg>

(v0.03) color JPEG with default extension .jpg
(Note: JPEG encoding is not recommended.  It's designed for
photo-realistic images, not the text and line art more commonly found
in PostScript files.)

You can control the compression quality by using
S<C<< gs_param => ['-dJPEGQ=N'] >>> (where N is an integer from 0 to 100).
The default depends on your Ghostscript, but is usually 75.

=item C<jpeg>

(v0.03) color JPEG with default extension .jpeg

=item C<jpeggray>

(v0.03) grayscale JPEG with default extension .jpeg

=back

=item C<ghostscript>

This is the Ghostscript executable to use.  It defaults to C<gs>,
except on Microsoft Windows, where it is C<gswin32c.exe>.
(You may use a pathname here.)

=item C<include>

An arrayref of directories to add to Ghostscript's search path (for
advanced users only).

=item C<input>

This is the input filename.  (This is used only for calculating
C<filename> when necessary.  It does not mean to actually read from
this file, and it need not exist on disk.)  If omitted, it will be
taken from C<$input> (if that is a filename or a PostScript::File
object containing a filename).

=item C<paper_size>

(v0.02) The desired output paper size.  This can be a string
indicating a known L<paper size|/"Paper Sizes">, a string of the form
C<WIDTHxHEIGHT> (where WIDTH and HEIGHT are in inches), or an arrayref
of two numbers S<C<[ WIDTH, HEIGHT ]>> (where WIDTH and HEIGHT are in
points).  If omitted, Ghostscript will use its default paper size,
unless you pass a PostScript::File object (or an object that supplies
a PostScript::File), in which case the paper size will be taken from
that object.

=item C<resolution>

(v0.02) The desired output resolution in pixels per inch.  This is
either a string of two integers separated by C<x> (C<XRESxYRES>) or a
single integer (if the X and Y resolution should be the same).
(Passed to C<gs> as its C<-r> option.)

=item C<device>

The Ghostscript device to use (for advanced users only).  This is
normally set automatically from the C<format>.

=item C<gs_param>

An arrayref of additional parameters to pass to Ghostscript (for
advanced users only).

=item C<unsafe>

Ghostscript is normally run with C<-dSAFER>, which prevents the
PostScript code from accessing the filesystem.  Passing
S<C<< unsafe => 1 >>> will use C<-dNOSAFER> instead.  Don't do this
unless you trust the PostScript code you are converting.

=back

=head2 Paper Sizes

Paper sizes are not case sensitive.  These are the known sizes:
"comm #10 envelope", "envelope-c5", "envelope-dl", "envelope-monarch", europostcard, executive, folio, "half-letter", ledger, legal, letter, superb, tabloid, "us-legal", "us-letter", A0 - A10, B0 - B10.

=head1 DIAGNOSTICS

=over

=item C<< Can't %s STDIN: %s >>

There was an error while redirecting STDIN in order to run Ghostscript.


=item C<< Can't seek temporary file: %s >>

A seek failed for the specified reason.


=item C<< Don't know how to handle a %s >>

You passed an object that psconvert doesn't accept as C<$input>.


=item C<< Don't know how to handle a %s ref >>

psconvert only accepts a scalar or array reference as C<$input>.


=item C<< Expected extension in %s >>

The temporary filename created by PostScript::File must have an
extension, but it didn't.


=item C<< Ghostscript failed: exit status %s >>

Ghostscript did not exit successfully.  The exit status is reported as
a decimal number (C<<< $? >> 8 >>>),
followed by " (signal %d)" if C<< $? & 127 >> is non-zero,
followed by " (core dumped)" if C<< $? & 128 >>.


=item C<< ghostscript not defined >>

The C<ghostscript> option was somehow unset.  This shouldn't happen,
since it has a default value.


=item C<< Must have PostScript::File 2.00 or later, this is only %s >>

PostScript::Convert isn't directly compatible with versions of
PostScript::File older than 2.00.  (If you can't upgrade
PostScript::File, then you can write the PostScript to a file and pass
that file to psconvert.)


=item C<< No extension defined for format %s >>

The specified C<format> failed to define a file extension.


=item C<< No extension in %s >>

The output filename must have a file extension.


=item C<< No output device supplied >>

The C<device> option (which normally comes from the C<format>) was not set.


=item C<< No output filename supplied >>

You didn't specify an output filename, nor did you provide an input
filename to guess it from.


=item C<< No output format or filename supplied >>

You didn't specify the C<format> option, nor did you supply an output
filename from which to guess it.


=item C<< Unable to determine format from %s >>

You didn't specify the C<format> option, and the output filename you
supplied doesn't match any known format.


=item C<< Unable to open %s: %s >>

Opening the specified file failed for the specified reason.


=item C<< Unknown format %s >>

The C<format> you specified is not valid.


=item C<< Unknown paper size %s >>

The C<paper_size> you specified is not valid.


=back

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::Convert expects to find a Ghostscript executable somewhere
on your C<$ENV{PATH}>.  (See the C<ghostscript> option for details.)

=head1 DEPENDENCIES

PostScript::Convert depends on L<Carp>, L<Exporter>, L<File::Spec>,
L<File::Temp>, and L<Scalar::Util>.  All of these are core modules,
but you may need to install a newer version of File::Temp.

It also requires you to have Ghostscript
(L<http://pages.cs.wisc.edu/~ghost/>) installed somewhere on your
PATH, unless you use the C<ghostscript> option to specify its
location.

=head1 INCOMPATIBILITIES

PostScript::Convert is not compatible with versions of
PostScript::File older than 2.00.  (However, you could have an older
version of PostScript::File write the PostScript to a file, and then
pass that file to C<psconvert>.)

=for Pod::Coverage
apply_format
check_options
convert_.+
guess_output_filename

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-Convert AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-Convert >>.

You can follow or contribute to PostScript-Convert's development at
L<< https://github.com/madsen/postscript-convert >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
