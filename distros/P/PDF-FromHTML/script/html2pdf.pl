#!/usr/local/bin/perl
use strict;
use warnings;
use Getopt::Long;
use PDF::FromHTML;

=head1 NAME

html2pdf.pl - Convert HTML to PDF

=head1 SYNOPSIS

B<html2pdf.pl> S<[ B<-l> ]> S<[ B<-e> I<encoding> ] [ B<-f> I<font> ] [ B<-s> I<size> ]>
            S<I<input.html> [ I<output.pdf> ]>

If I<input.html> is not given, reads HTML from standard input.

If I<output.pdf> is not given, writes PDF to the same name as the input file
with an additional F<.pdf> suffix, or to standard output if it's being
redirected to somewhere other than a terminal.

If I<encoding> is not given, the input encoding defaults to C<utf-8>.

If I<font> is not given, the base font family defaults to C<Helvetica>.
The value of I<font> can be a truetype font file, one of the PDF core fonts,
or one of: C<traditional>/C<simplified>/C<korean>/C<japanese>.

If I<size> is not given, the base font size defaults to C<12> points.

If B<-l> is specified, the output uses landscape layout.

=cut

my $font      = 'Helvetica';
my $encoding  = 'utf-8';
my $size      = 12;
my $landscape = 0;
GetOptions(
    "e|encoding=s" => \$encoding,
    "f|font=s"     => \$font,
    "s|size=s"     => \$size,
    "l|landscape"  => \$landscape,
);

my $pdf = PDF::FromHTML->new(
    encoding => $encoding,
);

local $SIG{__DIE__} = sub { require Carp; Carp::confess(@_) };

my $input_file = @ARGV ? shift : '-';
my $output_file = @ARGV ? shift : (-t STDOUT and $input_file ne '-') ? "$input_file.pdf" : '-';

$pdf->load_file($input_file);
$pdf->convert(
    Font        => $font,
    LineHeight  => $size,
    Landscape   => $landscape,
);
#warn $pdf->twig->sprint;
$pdf->write_file($output_file);

1;

__END__

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2008 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
