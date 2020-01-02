#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

no warnings 'deprecated'; ## no critic

use PDF::Builder;
use PDF::Builder::Resource::XObject::Image::JPEG;

my $pdf = PDF::Builder->new();
#my $image = PDF::Builder::Resource::XObject::Image::JPEG->new_api($pdf, 't/resources/1x1.jpg');

#ok($image, q{new_api still works});
ok($pdf, q{new_api removed});

1;
