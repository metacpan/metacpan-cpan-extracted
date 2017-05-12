#!/usr/bin/perl

use strict; use warnings;
use PDF::Create;
use File::Temp qw/tempfile/;
use Test::More tests => 2;

my $get_filename = sub {
    my ($filehandle, $filename) = tempfile();
    return $filename;
};

my $get_filehandle = sub {
    my $filehandle = tempfile();
    return $filehandle;
};

my $pdf_with_filename   = create_pdf({ 'filename' => $get_filename->()   });
my $pdf_with_filehandle = create_pdf({ 'fh'       => $get_filehandle->() });

$pdf_with_filename->close();
ok(!defined fileno($pdf_with_filename->{fh}), 'pdf with filename not closed properly');

$pdf_with_filehandle->close();
ok(defined fileno($pdf_with_filehandle->{fh}), 'pdf with filehandle should not be closed');

sub create_pdf {
    my ($args) = @_;

    my $pdf  = PDF::Create->new(%$args);
    my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('A4'));
    my $font = $pdf->font('Encoding' => 'WinAnsiEncoding');
    my $page = $root->new_page;
    $page->stringc($font, 40, 306, 700, 'PDF::Create');

    return $pdf;
}
