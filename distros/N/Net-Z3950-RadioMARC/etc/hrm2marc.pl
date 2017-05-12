#!/usr/bin/perl -w

# $Id: hrm2marc.pl,v 1.3 2004/12/21 15:37:56 mike Exp $
#
# Convert human-readable MARC records, such as those written out by
# the MARC::Record module's "marcdump" utility, into ISO 2709
# formatted records.  Reads the human-readable records on stdin and
# writes the formatted records on stdout.

use strict;
use warnings;
use MARC::Record;

my $rec = undef;
my $field = undef;

while (<>) {
    chomp();
    next if /^$/;
    next if /^#/;

    if (/^LDR /) {
	# Start of new record
	maybe_print($rec, $field);
	$rec = new MARC::Record;
	$field = undef;
	next;
    }

    my($tag, $i1, $i2, $subp, $sub, $value) = /^(...) (.)(.) (.)(.)(.*)/;
    $value = "$sub$value" if $subp eq " ";
    if ($tag eq "   ") {
	#print STDERR "field '", $field->tag(),"': adding $sub='",$value,"'\n";
	$field->add_subfields($sub, $value);
	next;
    }

    $rec->append_fields($field)
	if defined $field;
    if ($tag < 10) {
	#print STDERR "control field '$tag': setting '", $value, "'\n";
	$field = new MARC::Field($tag, $value);
    } else {
	#print STDERR "field '$tag': setting '$sub'='", $value, "'\n";
	$field = new MARC::Field($tag, $i1, $i2, $sub, $value);
    }
}

maybe_print($rec, $field);


sub maybe_print {
    my($rec, $field) = @_;

    die "maybe_print(): field defined but record not"
	if defined $field && !defined $rec;
    $rec->append_fields($field)
	if defined $field;
    print $rec->as_usmarc()
	if defined $rec;
}
