
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

BEGIN {
	use POSIX qw!locale_h!;
	setlocale(LC_CTYPE, 'cs');
	}

BEGIN {
	eval 'use Cz::Cstocs';
	if ($@) { print "1..0\nCouldn't find Cz::Cstocs filtering module.\n"; exit; }
	}


print "1..8\n";

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
	'frontend' => 'string',
	'init_env' => 'use Cz::Cstocs qw!il2_to_ascii!; use locale; ',
	'filter' => 'map { lc il2_to_ascii $_ }'
	) or print "$MyConText::errstr\nnot ";
print "ok 3\n";


print "Indexing documents\n";
my $t0 = new Benchmark;

$ctx->index_document('krtek', 'krtek leze');
$ctx->index_document('jezek', 'Je¾ek leze taky');
$ctx->index_document('zirafa', '®irafa má dlouhej krk');
$ctx->index_document('jezek', 'je¾eèek leze a má bodliny');
$ctx->index_document('slon', 'slon mává chobotem');
$ctx->index_document('slon_krtek', 'slon mává s krtkem');
$ctx->index_document('jezek_2', 'JE®EK LÉTÁ');

my $t1 = new Benchmark;
print "Indexing took ", timestr(timediff($t1, $t0)), "\n";
print "ok 4\n";


my (@docs, $expected);


print "Calling contains('krt%')\n";
@docs = $ctx->contains('krt%');
$expected = 'krtek slon_krtek';
print "Documents containing `krt%': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";

print "Calling contains('ma')\n";
@docs = $ctx->contains('ma');
$expected = 'jezek zirafa';
print "Documents containing `ma': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";

print "Calling contains('genius')\n";
my @notfound = $ctx->contains('genius');
print 'not ' if @notfound > 0;
print "ok 7\n";

print "Calling contains('jezek')\n";
@docs = $ctx->contains('jezek');
$expected = 'jezek_2';
print "Documents containing `jezek': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 8\n";

