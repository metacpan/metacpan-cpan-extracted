#!/usr/bin/env perl 
use strict;
use List::Util qw(max);

#program  paste.pl, a tiny program to write in two columns two text files

if( @ARGV < 2) {    # is less than two arguments 
      print "usage: paste.pl filename1 filename2";
      exit 0;
}

# "$FIRSTFILE" is the name of the file handle
open(my $FIRSTFILE,$ARGV[0]) || die "Cannot open file \"$ARGV[0]\"";
my $format = max(map { length $_ } <$FIRSTFILE>);
close ($FIRSTFILE);

open($FIRSTFILE,$ARGV[0])  || die "Cannot open file \"$ARGV[0]\"";
open(my $SECONDFILE,$ARGV[1]) || die "Cannot open file \"$ARGV[1]\"";

my $sep = $ARGV[2] || ' | ';
while(my $line1 = <$FIRSTFILE>) {
    my $line2 = <$SECONDFILE>;
    $line2 = "" unless defined($line2);

    chomp($line1);  # removes the CR/LineFeed at the end
    my $whites = " "x($format-length($line1));
    print ${line1}, "$whites$sep${line2}";
}
close($FIRSTFILE);

my $whites = " "x$format;
while(my $line2 = <$SECONDFILE>) {
    print "$whites$sep${line2}";
}
close($SECONDFILE);
