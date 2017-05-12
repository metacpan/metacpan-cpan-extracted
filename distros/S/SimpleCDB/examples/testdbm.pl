#!/usr/local/bin/perl -w

use strict;

{ package P; use POSIX; }
use Fcntl;

my $dbtype;
BEGIN { $dbtype = 'NDBM_File' }
eval "use $dbtype";

# test NDBM_File
# - create a DB, then grep to check we get out as many records as we put in

my $records = shift || 1_000;

warn "$records records\n";

my $columns = ($ENV{COLUMNS} || 80) - 8;
$| = 1;

# range of key,value chars
my @d = map {chr($_)} 0x20..0x7e;

sub create
{
	print 'create: ';
	my %h;
	tie %h, $dbtype, 'db', O_WRONLY|O_CREAT|O_TRUNC, 0640
		or die "tie failed: $!\n";

	my $n = $records/$columns;
	my $m = 1;
	my $i;
	for ($i = 0; $i < $records; $i++)
	{
		my $j = $i % @d;
		my $k = $i;
		my $v = join '', (@d[$j..$#d], @d[0..($j-1)])[0..rand(@d)];
		$h{$k} = "$i $v";
		$m += $n, print '.' if ($i == int $m);
	}

	untie %h;	# release DB
	print "\n";
}

sub qgrep
{
	my %h;
	print 'grep:   ';
	unless (tie %h, $dbtype, 'db', O_RDONLY, 0)
	{
		warn "tie failed: $!\n";
		return undef;
	}

	#print "$$ query:\n";

	my $n = $records/$columns;
	my $m = 1;
	my $i = 0;
	while (my ($k, $v) = each %h)
	{
		die "invalid record\n" unless $v =~ /^$k /;
		$m += $n, print '+' if ($i++ == int $m);
	}
	die "invalid number of records: expected $records, got $i\n"
		if ($i != $records);
	print "\n";

	untie %h;
}

unless (unlink 'db', 'db.dir', 'db.pag')
{
	die "couldn't remove old db files: $!\n" if $! != POSIX::ENOENT;
}

create();

qgrep();

unlink 'db', 'db.dir', 'db.pag' or die "couldn't remove db files: $!\n";
