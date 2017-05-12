# $Id: 04-boolean.t,v 1.1 2004/12/22 13:32:18 mike Exp $

use strict;

use IO::File;
use MARC::File::USMARC;

BEGIN {
    use vars qw(@tests $ntests);
    @tests = (
	      [ 'foo' => "12" ],
	      [ 'bar' => "23" ],
	      [ '@and foo bar' => "2" ],
	      [ '@or foo bar' => "123" ],
	      [ '@not foo bar' => "1" ],
	      [ '@not bar foo' => "3" ],
	      [ '@not @or foo bar @and foo bar' => "13" ],
	      [ '@not @and foo bar foo' => "" ],
	      [ '@not @and foo bar bar' => "" ],
	      );

    $ntests = 4 + scalar(@tests);
}

use Test::More tests => $ntests;
BEGIN { use_ok('Net::Z3950::IndexMARC') };

my $index = new Net::Z3950::IndexMARC();
ok(defined $index, "create index");

my $filename = "etc/boolean.marc";
my $file = MARC::File::USMARC->in($filename);
ok(defined $file, "open MARC file");
my $count = 0;
while (my $marc = $file->next()) {
    $index->add($marc);
    $count++;
}
$file->close();
ok(1, "added $count records to test-set");

foreach my $test (@tests) {
    my($query, $expected) = @$test;

    my $pqf = "\@attr 1=4 $query";
    my $hithash = $index->find($pqf);
    my $found = join("", sort { $a <=> $b } map { $_+1 } keys %$hithash);
    ok($found eq $expected,
       "$pqf found $found, expected $expected");
}
