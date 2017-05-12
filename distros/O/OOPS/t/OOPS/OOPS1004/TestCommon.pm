
#
# Regression test support for OOPS
#

package OOPS::OOPS1004::TestCommon;

@EXPORT = qw($debug 
	$r1 $r2 
	$fe
	$okay
	$ocut
	$bbs
	$basecount
	$dbms
	$tcTODO
	notied
	nodata
	test
	samesame
	docompare
	qcheck
	showpos
	max
	rowcount
	resetall
	groupmangle
	check_refcount
	nocon
	rcon
	rcon12
	nukevar
	runtests
	runtest
	russian_roulette
	wa
	db_drop
	supercross1
	supercross7
	rvsamesame
	ref2string
	modern_data_compare
	check_resources
	safeout
	betterkeys
	$test_dsn
	$test_user
	$test_pass
	$multiread
	$Npossible
	$Nvert
	$prefix
	%args
	);
@ISA = qw(Exporter);

BEGIN {
	for my $m (qw(Data::Compare Clone::PP BSD::Resource)) {
		unless ( eval " require $m " ) {
			print "1..0 # Skipped: this test requires the $m module\n";
			exit;
		}
		$m->import();
	}
}

use OOPS::OOPS1004;
use OOPS::OOPS1004::Setup;
import Clone::PP qw(clone); 
use Carp::Heavy; # weird error sometimes w/o this
use Carp qw(confess);
use Scalar::Util qw(reftype refaddr);
use Data::Dumper;
use strict;
require Exporter;

select(STDOUT);
$| = 1;

our $debug = ! $ENV{HARNESS_ACTIVE};
print STDERR "# Debugging on\n" if $debug;

our $multiread = 0;

our $test_dsn;

our $tcTODO;

BEGIN	{
	$test_dsn = $ENV{OOPSTEST_DSN};

	unless ($test_dsn || eval { require DBD::SQLite } ) {
		print "1..0 # Skipped: this test requires \$OOPSTEST_DSN to be set or DBD::SQLite to be installed\n";
		exit 0;
	}
}

our $test_user = $ENV{OOPSTEST_USER};
our $test_pass = $ENV{OOPSTEST_PASS};

unless ($test_dsn) {
	# we know we've got SQLite..
	$test_dsn = "DBI:SQLite:dbname=/tmp/OOPStest.$$.db"
}

our (%args) = (
	dbi_dsn		=> $test_dsn, 
	user		=> $test_user, 
	password	=> $test_pass,
	table_prefix	=> $ENV{OOPSTEST_PREFIX} || "TEST",
	no_front_end	=> 1,
);

$args{default_synchronous} = 'OFF' if $test_dsn =~ /^DBI:SQLite:/i;

our $fe;
our ($r1, $r2);
our $prefix;

our $okay = 1;


$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useperl = 1;
$Data::Dumper::Purity = 1;

delete $SIG{__WARN__};
delete $SIG{__DIE__};

our $basecount;

our $dbms = OOPS::OOPS1004->initial_setup(%args) || confess;

$OOPS::OOPS1004::bigcutoff = 50;
$OOPS::OOPS1004::sqlite::big_blob_size = 60;
our $ocut = $OOPS::OOPS1004::bigcutoff;
our $bbs = $OOPS::OOPS1004::sqlite::big_blob_size;

sub eline
{
	 my $i = 0;
	 my $l = '';
	 for (;;) {
		 my ($package, $filename, $line) = caller($i++);
		 $l .= "/" if $l;
		 $l .= $line;
		 return($debug ? $l : $line) if $filename ne __FILE__;
		 return '???' unless $filename;
	}
}

sub safeout
{
	my $x = join('', @_);
	$x =~ s/\n([^\#])/\n#$1/g;
	print STDERR $x;
}

sub rvnotied
{
	my $bad = 0;

	for my $i (keys %OOPS::OOPS1004::tiedvars) {
		next if $i eq $r1;
		next if $i eq $r2;
		next if $r1 && $i eq tied %{$r1->{named_objects}};
		next if $r2 && $i eq tied %{$r2->{named_objects}};
		$bad++;
		print "TIED $i FROM $OOPS::OOPS1004::tiedvars{$i}\n" if $debug;
	}
	return $bad;
}

sub notied 
{
	my ($msg, $line) = @_;

	unless ($OOPS::OOPS1004::debug_tiedvars) {
		print "ok $okay # Skip \$OOPS::OOPS1004::debug_tiedvars not set\n";
		$okay++;
		return;
	}

	my $bad = rvnotied();

	$line ||= eline;
	my $pm = $msg || '';
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;

	print "not " unless $bad == 0;
	print "ok $okay - line$line # $pm - $bad tied variables\n";
	$okay++;
	russian_roulette($bad);
	%OOPS::OOPS1004::tiedvars = (); 
}

sub russian_roulette
{
	my ($chambered, $msg) = @_;
	return unless $chambered;
	return unless $debug;
	print $msg if defined $msg;
	print "\nBail out!   ... early so the error doesn't scroll away\n";
	print Carp::longmess();
	select(STDOUT);
	$| = 1;
	print "";
	kill(9,$$);
}

sub nodata
{
	my ($msg) = @_;

	return unless defined $basecount;

	my $count = rowcount();

	my $line = eline;
	print "not " unless $count eq $basecount;
	my $pm = $msg || '';
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;
	$pm = "database is empty" unless $pm;
	print "ok $okay - line$line # $pm\n";
	$okay++;

	russian_roulette($count ne $basecount, "basecount: $basecount\nnewcount: $count\n");
}

sub todo_test
{
	my ($true, $msg) = @_;

	my $line = eline;

	my $pm = $msg || '';
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;
	print "not " unless $true;
	print "ok $okay - line$line # TODO $pm\n";
	$okay++;
}

sub test
{
	my ($true, $msg) = @_;

	my $line = eline;

	my $todo = $tcTODO
		? "TODO ($tcTODO) "
		: "";

	my $pm = $msg || '';
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;
	print "not " unless $true;
	print "ok $okay - line$line # $todo$pm\n";
	$okay++;

	russian_roulette(! $true)
		unless $tcTODO;
}

sub rvsamesame
{
	my ($o1, $o2, $msg) = @_;
	
	my $x1 = Dumper($o1);
	my $x2 = Dumper($o2);
	$msg .= "\n" if $msg && $msg !~ /\n$/;
	$msg = '' unless defined $msg;

	return "x1=$x1\nx2=$x2\n$msg"
		if $x1 ne $x2;
	return undef;
}

sub samesame
{
	my ($o1, $o2, $msg) = @_;

	my $err = rvsamesame($o1, $o2);

	my $line = eline;
	print "not " if $err;
	my $pm = $msg || '';
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;
	print "ok $okay - line$line # $pm\n";
	$okay++;

	russian_roulette($err, $err);
}


#	http://search.cpan.org/~fdaly/Test-Deep-0.084/lib/Test/Deep.pod
#	http://search.cpan.org/~mgraham/Palm-Progect-2.0.1/mlib/Test/More.pm
#	http://search.cpan.org/~pdenis/Data-Structure-Util-0.09/lib/Data/Structure/Util.pm
#	http://search.cpan.org/~ilyaz/etext.1.6.3/eText/utils/FreezeThaw.pm
#	http://search.cpan.org/~xmath/Data-XDumper-1.03/XDumper.pm
#	http://search.cpan.org/~jzucker/SQL-Statement-1.005/lib/SQL/Parser.pm
#	http://search.cpan.org/~gaas/Data-Dump-1.02/lib/Data/Dump.pm
#	http://search.cpan.org/~clkao/Data-Hierarchy-0.17/Hierarchy.pm
#	http://search.cpan.org/~jbrown/PHP-Serialization-0.27/lib/PHP/Serialization.pm
#	http://search.cpan.org/~ingy/Data-Denter-0.15/Denter.pod
#	http://search.cpan.org/~ingy/YAML-0.30/YAML.pod

sub docompare
{
	my ($x, $y) = @_;
	my $r = Data::Compare::Compare($x, $y);
	return $r if $r;

#	my $x1 = Dumper($x);
#	my $x2 = Dumper($y);
#	return 1 if $x1 eq $x2;
#	safeout "# x1=$x1\nx2=$x2\n" if $debug;
#	
#	require YAML;
#	my $y1 = YAML::Dump($x);
#	my $y2 = YAML::Dump($y);
#	return 1 if $y1 eq $y2;
#	safeout "# y1=\n$y1\ny2=\n$y2\n" if $debug;
#
#	require Data::Dump;
#	my $b1 = Data::Dump::dump($x);
#	my $b2 = Data::Dump::dump($y);
#	return 1 if $b1 eq $b2;
#	safeout "# b1=$b1\nb2=$b2\n" if $debug;
#
	my $c1 = ref2string($x);
	my $c2 = ref2string($y);
	return 1 if $c1 eq $c2;
	safeout "# c1=$c1\n# c2=$c2\n" if $debug;
#
#	use Data::XDumper;
#	my $z1 = Data::XDumper::Dump($x);
#	my $z2 = Data::XDumper::Dump($y);
#	safeout "# z1=$z1\nz2=$z2\n" if $debug;

	return 0;
}

sub modern_data_compare
{
	# 0.02 bad, 0.10 good, don't know about in-betwen
	return 1 if $Data::Compare::VERSION >= 0.10;  
	print "1..0 # Skipped: Data::Compare too out-of-date, may recurse forever\n";
	exit 0;
}

our $resource_check_magic_number = 100;
our $resource_check_count;
our $resource_check_first;
our $resource_check_last;
our $resource_check_last_okay;
our $resource_check_okay;
sub check_resources
{
	my (undef, undef, $maxrss) = getrusage(RUSAGE_SELF);
	if ($resource_check_count++ == $resource_check_magic_number) {
		$resource_check_okay = $okay;
		$resource_check_first = $maxrss;
	}
	if ($resource_check_first && $maxrss > $resource_check_last) {
		printf "# memory leaked since last resrouce check: %d\n", 
			$maxrss - $resource_check_last;
	}
	$resource_check_last = $maxrss;
	$resource_check_last_okay = $okay;
}
END	{
	if ($resource_check_first) {
		printf "# Memory leaked between test $resource_check_last_okay and $resource_check_okay: %d",
			$resource_check_last - $resource_check_first;
	}
}

END	{
	print "# DBI bug workaround invoked: $OOPS::OOPS1004::dbi_bug_workaround_count_debug\n"
		if $OOPS::OOPS1004::dbi_bug_workaround_count_debug;
}


sub qcheck
{
	my ($q, $picture, @extra) = @_;
	$q =~ s/TP_/$args{table_prefix}/g;
	confess "pict:'$picture'" unless $picture =~ /\A(\s+)\+([-+]+)\+\n/;
	my $ws = $1;
	my $fp = $2;
	my (@fl) = map { length($_) - 1} split(/\+/, $fp);
	my $wsl = length($ws);
	my $pos = ($wsl + length($fp) + 3) * 3;
	my %rows;
	while ($pos < length($picture)) {
		$pos += $wsl + 2;
		last if substr($picture, $pos-2, 1) eq '+';
		#showpos($pos, $picture);
		my @row;
		for my $i (0..$#fl) {
			my $x = substr($picture, $pos, $fl[$i]);
			$x =~ s/^\s+//;
			$x =~ s/\s+$//;
			push(@row, $x);
			$pos += $fl[$i]+2;
		}
		#print "row = @row\n";
		$rows{join(",", @row)}++;
	}
	my $dbh = OOPS::OOPS1004->dbiconnect(%args) || confess;
	my $sth = $dbh->prepare($q) || confess;
	$sth->execute(@extra) || confess;
	my (@a);
	while (@a = $sth->fetchrow_array()) {
		$rows{join(",", @a)}--;
	}
	$sth->finish;
	my $ok = 1;
	for my $r (keys %rows) {
		next unless $rows{$r};
		$ok = 0;
		next unless $debug;
		if ($rows{$r} > 0) {
			print STDERR "${okay}missing: $r\n";
		} else {
			print STDERR "${okay}extra  : $r\n";
		}
	}
	my $line = eline;
	print "not " unless $ok;
	my $pm = $q;
	$pm =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$pm =~ s/\n\s*/\\n /g;
	print "ok $okay - line$line # $pm\n";
	$okay++;
	$dbh->disconnect;
	russian_roulette(! $ok);
}



sub showpos
{
	my ($pos, $str) = @_;
	my $mb = max(200, $pos, length($str));
	my $ma = max(200, length($str)-$pos);
	print substr($str, $pos-$mb, $mb);
	print "*";
	print substr($str, $pos, $ma);
	print "\n\n\n";
}

sub max
{
	my ($n, @n) = @_;
	for my $i (@n) {
		$n = $i if $n > $i;
	}
	return $n;
}

sub rowcount
{
	my (@tables) = @_;

	my $t = "TP_object TP_attribute TP_big";
	$t =~ s/TP_/$args{table_prefix}/g;
	@tables = split(" ", $t)
		unless @tables;

	my $dbh = OOPS::OOPS1004->dbiconnect(%args) || confess;
	my $c = 0;
	my $s = '';
	for my $t (@tables) {
		my $sth = eval { $dbh->prepare("select count(*) from $t");};
		confess $@ if $@;
		$sth->execute() || confess $sth->errstr;
		my ($count) = $sth->fetchrow_array();
		$c += $count;
		$s .= " $t:$count";
		$sth->finish();
	}
	$dbh->disconnect;
	return "$c$s";
}

sub db_drop
{
	if ($test_dsn =~ m{^DBI:SQLite\d*:dbname=(/tmp/OOPStest.\d+.db)$}) {
		unlink($1);
	} else {
		eval {
			OOPS::OOPS1004->db_domany(\%OOPS::OOPS1004::TestCommon::args, <<END);
				DROP TABLE TP_object;
				DROP TABLE TP_attribute;
				DROP TABLE TP_big;
END
		};
		eval { OOPS::OOPS1004->db_domany(\%OOPS::OOPS1004::TestCommon::args, "DROP TABLE TP_counters") }
			unless $dbms eq 'sqlite';
	}
}

sub resetall
{
	my ($msg, $die, $force) = @_;
	my $line = eline;

	print "# ---------------------------- reset all ---------------------- $line\n" if $debug;
	undef $fe;
	undef $r1;
	check_refcount($msg, $die)
		unless $force;
	notied('at reset', $line)
		unless $force;

	no strict 'refs';
	my $x;
	for my $t (&{"OOPS::OOPS1004::${dbms}::table_list"}()) {
		$x .= "DELETE FROM $t;\n";
	}
	OOPS::OOPS1004->db_domany({ %args }, 
		$x 
		. OOPS::OOPS1004->db_initial_values() 
		. &{"OOPS::OOPS1004::${dbms}::db_initial_values"}());
	use strict;
	

	$basecount = rowcount() unless defined $basecount;
	nodata();

	$r1 = OOPS::OOPS1004->new(%args) || confess;
	$fe = OOPS::OOPS1004::FrontEnd->new($r1);
	$prefix = $r1->{table_prefix};
}

sub groupmangle
{
	my ($action) = @_;

	my $r = OOPS::OOPS1004->new(%args) || confess;
	my $dbh = $r->{dbh};

	my $q;

	if ($action eq 'manygroups') {
		$q = $dbh->prepare(<<END);
			UPDATE `${prefix}object` 
			SET loadgroup = id
END
	} elsif ($action eq 'onegroup') {
		$q = $dbh->prepare(<<END);
			UPDATE `${prefix}object` 
			SET loadgroup = 5
			WHERE virtual = 0

END
	} else {
		confess;
	}
	confess $dbh->errstr unless $q;
	$q->execute();
}

sub AUTODISC::DESTROY
{
	my $self = shift;
	my $dbh = $self->{dbh};
	$dbh->disconnect();
}

sub check_refcount
{
	my ($msg, $die) = @_;
	my $dbh = OOPS::OOPS1004->dbiconnect(%args) || confess;
	my $autodisc = bless { dbh => $dbh }, 'AUTODISC';
	my $error = 0;
	my $aq = "SELECT pval, count(*) FROM TP_attribute WHERE ptype = 'R' GROUP BY pval";
	$aq =~ s/TP_/$args{table_prefix}/g;
	my $rq = "SELECT id, refs FROM TP_object";
	$rq =~ s/TP_/$args{table_prefix}/g;
	my $actual = $dbh->prepare($aq) || confess $dbh->errstr;
	$actual->execute() || confess $actual->errstr;
	my (%actual, %recorded);
	my ($id, $count);
	while (($id, $count) = $actual->fetchrow_array()) {
		$actual{$id} = $count;
	}
	$actual->finish;
	my $recorded = $dbh->prepare($rq) || confess $dbh->errstr;
	$recorded->execute() || confess $recorded->errstr;
	while (($id, $count) = $recorded->fetchrow_array()) {
		$recorded{$id} = $count;
	}
	$recorded->finish;
	undef $actual;
	undef $recorded;
	$dbh->disconnect;
	my $err;
	for $id (keys %actual) {
		no warnings qw(uninitialized);
		if ($recorded{$id} != $actual{$id}) {
			$err .= "reference count of *$id is off: $recorded{$id} recorded, but should be $actual{$id}\n";
			$error++;
		}
		delete $recorded{$id};
	}
	for $id (keys %recorded) {
		$err .= "reference count of *$id is off: $recorded{$id} recorded, but should be 0\n";
		$error++;
	}
	#my $line = (caller(@_ ? $_[0] : 1))[2];
	my $line = eline;
	$msg ||= '';
	$msg =~ s/\A\s*(.*?)\s*\Z/$1/s;
	$msg =~ s/\n\s*/\\n /g;
	$msg = "- $msg" if $msg;
	if ($err) {
		print "not ok $okay - line$line # reference counts are off - $error object $msg\n";
		confess "$err " if $die;
		print $err if $debug;
		russian_roulette(1);
	} else {
		print "ok $okay - line$line # refcount $msg\n";
	}
	$okay++;
}

sub nocon
{
	undef $fe;
	undef $r1;
	undef $r2;
}

sub rcon
{
	my ($msg, $skipref) = @_;
	undef $fe;
	undef $r1;
	undef $r2;
	my $line = eline;
	print "# ---------------------------- reconnect ---------------------- $line\n" if $debug;
	check_refcount($msg)
		unless $skipref;
	notied('at reset', $line)
		unless $skipref;
	$r1 = OOPS::OOPS1004->new(%args) || confess;
	$fe = OOPS::OOPS1004::FrontEnd->new($r1);
}

sub rcon12
{
	rcon(($_[0] || 0)+1);
	$r2 = OOPS::OOPS1004->new(%args) || confess;
}

our $Nvert;

sub runtest
{
	my ($setup, $modify, $msg, $virts, $looks, @variables) = @_;
	my $line = eline;
	my $mult = scalar(@$virts) * scalar(@$looks);
	my $count = 1;
	for my $virt (@$virts) {
		for my $look (@$looks) {
			my $x = eval {
				my $r;
				resetall(undef,'die','force');
				my %named;
				my $n1 = \%named;

				$Nvert = 0;
				&$setup($n1, @variables);
				return "SETUPFAILURE\n" unless %named;

				$Nvert = 1;
				&$setup($r1->{named_objects}, @variables);

				$r1->virtual_object($r1->{named_objects}{root}, 1)
					if exists $n1->{root} && $virt eq 'virt1';
				if ($look & 0x2) {
					$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
					return "PRECOMMIT\n$r" if $r;
				}
				$r1->commit;
				if ($look & 0x4) {
					$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
					return "POSTCOMMIT\n$r" if $r;
				}
				nocon;
				check_refcount(__LINE__, 'die');
				rcon(undef, 'skipref');
				if ($look & 0x10) {
					$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
					return "PREMODIFY\n$r" if $r;
				}
				$Nvert = 0;
				&$modify($n1, @variables);
				$Nvert = 1;
				&$modify($r1->{named_objects}, @variables);
				if ($look & 0x1) {
					$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
					return "POSTMODIFY\n$r" if $r;
				}
				$r1->commit;
				if ($look & 0x8) {
					$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
					return "PRERECONNECT\n$r" if $r;
				}
				nocon;
				check_refcount(__LINE__, 'die');
				rcon(undef, 'skipref');
				$r = rvsamesame($n1->{root}, $r1->{named_objects}{root});
				return "POSTRECONNECT\n$r" if $r;
				nocon;
				check_refcount(undef, 'die');
				return 0;
			};
			my $e = $@;
			eval { $r1->{dbh}->commit; };  # for debugging

			print "not " if $e || $x;
			print "ok $okay - line$line # $virt $look $count/$mult - $msg\n";
			$okay++;
			$count++;

			return "EVAL: $e" if $e;
			return "ERROR: $x" if $x;
		}
	}
	return 0;
}

our $Npossible = 0;;

#
# runtests($setupfunc, $modifyfunc, $virtarry, $peekarray, @other_vars) 
#	$setupfunc(\%hash, @other_vars)  - function to set things up  
#	$modifyfunc(\%hash, @other_vars)  - function to modify values
#	$virtarray - [ qw(virt0 virt1) ]
#	$peekarray - [ 0..31 ]'
#	@other_vars - multiple array slices of subtests
#
sub runtests
{
	my ($setup, $modify, @variables) = @_;
	my $line = eline;

	my $sig = '';
	$Npossible = 1;
	for my $vi (0..$#variables) {
		$Npossible *= scalar(@{$variables[$vi]});
		$sig .= scalar(@{$variables[$vi]}) == 1
			? "<$variables[$vi][0]>"
			: "*".scalar(@{$variables[$vi]});
	}
	$sig .= "-$Npossible";
	my $r = runtest($setup, $modify, $sig, @variables);
	return unless $r && $debug;

	russian_roulette($Npossible == 1, $r);

	print "# $r\n";

	my $inv = $#variables;
	print "# ATTEMPTING TO CUT DOWN POSSIBILITY SPACE\n";
	for my $xx (1..3) {
		for my $vi (0..$#variables) {
			my (@found) = @{$variables[$vi]};
			my @tested;
			my @test;
			my (@nv) = (@variables[0..($vi-1)], \@test, @variables[($vi+1)..$#variables]);
			confess unless $#nv == $inv;
			confess if grep (! (ref $_ eq 'ARRAY'), @nv);
			for(;;) {
				last unless @found > 1;
				@test = @found[0..int(($#found)/2)];
				confess unless @test;
				last unless @test;
				my (@untest) = @found[int(($#found)/2)+1 .. $#found];
				confess unless @untest;
				confess unless $#nv == $inv;
				confess if grep (! (ref $_ eq 'ARRAY'), @nv);
				$r = runtest($setup, $modify, $line, @nv);
				if ($r) {
					# winner
#print "a winner at variables[$vi]: '@found': $r\n";
					@found = @test;
					redo;
				} 
				my (@tmp) = @test;
				@test = @untest;
				last unless @test;
				@untest = @tmp;
				confess unless @untest;
				confess unless $#nv == $inv;
				confess if grep (! (ref $_ eq 'ARRAY'), @nv);
				$r = runtest($setup, $modify, $line, @nv);
				if ($r) {
					# winner
#print "a winner at variables[$vi]: '@found': $r\n";
					@found = @test;
					redo;
				} 
				last;
			}
			@variables = (@variables[0..($vi-1)], \@found, @variables[($vi+1)..$#variables]);
			confess unless $#variables == $inv;
			confess if grep (! (ref $_ eq 'ARRAY'), @variables);
		}
	}
	print "----------------------------- simplest run ---------------------------------------------\n";
	$r = runtest($setup, $modify, $line, @variables);
	print $r;
	print "line$line\n\nrussian_roulette(map { \$_, \$_ } runtests(\$t1, \$t2";
	for my $vi (0..$#variables) {
		print ", [qw( ".join(' ',@{$variables[$vi]})." )]";
	}
	print "));\n";

	russian_roulette(1);
}

sub ref2string
{
	my $r = shift;
	my $str = '';
	bad_dump(\$str, $r);
	return $str;
}

sub bad_dump
{
	my($sr,$x,$indent,%done) = @_;
	my($y);

	$indent = 0 unless defined $indent;

	if (ref $x) {
$$sr .= "(noting '$x')" if $main::xy;
		if ($done{refaddr($x)}++) {
			$$sr .= '<CIRCULAR VALUE>';
			return;
		}
	}

	my $n;

	if (ref $x) {
		if (ref($x) ne reftype($x)) {
			$$sr .= "(" if $indent;
			$$sr .= "bless ";
		}
		if (reftype($x) eq 'HASH') {
			$$sr .= "{";
			$n = "\n";
			for $y (sort keys %$x) {
				$$sr .= $n."  ".("  "x$indent);
				if (ref $y) {
					&bad_dump($sr, $y, $indent+1, %done);
				} else {
					$$sr .= &quote($y);
				}
				$$sr .= " => ";
				&bad_dump($sr,$x->{$y},$indent+1, %done);
				$n = ",\n";
			}
			if ($n ne "\n") { # {
				$$sr .= "\n".("  "x$indent)."}";
			} else { # {
				$$sr .= "}";
			}
		} elsif (reftype($x) eq 'ARRAY') {
			$$sr .= "[";
			$n = "\n";
			for ($y = 0; $y <= $#{$x}; $y++) {
				$$sr .= "$n  ".("  "x$indent);
				&bad_dump($sr,${$x}[$y],$indent+1, %done);
				$n = ", # $y\n";
			}
			if ($n ne "\n") {
				$$sr .= "  # ".($y-1)."\n".("  "x$indent)."]";
			} else {
				$$sr .= "]";
			}
		} elsif (reftype($x) eq 'SCALAR') {
			#$$sr .= "\\".&quote($$x);
			$$sr .= "\\";
			&bad_dump($sr,$$x,$indent+1, %done);
		} elsif (reftype($x) eq 'REF') {
			$$sr .= "\\";
			&bad_dump($sr,$$x,$indent+1, %done);
		} else {
			confess;
		}
		if (ref($x) ne reftype($x)) {
			$$sr .= ", ".&quote(ref($x));
			$$sr .= ")";
			$$sr .= ")" if $indent;
		}
	} else {
		$$sr .= &quote($x);
	}
}

sub quote {
	my($s) = @_;
	my($e);
	return 'undef' unless defined $s;
	$s =~ s/\\/\\\\/g && ($e = 1); 
	$s =~ s/\n/\\n/g && ($e = 1);
	$s =~ s/\t/\\t/g && ($e = 1);
	$s =~ s/\r/\\r/g && ($e = 1);
	$s =~ s/\f/\\f/g && ($e = 1);
	$s =~ s/\$/\\\$/g && ($e = 1);
	$s =~ s/\@/\\\@/g && ($e = 1);
	$s =~ s/([\0-\37\177-\200])/sprintf("\\x%02x",ord($1))/eg && ($e = 1);
	if ($s =~ /^[1-9]\d*(\.\d+)?$/ || $s =~ /^[A-Z]\w*$/) {
		return $s;
	} elsif (defined $e && $e == 1) {
		$s =~ s/"/\\"/g;
		return "\"$s\"";
	} else {
		$s =~ s/'/\\'/g;
		return "'$s'";
	}
}

sub nukevar
{
	for my $x (@_) {
		next unless ref($x);
		if (reftype($x) eq 'HASH') {
			nukevar(keys %$x);
			%$x = ();
		} elsif (reftype($x) eq 'ARRAY') {
			nukevar(@$x);
			@$x = ();
		} elsif (reftype($x) eq 'SCALAR') {
			nukevar($$x);
			$x = undef;
		} elsif (reftype($x) eq 'REF') {
			nukevar($$x);
			$x = undef;
		} else {
			confess;
		}
	}
}

sub supercross1
{
	my ($tests, $baseroot, $selector) = @_;
	my $number = 0;
	for my $test (split(/^\s*$/m, $tests)) {
		$number++;
		next unless &$selector($number);
		my %conf;
		$test =~ s/\A[\n\s]+//;
		$conf{$1} = [ split(' ', $2) ]
			while $test =~ s/([A-Z])=(.*)\n\s*//;
		my (@tests) = split(/\n\s+---\s*\n/, $test);
		my (@func);
		for my $t (@tests) {
			eval "push(\@func, sub { my (\$root, \$subtest, \$subtest2, \$subtest3) = \@_; $t })";
			confess "eval test $number: <<$t>>of<$test>: $@" if $@;
		}
		my $pre;
		if ($conf{E}) {
			eval "\$pre = sub { my \$root = shift; @{$conf{E}} }";
			confess "eval <<@{$conf{E}}>>of<$test>: $@" if $@;
		}

		my (@virt) = defined $conf{V}
			? @{$conf{V}}
			: (qw(0 virtual));
		my (@commits) = defined $conf{C}
			? (grep {$_ <= (2**@tests)} @{$conf{C}})
			: (0..2**(@tests));
		my (@ss) = defined $conf{S}
			? (grep {$_ <= (2**(@tests -1))} @{$conf{S}})
			: (0..2**(@tests -1));
		my (@subtest) = defined $conf{T}
			? @{$conf{T}}
			: (0);
		my (@subtest2) = defined $conf{U}
			? @{$conf{U}}
			: (0);
		my (@subtest3) = defined $conf{X}
			? @{$conf{X}}
			: (0);

		my $mroot = {};
		my $proot;
		for my $vobj (@virt) {
			for my $subtest (@subtest) {
				for my $subtest2 (@subtest2) {
					for my $subtest3 (@subtest3) {
						for my $docommit (@commits) {
							for my $dosamesame (@ss) {
								resetall;
								my $x = 'rval';
								$mroot = clone($baseroot);
								&$pre($mroot) if $pre;

								$r1->{named_objects}{root} = clone($mroot);
								$r1->virtual_object($r1->{named_objects}{root}, $vobj) if $vobj;
								$r1->virtual_object($r1->{named_objects}{root}{hkey}, $vobj) if $vobj;
								$r1->commit;
								rcon;

								my $sig = "N=$number.V=$vobj.C=$docommit.S=$dosamesame.T=$subtest.U=$subtest2.X=$subtest3";
								print "# $sig\n";
								print $test if $debug;

								for my $tn (0..$#func) {
									my $tf = $func[$tn];
									$proot = $r1->{named_objects}{root};

									print "# EXECUTING $tests[$tn]\n" if $debug;
									&$tf($mroot,$subtest,$subtest2,$subtest3);
									&$tf($proot,$subtest,$subtest2,$subtest3);

									$r1->commit
										if $docommit & 2**$tn;
									print "# COMPARING\n" 
										if $dosamesame & 2**$tn && $debug;
									test(docompare($mroot, $proot), "<$tn>$sig")
										if $dosamesame & 2**$tn;
									rcon
										if $tn < $#func && $docommit & 2**$tn;
								}
								print "# FINAL COMPARE\n" if $debug;
								test(docompare($mroot, $proot), "<END>$sig")
							}
						}
					}
				}
			}
		}

		rcon;

		nukevar($r1->{named_objects}, $mroot);
		$r1->commit;
		rcon;
		notied;
	}
}

sub wa
{
	$r1->workaround27555(@_);
}


sub supercross7
{
	my ($tests, $extra) = @_;
	$extra ||= {};
	my $funcs = qr/(?:COMMIT|COMPARE|VIRTUAL|TODO_COMPARE|CLEAR_CACHE)/;
	for my $test (split(/^\s*$/m, $tests)) {
		my @vars;
		for(;;) {
			if ($test =~ s/^\s*\$?(\w+):(\S*)\s*\n//) {
				push(@vars, {
					pvar	=> $1,
					list	=> [ split(',', $2) ],
				});
				next;
			}
			last;
		}
		my $cpx = 1;
		while ($test =~ s/\s*CP_($funcs[^;\n]*)/\n\t\t$1 if \$supercross7cp$cpx/) {
			push(@vars, {
				pvar	=> "supercross7cp$cpx",
				list	=> [0, 1],
			});
			$cpx++;
		}
		$test =~ s/\A\s*\n//s;
		$extra->{clean} = $test;

		my $vlist = '';
		for my $v (@vars) {
			$vlist .= "\$$v->{pvar},";
		}
		chop($vlist);

		$test .= "\nDONE\n";

		my $parts = [];
		my $last = {};
		while ($test =~ s/(.*?)($funcs|DONE)(\S+)?([^\n]*)\n//s) {
			my ($tpart, $func, $arg, $ifclause) = ($1, $2, $3, $4);
			if ($tpart =~ /\S/) {
				my $x;
				eval "\$x = sub { my (\$root, $vlist) = \@_; $tpart }";
				die "eval with vlist='$vlist' and tpart='$tpart': $@" if $@;
				my $p = {
					code	=> $x,
					source	=> $tpart,
				};
				$tpart =~ s/\n\s*/\\n /g;
				$p->{source1} = $tpart;
				$p->{num} = $#$parts;
				$last = $p;
				push(@$parts, $p);
			}
			last if $func eq 'DONE';
			my $cond;
			if ($ifclause =~ /\S/) {
				eval "\$cond = sub { my ($vlist) = \@_; return 1 $ifclause; return 0 }";
				die "$@ on eval with $vlist and $ifclause" if $@;
			} else {
				$cond = sub { 1 };
			}
			push(@$parts, {
				special		=> $func,
				clause		=> $ifclause,
				cond		=> $cond,
				arg		=> $arg,
				source		=> $last->{source},
				source1		=> $last->{source1},
				num		=> $#$parts,
			});
		}
		die "test='$test'" if $test =~ /\S/s;
		supercross7test($parts, $extra, [], @vars);
	}
}

sub betterkeys(\%)
{
	my ($kref) = shift;
	my $tied = tied(%$kref);
	return keys(%$kref) if wantarray;
	if ($tied && $tied->can('SCALAR')) {
		return scalar(%$kref);
	} else {
		return keys(%$kref);
	}
}

sub supercross7test
{
	my ($parts, $extra, $preamble, $v, @vars) = @_;

	if ($v) {
		my $l = $v->{list};
		for my $i (@$l) {
			$v->{list} = [ $i ];
			push(@$preamble, $v);
			supercross7test($parts, $extra, $preamble, @vars);
			pop(@$preamble);
		}
		return;
	} 

	my $vset = '';
	my @vlist;
	for my $p (@$preamble) {
		$vset .= "\t\t\$$p->{pvar}:$p->{list}[0]\n";
		push(@vlist, $p->{list}[0]);
	}
	my $clean .= $vset . $extra->{clean};

	my $baseroot = $extra->{baseroot} || {};

	resetall;

	safeout("# $clean") if $debug;

	my $mroot = clone($baseroot);
	my $proot = $r1->{named_objects}{root} = clone($mroot);

	safeout(sprintf("# %d parts\n", scalar(@$parts))) if $debug;

	local($tcTODO) = $tcTODO;

	my $pnum = 1;
	for my $part (@$parts) {
		if ($part->{code}) {
			my $code = $part->{code};
			&$code($mroot, @vlist);
			&$code($proot, @vlist);
			safeout("# Running code: $part->{source}\n") if $debug;
		} else {
			my $ifclause = $part->{cond};
			if ($part->{clause} =~ /\S/) {
				print STDERR "# ifclause=$part->{clause}\n" if $debug;
			}
			if (&$ifclause(@vlist)) {
				if ($part->{special} eq 'COMMIT') {
					print STDERR "# Commit\n" if $debug;
					$r1->commit();
					undef $proot;
					rcon;
					$proot = $r1->{named_objects}{root};
				} elsif ($part->{special} eq 'TODO_COMPARE') {
					print STDERR "# Compare (todo)\n" if $debug;
					todo_test(docompare($mroot, $proot), $pnum);
				} elsif ($part->{special} eq 'COMPARE') {
					print STDERR "# Compare\n" if $debug;
					test(docompare($mroot, $proot), $pnum);
				} elsif ($part->{special} eq 'VIRTUAL') {
					if ($part->{arg}) {
						my $arg = $part->{arg};
						$arg =~ s/^\((.*)\)$/$1/;
						print STDERR "# Virtualize $arg\n" if $debug;
						eval "\$r1->virtual_object(\$proot$arg)";
						die $@ if $@;
					} else {
						print STDERR "# Virtualize root\n" if $debug;
						eval { $r1->virtual_object($proot, 1) };
						die $@ if $@;
					}
				} elsif ($part->{special} eq 'CLEAR_CACHE') {
					eval "\$r1->clear_cache()";
					die $@ if $@;
				} else {
					die;
				}
			} else {
				print STDERR "# Negatory on $part->{special}\n" if $debug;
			}
		}
		$pnum++;
	}
}

1;
