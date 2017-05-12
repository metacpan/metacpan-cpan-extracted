
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..12\n";

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


print "Creating MyConText index with file frontend\n";
$ctx = MyConText->create($dbh, '_ctx_test',
	'frontend' => 'file') or print "$MyConText::errstr\nnot ";
print "ok 3\n";


my $DIR = 'test_data';
chdir $DIR or die "Cannot chdir to $DIR\n";

print <<EOF;
Indexing documents in directory $DIR, may take a while ...
  FYI, version 0.22 did these 19 files (4789 words) in
    12 wallclock secs ( 2.60 usr +  0.73 sys =  3.33 CPU)
  on my AMD 133 running Linux
EOF

use Benchmark;

my ($t0, $t1);
$t0 = new Benchmark;

my ($totfiles, $totwords) = (0, 0);
opendir DIR, '.';
my @files = sort grep { -f $_ } readdir DIR;
closedir DIR;
$| = 1;
for my $file (@files) {
	print "$file: ";
	if (defined (my $ret = $ctx->index_document($file))) {
		print "$ret\n";
		$totwords += $ret;
		$totfiles++;
		}
	else {
		print $ctx->errstr, "\n";
		}
	}
$t1 = new Benchmark;
print "Indexing of $totfiles files ($totwords words) took\n    ", timestr(timediff($t1, $t0)), "\n";

print "ok 4\n";

my (@docs, $expected);
print "Calling contains('while')\n";
@docs = sort($ctx->contains('while'));
print "Documents containing `while': @docs\n";
$expected = 'Index.modul Makefile Makefile.old Memo.modul MyConText.modul SQL.modul XBase.modul driver_characteristics dump';
print "expected $expected\nnot " unless "@docs" eq $expected;
print "ok 5\n";


print "Calling contains('genius')\n";
my @notfound = $ctx->contains('genius');
print 'not ' if @notfound > 0;
print "ok 6\n";


print "Calling contains('whi%')\n";
@docs = sort($ctx->contains('whi%'));
print "Documents containing `whi%': @docs\n";
$expected = 'Base.modul Changes Index.modul Makefile Makefile.old Memo.modul MyConText.modul SQL.modul XBase.modul driver_characteristics dump';
print "expected $expected\nnot " unless "@docs" eq $expected;
print "ok 7\n";

chdir '../test_data_empty' or die "Error chdirring to *_empty directory\n";
print "Remove document XBase.modul from index\n";
$t0 = new Benchmark;
if (not defined ($ctx->index_document('XBase.modul'))) {
	print $ctx->errstr, "\nnot ";
	}
print "ok 8\n";
$t1 = new Benchmark;
print 'Removing took ', timestr(timediff($t1, $t0)), "\n";


print "Calling contains('whi%')\n";
@docs = sort($ctx->contains('whi%'));
print "Documents containing `whi%': @docs\n";
$expected = 'Base.modul Changes Index.modul Makefile Makefile.old Memo.modul MyConText.modul SQL.modul driver_characteristics dump';
print "expected $expected\nnot " unless "@docs" eq $expected;
print "ok 9\n";


chdir "../$DIR" or die "Error chdirring back to $DIR\n";
print "Indexing the XBase.modul back\n";
$t0 = new Benchmark;
if (not defined $ctx->index_document('XBase.modul')) {
	print $ctx->errstr, "\nnot ";
	}
print "ok 10\n";
$t1 = new Benchmark;
print 'Reindexing took ', timestr(timediff($t1, $t0)), "\n";


print "Calling contains('whi%')\n";
@docs = sort($ctx->contains('whi%'));
print "Documents containing `whi%': @docs\n";
$expected = 'Base.modul Changes Index.modul Makefile Makefile.old Memo.modul MyConText.modul SQL.modul XBase.modul driver_characteristics dump';
print "expected $expected\nnot " unless "@docs" eq $expected;
print "ok 11\n";


print "Calling contains('zvirata')\n";
@docs = $ctx->contains('zvirata');
print "Documents containing `zvirata': @docs\n";
$expected = 'XBase.modul';
print "expected $expected\nnot " unless "@docs" eq $expected;
print "ok 12\n";


__END__

print <<EOF;
Benchmarking search for whi%, genius and krtek.
FYI, with version 0.18 the results were
    genius:  3 wallclock secs ( 1.70 usr +  0.16 sys =  1.86 CPU)
     krtek:  4 wallclock secs ( 2.16 usr +  0.14 sys =  2.30 CPU)
     while:  6 wallclock secs ( 2.90 usr +  0.19 sys =  3.09 CPU)
EOF

timethese(1000, { 'while' => sub { $ctx->contains('whi%') },
	'genius' => sub { $ctx->contains('genius') },
	'krtek' => sub { $ctx->contains('krtek') },
	});


