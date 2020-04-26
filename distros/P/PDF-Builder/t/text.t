#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 7;

use PDF::Builder;

my $pdf = PDF::Builder->new();
my $page = $pdf->page();
my $text = $page->text();
my $font = $pdf->corefont('Helvetica');

$text->font($font, 12);
$text->text('Test Text');

my $width = $text->advancewidth('Test Text');
is($width, '49.956', 'Advance Width Check'); # was 50.016

$text->charspace(2);
is($text->charspace(), 2, 'Charspace is set');
$width = $text->advancewidth('Test Text');
is($width, '65.956', 'Advance width check with charspace added'); # was 66.016

$text->wordspace(4);
is($text->wordspace(), 4, 'Wordspace is set');
$width = $text->advancewidth('Test Text');
is($width, '69.956', 'Advance width check with wordspace added'); # was 70.016

# Check for death if text() is called without font()
$text = $page->text();
{
    local $@;
    eval { $text->text('This should die because no font has been set') };
    like($@,
         qr{Can't add text without first setting a font and font size},
         q{Call to text without a set font returns an informative error});

    # Call font(), but without setting a font size
    eval { $text->font($font); };
    like($@,
         qr{A font size is required},
         q{Call to text without a set font size returns an informative error});
}

1;
