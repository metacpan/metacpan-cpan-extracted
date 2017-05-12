#!/usr/bin/perl

use strict;
use Music::Scales;


my @maj = get_scale_notes('Eb');           # defaults to major
print join(" ",@maj),"\n";                 # "Eb F G Ab Bb C D Eb"
my @blues = get_scale_nums('bl');		   # 'bl','blu','blue','blues'
print join(" ",@blues),"\n";               # "0 3 5 6 7 10"
my %min = get_scale_offsets ('G','mm',1);  # descending melodic minor
print map {"$_=$min{$_} " } sort keys %min;# "A=0 B=-1 C=0 D=0 E=-1 F=0 G=0"

