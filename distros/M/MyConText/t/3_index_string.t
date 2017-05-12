
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..7\n";

use MyConText;
use Benchmark;

print "ok 1\n";


print "We will drop all the tables first\n";
for (qw! _ctx_test _ctx_test_data _ctx_test_words _ctx_test_docid !) {
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}

print "ok 2\n";

my $ctx;


print "Creating default MyConText index\n";
$ctx = MyConText->create($dbh, '_ctx_test',
	'frontend' => 'string') or print "$MyConText::errstr\nnot ";
print "ok 3\n";


print "Indexing documents\n";
my $t0 = new Benchmark;

$ctx->index_document('krtek', 'krtek leze');
$ctx->index_document('jezek', 'jezek leze taky');
$ctx->index_document('zirafa', 'zirafa ma dlouhej krk');
$ctx->index_document('jezek', 'jezek leze a ma bodliny');
$ctx->index_document('slon', 'slon mava chobotem');
$ctx->index_document('slon_krtek', 'slon mava s krtkem');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";


my (@docs, $expected);


print "Calling contains('krtek')\n";
@docs = sort($ctx->contains('krt%'));
$expected = 'krtek slon_krtek';
print "Documents containing `krt%': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";

print "Calling contains('ma')\n";
@docs = sort($ctx->contains('ma'));
$expected = 'jezek zirafa';
print "Documents containing `ma': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";

print "Calling contains('genius')\n";
my @notfound = $ctx->contains('genius');
print 'not ' if @notfound > 0;
print "ok 7\n";

