#!/usr/bin/perl

# PDF::Create sample usage

use strict; use warnings;
use PDF::Create;

my $pdf = new PDF::Create(
    'filename' => 'sample.pdf',
    'Version'  => 1.2,
    'PageMode' => 'UseOutlines',
    'Author'   => 'John Doe',
    'Title'    => 'Sample Document'
);

my $root = $pdf->new_page('MediaBox' => $pdf->get_page_size('a4'));

# Prepare 2 fonts
my $font1 = $pdf->font(
    'Subtype'  => 'Type1',
    'Encoding' => 'WinAnsiEncoding',
    'BaseFont' => 'Helvetica'
);
my $font2 = $pdf->font(
    'Subtype'  => 'Type1',
    'Encoding' => 'WinAnsiEncoding',
    'BaseFont' => 'Helvetica-Bold'
);

# Add a page which inherits its attributes from $root
my $page1 = $root->new_page;

# Prepare a Table of Content
my $toc = $pdf->new_outline('Title' => 'Sample Document');

# Add an entry to the outline
$toc->new_outline('Title' => 'Page 1', 'Destination' => $page1);

# Write some text to the page
$page1->stringc($font2, 40, 306, 426, 'PDF::Create');
$page1->stringc($font1, 20, 306, 396, "version $PDF::Create::VERSION");
$page1->stringc($font1, 20, 300, 300, 'Fabien Tassin');
$page1->stringc($font1, 20, 300, 250, 'Markus Baertschi (markus@markus.org)');

# Add another page
my $page2 = $root->new_page;
my $s2 = $toc->new_outline('Title' => 'Page 2', 'Destination' => $page2);
$s2->new_outline('Title' => 'GIF');
$s2->new_outline('Title' => 'JPEG');

# Draw a border around the page (A4 max is 595/842)
$page2->line(10,  10,  10,  832);
$page2->line(10,  10,  585, 10);
$page2->line(10,  832, 585, 832);
$page2->line(585, 10,  585, 832);

# Add a gif image
$page2->string($font1, 20, 50, 600, 'GIF Image:');
my $image1 = $pdf->image('pdf-logo.gif');
$page2->image('image'=>$image1, 'xscale'=>0.2, 'yscale'=>0.2, 'xpos'=>200, 'ypos'=>600);

# Add a jpeg image
$page2->string($font1, 20, 50, 500, 'JPEG Image:');
my $image2 = $pdf->image('pdf-logo.jpg');
$page2->image('image'=>$image2, 'xscale'=>0.2,'yscale'=>0.2, 'xpos'=>200, 'ypos'=>500);

# Wrap up the PDF and close the file
$pdf->close;
