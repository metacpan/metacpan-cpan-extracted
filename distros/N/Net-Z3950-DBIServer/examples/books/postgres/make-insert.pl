#!/usr/bin/perl -w

# $Header: /home/mike/cvs/mike/zSQLgate/examples/books/postgres/make-insert.pl,v 1.2 2004-11-09 22:24:46 mike Exp $

use IO::File;
use strict;

foreach my $table (@ARGV) {
    my $filename = "../$table.data";
    my $fh = new IO::File("<$filename")
	or die "can't open '$filename': $!";
    process($table, $fh);
    $fh->close();
}

sub process {
    my($table, $fh) = @_;

    print STDERR "Generating data for table '$table'\n";
    my $names = nc_getline($fh);
    chomp($names);
    my @names = split /,/, $names;

    while (my $data = nc_getline($fh)) {
	chomp($data);
	my @fields = split /,/, $data;
	foreach my $field (@fields) {
	    my $q = "'";
	    $field =~ s/$q/''/g;
	    $field = "'$field'";
	}

	$names = join(",", @names[0..$#fields]);
	print "INSERT INTO $table($names) VALUES(", join(',', @fields), ");\n";
    }
}

sub nc_getline {
    my($fh) = @_;
    my $line;

    do {
	$line = $fh->getline();
    } while (defined $line && $line =~ /^#/);

    return $line;
}
