#!/usr/bin/perl

use Data::Dumper;
use lib './blib/lib';
use Rodney::XML::QuickStruct;
use Getopt::Std;

use strict;


my $opt = {};
getopts('s', $opt);



my $xml_file = shift;
die qq{USAGE: $0 file [tag_map_file]\n} unless (-f $xml_file);


##
##  Find a configuration file.

# Hint to the reader that wants to play with this API, try overloading the tag
# map file with other tag maps to see what happens.
my $tag_map_file;
if (@ARGV) {
    $tag_map_file = shift;
}
else {
    ($tag_map_file = $xml_file) =~ s/\.xml$/.tm/;
}

die qq{Invalid tag map file "$tag_map_file".\n} unless (-f $tag_map_file);


##
##  Use this distribution's package to get a configuration with.

# Here's a real-world example of how I use this.
my $tm_struct = Rodney::XML::QuickStruct::parse_file($tag_map_file, {tags => 'hash', title => 'scalar'});

die sprintf(
  qq{Failed to load tag map file:\n  [%s]\n},
  Rodney::XML::QuickStruct::error()
) if Rodney::XML::QuickStruct::error();



# The tag map to use for the actual XML file named.
my $tag_map = $tm_struct->{tags};
# An optional title that the tag map file may define.
my $title   = $tm_struct->{title} || qq{Output from file: "$xml_file"};


##
##  Process the actual XML file

# The object interface is my preference. If you have multiple sources to parse,
# then a new object for each will allow you to keep error handling separate and
# transient.
my $parser = Rodney::XML::QuickStruct->new(tag_map => $tag_map, sloppy => $opt->{s});
# Returning to a hash just to show that it's available. The hashref 
my %file_struct = $parser->parse_file($xml_file);

unless (%file_struct) {
    printf qq{Failed parse_file(), this may help:\n  %s\n},
      join("\n  ", $parser->error());

    exit 1;
}


# I've heard that you can write Fortran in any language.
my $c = '#';
my $b = ($c x (length($title)+8));
print qq{$b\n$c$c  $title  $c$c\n$b\n\n};


print Dumper(\%file_struct);

