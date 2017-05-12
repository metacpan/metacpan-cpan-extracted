#! /usr/local/bin/perl -w
# simple expample, add all files below t to the zip, but pretend relative to
# the t directory.

use strict;
use warnings;
use PANT;

StartPant();

my $zipper = Zip("xxx.zip");
$zipper->AddTree('t', '');
$zipper->Compression(0);
$zipper->Close();


EndPant();
