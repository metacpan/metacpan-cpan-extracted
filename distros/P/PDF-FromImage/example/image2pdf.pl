#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, qw/.. lib/ );

use PDF::FromImage;

GetOptions(
    \my %option,
    qw/help output=s/
);
pod2usage(0) if $option{help};
pod2usage(1) unless $option{output} and scalar @ARGV;

my $pdf = PDF::FromImage->new;
$pdf->load_images(@ARGV);
$pdf->write_file($option{output});

=head1 NAME

image2pdf.pl - convert images to pdf

=head1 SYNOPSIS

image2pdf.pl -o output.pdf images...

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut

