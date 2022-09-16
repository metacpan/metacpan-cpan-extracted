#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;

# PDF::API2 changed header to 1.3, but PDF::Builder doesn't permit
# PDF::Builder will warn if PDF version is decreased

my $pdf = PDF::Builder->new('compress' => 0);  # default header 1.4, no trailer
$pdf->{'pdf'}->header_version('1.5');    # header says 1.5
$pdf->{'pdf'}->trailer_version('1.6');   # trailer says 1.6

is($pdf->version(), '1.6',   # trailer overrides header 1.6 vs 1.5
   q{version() returns whichever version is largest (1/2)});

$pdf->{'pdf'}->header_version('1.7');

is($pdf->version(), '1.7',   # header overrides trailer 1.7 vs 1.6
   q{version() returns whichever version is largest (2/2)});

$pdf->version('1.8');  # sets both header and trailer versions to 1.8

is($pdf->version(), '1.8',  # larger of H/T. then check individually
   q{version() is settable});

is($pdf->{'pdf'}->header_version(), '1.8',  # expect 1.8, set by version
   q{version() set header version});

is($pdf->{'pdf'}->trailer_version(), '1.8',  # expect 1.8, set by version
   q{version() set trailer version});

my $string = $pdf->to_string();

like($string, qr/%PDF-1.8/,
     q{Expected header version is present});

like($string, qr{/Version /1.8},
     q{Expected trailer version is present});

$pdf = PDF::Builder->new('compress' => 0);
$pdf->{'pdf'}->header_version('2.3');
$pdf->{'pdf'}->trailer_version('2.4');

# header 2.3, trailer 2.4, need 2.3 or higher so no change
my $version = $pdf->{'pdf'}->require_version('2.3');

is($version, '2.4',
   q{require_version returns current version});

$pdf->{'pdf'}->require_version('2.4');

is($pdf->{'pdf'}->header_version(), '2.3',
   q{require_version doesn't increase header version if trailer is sufficient});

# header 2.3, trailer 2.4, need 2.5 or higher so change both to 2.5
$version = $pdf->{'pdf'}->require_version('2.5');

is($pdf->version(), '2.5',
   q{require_version increases version when needed});

is($version, '2.4',
   q{require_version returns the previous version number});

#$pdf = PDF::Builder->new('compress' => 'none'); # version (header only) 1.4
#$pdf->version(1.3); # need to capture STDERR warning that version illegal
#is($pdf->version(), '1.4'); # should still be 1.4
#
#$pdf->version(1.6);
#$pdf->version(1.5); # need to capture STDERR warning that version drops
#is($pdf->version(), '1.5'); # should have dropped to 1.5

done_testing();

1;
