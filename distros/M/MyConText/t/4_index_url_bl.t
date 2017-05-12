
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..16\n";

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


print "Creating MyConText index with url frontend\n";
$ctx = MyConText->create($dbh, '_ctx_test',
	'frontend' => 'url') or print "$MyConText::errstr\nnot ";
print "ok 3\n";

my %have = map { ( $_ => 0 ) }
		qw! root bash csh netscape perl gimp mycontext !;

if (open PASSWD, '/etc/passwd') {
	print "We will read the /etc/passwd to see what to expect.\n";
	while (<PASSWD>) {
		if (/\broot\b/) { $have{'root'} = 1; print "Have root.\n"; }
		if (/\bbash\b/) { $have{'bash'} = 1; print "Have bash.\n"; }
		if (/\bcsh\b/) { $have{'csh'} = 1; print "Have csh.\n"; }
		}
	close PASSWD;
	}

my %external = qw!
	http://www.netscape.com/	netscape
	http://www.perl.com/		perl
	http://www.gimp.com/		gimp
	file:MyConText.pm		mycontext
	!;

use LWP::Simple;
for my $url (keys %external) {
	if (head($url)) {
		$have{$external{$url}} = 1;
		print "$url has $external{$url}\n";
		}
	}

my $testnum = 3;

for my $url (sort(keys(%external), 'file://localhost/etc/passwd',
	'file:/etc/passwd')) {
	my $words = $ctx->index_document($url);
	$words = 'no words found' unless defined $words;
	print "$url: num of words: $words\n";
	$testnum++;
	print "ok $testnum\n";
	}

for my $word (sort(keys %have)) {
	my @docs = $ctx->contains($word);
	print "Word $word -> @docs\n";
	if ($have{$word} and not @docs) {
		print 'not ';
		}
	$testnum++;
	print "ok $testnum\n";
	}

