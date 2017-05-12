# $Id: 02-indexmarc.t,v 1.4 2004/12/22 17:40:15 mike Exp $

use strict;

use IO::File;
use MARC::File::USMARC;

BEGIN { use vars '$ntests'; $ntests = 18; }
use Test::More tests => $ntests;
BEGIN { use_ok('Net::Z3950::IndexMARC') };

my $index = new Net::Z3950::IndexMARC();
ok(defined $index, "create index");

my $filename = "etc/set.marc";
my $file = MARC::File::USMARC->in($filename);
ok(defined $file, "open MARC file");

SKIP: {
    skip("can't get MARC records: $!", $ntests-3)
	if !defined $file;

    while (my $marc = $file->next()) {
	$index->add($marc);
    }
    $file->close();
    ok(1, "indexed records");

    # It's hard to meaningfully test dumpindex
    my $tmpfile = "/tmp/dumpindex.$$";
    my $fh = new IO::File(">$tmpfile");
    ok(defined $fh, "open dumpindex file");

    SKIP: {
	skip("can't open dumpindex file '$tmpfile': $!", 3)
	    if !defined $fh;

	$index->dump($fh);
	$fh->close();
	ok(1, "dumped index");

	my @stat = stat($tmpfile);
#	unlink($tmpfile);
	SKIP: {
	    skip("can't stat dumpindex file '$tmpfile': $!", 2)
		if !@stat;

	    ok(1, "obtained index size");
	    ok($stat[7] == 144621, "checked index size");
	}
    }

    my $hithash = $index->find("center");
    ok(defined $hithash, "found 'center' records");
    my @recnum = sort { $a <=> $b } keys %$hithash;
    ok(scalar(@recnum) == 4, "counted 'center' records");
    ok(join(" ", @recnum) eq "4 19 20 21", "got right 'center' records");
    ok(istr($hithash->{4}) eq "260b:1 490a:4 810b:1",
       "record 4 indexing is as expected");
    ok(istr($hithash->{19}) eq "260b:10 710b:5",
       "record 19 indexing is as expected");
    ok(istr($hithash->{20}) eq "260b:10 710a:4",
       "record 20 indexing is as expected");
    ok(istr($hithash->{21}) eq "260b:15 710a:4",
       "record 21 indexing is as expected: ");

    my $marc = $index->fetch(4);
    ok($marc->subfield(260, "b") =~ /^center\b/i, "260b content");
    ok($marc->subfield(490, "a") =~ /^\S+\s+\S+\s+\S+\s+center\b/i,
       "490a content");
    # 810b is a list of two values in the record we're considering here
    my @multival = $marc->subfield(810, "b");
    ok($multival[1] =~ /^center\b/i, "810b content");
}


# Return a string summarising the indexing of an IndexMARC record
sub istr {
    my($aref) = @_;

    return join(" ", map { $_->[0] . $_->[1] . ":" . $_->[2] } @$aref)
}
