#!/usr/bin/perl
use strict;
use warnings;

# Dumb weave, just attach the titles.

my ($title);
while(<>) {
	if   (/^=begin +literate +\+?(\S.*?)\s*$/) { $title=$1 }
	elsif(/^=for +literate:command +target=/)  { 1 }
	elsif(/^=for +literate +target:/)          { 1 }
	elsif(/^=for +literate +\.\s*$/)           { 1 }
	elsif(/^=for +literate +\+?(\S.*?)\s*$/)   { $title=$1 }
	elsif(/^=end +literate/)                   { 1 }
	elsif(/^\s*$/) { print }
	elsif($title&&/^(\s*)\S/) { print "$1< $title >=\n$_"; undef($title) }
	else { print }
}

