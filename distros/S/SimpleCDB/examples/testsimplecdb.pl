#!/usr/local/bin/perl -w

use strict;

use SimpleCDB;	# exports as per Fcntl

# test the SimpleCDB
# - create a DB, then fork off a number of readers
#   - every so often recreate the DB

my $records = shift || 1_000;

my $readers = shift || 0;

my $cleanup = shift;	$cleanup = 1 unless defined $cleanup;

warn "$records records, $readers readers, ". ($cleanup ? '' : 'not ') . 
	"cleaning up afterwards\n";

my $columns = ($ENV{COLUMNS} || 80) - 8;
$| = 1;

$SimpleCDB::DEBUG = $ENV{SIMPLECDBDEBUG};

# range of key,value chars
#my @d = map {chr($_)} 0x20..0x7e;
my @d = map {chr($_)} 0x00..0xff;
my $magic = pop @d;	# will be inserted in every value

sub update
{
	# create
	print "update: ";
	my %h;
	tie %h, 'SimpleCDB', 'db', O_WRONLY|O_TRUNC 
		or die "tie failed: $SimpleCDB::ERROR\n";

	my $n = $records/$columns;
	my $m = 1;
	my $i;
	for ($i = 0; $i < $records; $i++)
	{
		my $j = $i % @d;
		my $k = $i;
		my $v = join '', (@d[$j..$#d], @d[0..($j-1)])[0..rand(@d)];
		substr($v, rand(length($v)), 1) = $magic;
		$h{$k} = $v;
		die "store: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
		$m += $n, print '.' if ($i == int $m);
	}

	untie %h;	# release DB
	print "\n";
}

sub qgrep
# check the number of records
{
	my %h;
	print 'grep:   ';
	tie %h, 'SimpleCDB', 'db', O_RDONLY, 0
		or die "tie failed: $SimpleCDB::ERROR\n";

	my $n = $records/$columns;
	my $m = 1;
	my $i = 0;
	while (my ($k, $v) = each %h)
	{
		die "invalid record\n" unless $v =~ /$magic/;
		$m += $n, print '+' if ($i++ == int $m);
	}
	die "invalid number of records: expected $records, got $i\n"
		if ($i != $records);
	print "\n";

	untie %h;
}

sub query
{
	my %h;
	print 'o';	# "open"
	unless (tie %h, 'SimpleCDB', 'db', O_RDONLY)
	{
		if ($! == POSIX::EWOULDBLOCK)
		{
			print "!";
		}
		else
		{
			die "tie failed: $SimpleCDB::ERROR\n";
		}
		return undef;
	}

	#print "$$ query:\n";

	while (1)
	{
		my $i = int rand($records);
		my $v = $h{$i};
		die "fetch: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
		#print "$$\t$i = " . (defined $v ? 'ok' : '-') . "\n";
		print '+';
		die "there's just no magic between us anymore... [$v]\n"
			unless $v =~ /$magic/;
		last if rand() > 0.8;
	}
	print "\n";

	untie %h;
}

update();

qgrep();

my @kids;
my $i;
print "starting readers\n" if $readers;
for ($i = 0; $i < $readers; $i++)
{
	my $p = fork;
	srand();
	unless ($p) { @kids = (); last }
	push (@kids, $p);
}

if ($readers)
{
	if (@kids)	# parent
	{
		# an exercise in catching children
		# - perl 5.00x's signal handling is not reliable, and I quote from 
		#   perlipc "... doing nearly anything in your handler could in 
		#   theory trigger a memory fault". Nice, hey?
		# - hashes are probably not reliable, given that presumably memory
		#   allocation can occur at any time. Hopefully a presized array is
		#   ok...
		# - apparently 5.6 has signals handled via a separate thread, yippee
		my @zombies = map { 0 } @kids;
		my $z = 0;
		eval
		{
			local $SIG{INT} = sub { die "SIGINT\n" };
			local $SIG{TERM} = $SIG{INT};
			local $SIG{CHLD} = sub { $zombies[$z++] = wait; die "SIGCHLD\n" };

			while (1)
			{
				select(undef, undef, undef, 30);
				update();
			}
		};
		warn "\nchild exited unexpectedly\n" if $@ =~ /SIGCHLD/;
		print "\nstopping readers\n";
		# who's left?
		# - could just signal all @kids, but some may have exited already
		#   and thus a race condition arises - don't want to signal another
		#   unrelated process by accident (yes, yes, the probability of this
		#   happening is approximately zero, but someday I might want to do 
		#   this for real so I can come back to this code and see how I did 
		#   it. Ok? :-)
		# find complement of @kids U @zombies
		my %k = map { $_, 1 } @kids;
		map { delete $k{$_} if $_ } @zombies;
		kill INT => keys %k;
		while (%k) { my $pid = wait; delete $k{$pid} }
		die "\n" if $@ =~ /SIGCHLD/;
	}
	else		# child
	{
		eval
		{
			local $SIG{INT} = sub { die "SIGINT\n" };
			local $SIG{TERM} = $SIG{INT};
			while (1)
			{
				select(undef, undef, undef, 2 + rand(5));
				query();
			}
		};
		exit;
	}
}

if ($cleanup)
{
	$ENV{PATH} = '/bin:/usr/bin';
	system(qw/rm -rf/, 'db') == 0 or die "erk: couldn't clean up\n";
}
