#!/usr/bin/perl
# Feature: Hello World
# Description: Basic PDF creation showing minimal setup with a single line of text.
#              Demonstrates document creation, page setup, and text output.
# Output: corpus/feature_examples/01_basics/hello_world.pdf

use strict;
use warnings;
use lib 'lib';
use PDF::Make::Builder;

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/01_basics/hello_world',
);

$pdf->add_page(page_size => 'Letter')
    ->add_text(text => 'Hello, World!');

$pdf->save();
print "Created corpus/feature_examples/01_basics/hello_world.pdf\n";
