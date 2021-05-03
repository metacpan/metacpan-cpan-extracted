#!/usr/bin/env perl

use warnings;
use strict;
use PDL;
use PDL::IO::Matlab;


my $f1 = 'Rep_Carlo_90nm.mat';
my $mat1 = PDL::IO::Matlab->new($f1, '<');
print "Matlab file format of $f1 is " . $mat1->get_version . "\n";
$mat1->print_all_var_info( print_data => 1 ) ;
$mat1->close;

my $f2 = 'testf_mat73.mat';
my $mat2 = PDL::IO::Matlab->new($f2, '>', { header => 'This is the header' });
$mat2->close;

$mat2 = PDL::IO::Matlab->new($f2, '<');
print "Matlab file format of $f2 is " . $mat2->get_version . "\n";
$mat2->close;

my $f3 = 'testf_mat5.mat';
my $mat3 = PDL::IO::Matlab->new($f3, '>', {format => 'MAT5'});
$mat3->close;

$mat3 = PDL::IO::Matlab->new($f3, '<');
print "Matlab file format of $f3 is " . $mat3->get_version . "\n";
$mat3->close;

my $f4 = 'test_mat73a.mat';
my $mat4 = PDL::IO::Matlab->new($f4, '>', {format => 'MAT73'});
$mat4->close;

$mat4 = PDL::IO::Matlab->new($f4, 'r');
print "Matlab file version of $f4 is " . $mat4->get_version . "\n";
print "Matlab file format of $f4 is " . $mat4->get_format . "\n";
$mat4->close;

print join('.',PDL::IO::Matlab::get_library_version()), "\n";

1;
