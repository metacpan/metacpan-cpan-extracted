#!/usr/bin/perl
use strict;
use warnings;
my ($title);
while(<>) {
	if(0) { 1 }
	elsif(/^=for +literate:command +target=/)  { 1 }
	elsif(/^=for +literate +target:/)          { 1 } # deprecated
	elsif(/^=end\h+literate/)                   { undef($title) }
	elsif(/^=for\h+literate\h+\.\h*$/)          { undef($title) }
	elsif(/^=begin\h+literate\h+\+?(\H.*?)\h*$/) { $title=$1 }
	elsif(/^=for\h+literate\h+\+?(\H.*?)\h*$/)   { $title=$1 }
	elsif($title&&/^(\h*)\S/) { print "$1< $title >=\n$_"; undef($title) }
	else { print }
}

