#!/usr/local/bin/perl -w
# create a SimpleCDB, populating it with some random data

use strict;

use SimpleCDB;	# exports as per Fcntl

my $records = shift || 1_000;
my $nfiles = shift || 16;

warn "$records records, $nfiles files\n";

$| = 1;

$SimpleCDB::DEBUG = $ENV{SIMPLECDBDEBUG};

# range of key,value chars
#my @d = map {chr($_)} 0x00..0xff;
#my @d = map {chr($_)} 0x09,0x0a,0x20..0x7e;
# mix 'em up a bit
#my @d = sort {int rand(3) - 1} map {chr($_)} 0x09,0x0a,0x20..0x7e;
my @d = map {chr($_)} 0x20..0x7e,0x20..0x7e;

my %h;
my $h;
$h = tie %h, 'SimpleCDB', 'db', O_RDWR|O_CREAT|O_TRUNC, 0, $nfiles
	or die "tie failed: $SimpleCDB::ERROR\n";

my $n = $records/80;
$n = 1 if $n < 1;
my $m = 0;
my $i;

for ($i = 0; $i < $records; $i++)
{
	my $j = $i % @d;
	my $k = $i;

# 	# testing for existance of a key in the SimpleCDB is quite expensive
# 	# - i.e. this is not recommended if you can do without it
# 	# - if duplicates are written to the SimpleCDB, only the first instance
# 	#   will ever be found
# 	die "key [$k] already exists!\n" if exists $h{$k};
# 	die "store: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;

	my $v = join '', (@d[$j..$#d], @d[0..($j-1)])[0..rand(@d)];

	# there's not much difference (time wise) in the following call methods:
	$h{$k} = $v;
	#$h->STORE($k, $v);
	#SimpleCDB::STORE($h, $k, $v);
	die "store: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;

	if ($i == int($m + 0.5)) { print '.'; $m += $n }
}

undef $h;
untie %h;	# release DB
print "\n";
