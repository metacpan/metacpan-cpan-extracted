#!/usr/bin/perl -w

# $Id: dbish.pl,v 1.8 2007-10-11 18:20:09 mike Exp $

# Run like this:
#	dbish.pl dbi:mysql:books user password
#	dbi> select book.id, book.name, author.name from book, author where book.author_id = author.id and book.name like 'The%'
#
#	dbish.pl dbi:Oracle:sblt SIESEARCH YcoyC60r603L1wdk1F50
#	dbi> select row_id, created, x_title_proper_uc from siebel.s_ins_claim
#
#	ORACLE_HOME=/home/oracle/app/oracle/product/9.2.0 PERL5LIB=/home/mike/universe/lib/perl:PERL5LIB LD_LIBRARY_PATH=/home/mike/universe/lib:$LD_LIBRARY_PATH dbish.pl 'dbi:Oracle:host=test;sid=test' mike ********

use strict;
use warnings;
use DBI;

if (@ARGV < 1) {
    print STDERR "Usage: $0: <data_source> [<username> <auth>]\n";
    exit 1;
}

my($data_source, $username, $auth) = @ARGV;
my %attr; # Should be settable using command-line options
my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
die "can't connect" if !defined $dbh;

$| = 1;
while (1) {
    print "dbi> ";
    my $line = readline(STDIN);
    last if !$line;
    chomp($line);
    my $aref  = $dbh->selectall_arrayref($line);
    next if !defined $aref;

    my $n = @$aref;
    print "=== $n results ===\n";

    my @width;
    foreach my $cref (@$aref) {
	foreach my $i (0 .. @$cref-1) {
	    my $len = length($cref->[$i]);
	    $width[$i] = $len if !defined $width[$i] || $len > $width[$i];
	}
    }

    foreach my $cref (@$aref) {
	foreach my $i (0 .. @$cref-1) {
	    print sprintf("%*s", -$width[$i], $cref->[$i]);
	    print $i == @$cref-1 ? "\n" : "  ";
	}
    }
}
