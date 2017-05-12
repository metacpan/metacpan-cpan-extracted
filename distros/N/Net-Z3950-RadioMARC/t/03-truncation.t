# $Id: 03-truncation.t,v 1.2 2004/12/21 16:41:50 mike Exp $

use strict;

use IO::File;
use MARC::File::USMARC;

BEGIN {
    use vars qw(@tests $ntests);
    @tests = (
	      [ 100, "no truncation",
		[
		 [ fruitbat => "1" ],
		 [ fruit => "2" ],
		 [ bat => "3" ],
		 [ uitba => "4" ],
		 [ rui => "" ],
		 ],
		],
	      [ 1, "right truncation",
		[
		 [ fruitbat => "1" ],
		 [ fruit => "12" ],
		 [ bat => "3" ],
		 [ uitba => "4" ],
		 [ rui => "" ],
		 ],
		],
	      [ 2, "left truncation",
		[
		 [ fruitbat => "1" ],
		 [ fruit => "2" ],
		 [ bat => "13" ],
		 [ uitba => "4" ],
		 [ rui => "" ],
		 ],
		],
	      [ 3, "left and right truncation",
		[
		 [ fruitbat => "1" ],
		 [ fruit => "12" ],
		 [ bat => "13" ],
		 [ uitba => "14" ],
		 [ rui => "12" ],
		 ],
		],
	      );

    $ntests = 4;
    foreach my $type (@tests) {
	my($attrval, $desc, $queries) = @$type;
	$ntests += scalar(@$queries);
    }
}

use Test::More tests => $ntests;
BEGIN { use_ok('Net::Z3950::IndexMARC') };

my $index = new Net::Z3950::IndexMARC();
ok(defined $index, "create index");

my $filename = "etc/trunc.marc";
my $file = MARC::File::USMARC->in($filename);
ok(defined $file, "open MARC file");
my $count = 0;
while (my $marc = $file->next()) {
    $index->add($marc);
    $count++;
}
$file->close();
ok(1, "added $count records to test-set");

foreach my $type (@tests) {
    my($attrval, $desc, $queries) = @$type;

    foreach my $qspec (@$queries) {
	my($query, $expected) = @$qspec;
	my $pqf = "\@attr 1=4 \@attr 5=$attrval $query";

	my $hithash = $index->find($pqf);
	my $found = join("", sort { $a <=> $b } map { $_+1 } keys %$hithash);
	ok($found eq $expected,
	   "$pqf ($desc) found $found, expected $expected");
    }
}
