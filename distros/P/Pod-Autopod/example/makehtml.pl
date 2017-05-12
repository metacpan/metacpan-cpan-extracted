#!/usr/bin/perl


use Pod::Simple::HTMLBatch;
use strict;

my $output_dir='out/html';
my @search_dirs;
my $css='style.css';

push @search_dirs,'out/pod';



my $batchconv = Pod::Simple::HTMLBatch->new;

$batchconv->css_flurry(0);
$batchconv->add_css( $css );

$batchconv->batch_convert( \@search_dirs, $output_dir );


