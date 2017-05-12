#!/usr/bin/perl -I. -w

my $tmp;
BEGIN	{
	$tmp = "/tmp/transtest$$";
}

use Object::Transaction;
use Carp;
use Storable;

use strict;

my $c = 1;
print "1..88\n";

my $debug = -t STDOUT;

my $magic_cookie = "O:Ta"; # must match Transaction.pm

*read_file = \&Object::Transaction::_read_file;

$SIG{'ALRM'} = \&report_where;

okay($Object::Transaction::VERSION == 1.01);

sub report_where
{
	confess;
}

sub read_frozen
{
	my ($file) = @_;
	my $x = read_file($file);
	$x =~ s/^\Q$magic_cookie\E//o 
		or die "corrupt file: $file";
	return Storable::thaw($x);
}

sub okay
{
	my ($cond, $message) = @_;
	if ($cond) {
		print "ok $c\n";
	} else {
		if ($debug) {
			my($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require) = caller(0);
			print "not ok $c: $filename:$line $message\n";
		} else {
			print "not ok $c\n";
		}
	}
	alarm(300);
	$c++;
}

sub dumpfile
{
	my ($file) = @_;
	require Data::Dumper;
	my $ref = read_frozen($file);
	print "Contents of $file:\n";
	print Data::Dumper::Dumper($ref);
	print "\n";
}

{
	package Counter;
	no strict;
	@ISA = qw(Object::Transaction);
	use strict;
	use Carp;

	sub new {
		my ($pkg, $name) = @_;
		my $counter = bless { 'ID' => $name, 'COUNT' => 1};
		$counter->cache();
		$counter->savelater();
		return $counter;
	}
	sub file {
		my ($ref,$id) = @_;
		$id = $ref->{'ID'} unless $id;
		return "$tmp/$id";
	}
	sub getnext
	{
		my ($this) = @_;
		$this->savelater();
		return ($this->{'COUNT'}++);
	}
	sub presave {
	}
	sub preload {
	}
	sub postsave {
	}
	sub postload {
	}
	sub preremove {
	}
	sub postremove {
	}
}

{
	package Employee;
	no strict;
	@ISA = qw(Object::Transaction);
	*read_file = \&Object::Transaction::_read_file;
	*write_file = \&Object::Transaction::_write_file;
	use strict;
	use Carp;

	sub new {
		my ($pkg, $name, $boss) = @_;
		my $b = load Employee $boss;
		my $empno = load Counter 'empno';
		my $emp = bless { 
			'ID' => $empno->getnext(),
			'NAME' => $name,
		};
		if ($b) {
			$b->{'REPORTS'}{$emp->id()} = time;
			$b->savelater();
			$emp->{'BOSS'} = $b->id();
		}
		$emp->savelater();
		return $emp;
	}
	sub file {
		my ($ref,$id) = @_;
		$id = $ref->{'ID'} unless $id;
		confess() unless $id;
		return "$tmp/$id";
	}
	sub presave {
	}
	sub preload 
	{
		my ($pkg,$id) = @_;
		return unless $id;
		return if $id =~ /^\d+$/;
		if (-e "$tmp/$id") {
			return read_file("$tmp/$id");
		}
		return;
	}
	sub postsave 
	{
		my ($this, $old, @presave) = @_;
		if ($old && $old->{'NAME'} ne $this->{'NAME'}) {
			unlink "$tmp/$old->{NAME}";
		}
		write_file("$tmp/$this->{NAME}", $this->id());
	}
	sub postload {
	}
	sub preremove {
	}
	sub postremove 
	{
		my ($this) = @_;
		unlink "$tmp/$this->{NAME}";
	}
}

{
	my $a = new Counter 'empno';

	Object::Transaction::commit();
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# populate some records
{
	my $sue = new Employee 'sue';			# 1
	my $bob = new Employee 'bob', 'sue';		# 2
	my $fred = new Employee 'fred', 'sue';		# 3
	my $james = new Employee 'james', 'fred';	# 4
	my $john = new Employee 'john', 'fred';		# 5

	Object::Transaction::commit();
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# check caching
# check pre-&post save functions
{
	my $sueid = read_file("$tmp/sue");
	okay ($sueid == 1);

	my $sue = load Employee 'sue';
	okay ($sue->id() == 1);

	my $jamesid = read_file("$tmp/james");
	okay ($jamesid == 4);

	my $james = load Employee 'james';
	okay ($james->id() == 4);

	my $empno = load Counter 'empno';
	my $john = load Employee 'john';
	my $fred = load Employee 'fred';
	my $bob = load Employee 'bob';

	okay($bob->id() == 2);

	my $bob2 = load Employee 2;
	my $bob3 = load Employee 'bob';

	okay($bob == $bob2);
	okay($bob == $bob3);
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# check opportunistic locking failure
{
	eval {
		my $bob1 = load Employee 'bob';
		Object::Transaction->uncache();
		my $bob2 = load Employee 'bob';
		okay ($bob1 ne $bob2);
		$bob1->{'X'} = 1;
		$bob2->{'X'} = 2;
		$bob1->save();
		$bob2->save();
		# should have died...
		okay(0);
	};

	okay ($@ =~ /^DATACHANGE: file/);


	Object::Transaction->abandon();
	Object::Transaction->uncache();

	my $bob = load Employee 'bob';
	okay ($bob->{'X'} == 1);
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# test opportunistic locking failure 
# rollback details
{
	eval {
		my $james1 = load Employee 'james';
		Object::Transaction->uncache();
		my $james2 = load Employee 'james';

		okay ($james1 ne $james2);

		my $bob = load Employee 'bob';
		my $fred = load Employee 'fred';
		my $sue = load Employee 'sue';
		my $john = load Employee 'john';

		$james1->{'X'} = 3;
		$james2->{'X'} = 4;
		$bob->{'X'}++;
		$fred->{'Y'} = 7;
		$sue->{'Z'} = 3;
		$john->{'Q'} = 99;

		$james1->save();

		$james2->savelater();
		$fred->savelater();
		$bob->savelater();
		$sue->savelater();
		$john->savelater();

		Object::Transaction::commit();

		# should have died by now...
		okay(0);
	};


	okay ($@ =~ /^DATACHANGE: file/);

	Object::Transaction->abandon();

	my $xsue = read_frozen("$tmp/1");
	my $xbob = read_frozen("$tmp/2");
	my $xfred = read_frozen("$tmp/3");
	my $xjames = read_frozen("$tmp/4");
	my $xjohn = read_frozen("$tmp/5");

	okay ($xfred->{'Y'} == 7);
	okay (! ($xfred->{'Q'} && $xfred->{'Q'} == 99));

	okay ($xsue->{'__transfollowers'});
	okay (! $xbob->{'__transfollowers'});
	okay (! $xfred->{'__transfollowers'});
	okay (! $xjames->{'__transfollowers'});
	okay (! $xjohn->{'__transfollowers'});

	okay ($xsue->{'__rollback'});
	okay ($xbob->{'__rollback'});
	okay ($xfred->{'__rollback'});
	okay (! $xjames->{'__rollback'});
	okay (! $xjohn->{'__rollback'});

	okay (! $xsue->{'__transleader'});
	okay ($xbob->{'__transleader'});
	okay ($xfred->{'__transleader'});
	okay (! $xjames->{'__transleader'});
	okay (! $xjohn->{'__transleader'});

	Object::Transaction->abandon();
	Object::Transaction->uncache();

	my $fred = load Employee 'fred';

	my $ysue = read_frozen("$tmp/1");
	my $ybob = read_frozen("$tmp/2");
	my $yfred = read_frozen("$tmp/3");
	my $yjames = read_frozen("$tmp/4");
	my $yjohn = read_frozen("$tmp/5");

	okay (! $ysue->{'__transfollowers'});
	okay (! $ybob->{'__transfollowers'});
	okay (! $yfred->{'__transfollowers'});
	okay (! $yjames->{'__transfollowers'});
	okay (! $yjohn->{'__transfollowers'});

	okay (! $ysue->{'__rollback'});
	okay (! $ybob->{'__rollback'});
	okay (! $yfred->{'__rollback'});
	okay (! $yjames->{'__rollback'});
	okay (! $yjohn->{'__rollback'});

	okay (! $ysue->{'__transleader'});
	okay (! $ybob->{'__transleader'});
	okay (! $yfred->{'__transleader'});
	okay (! $yjames->{'__transleader'});
	okay (! $yjohn->{'__transleader'});
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# test opportunistic locking failures
# more rollback details
{
	eval {
		my $james1 = load Employee 'james';
		Object::Transaction->uncache();
		my $james2 = load Employee 'james';

		okay ($james1 ne $james2);

		my $bob = load Employee 'bob';
		my $fred = load Employee 'fred';
		my $sue = load Employee 'sue';
		my $john = load Employee 'john';

		$james1->{'X'} = 5;
		$bob->{'X'}++;
		$fred->{'Y'} = 77;
		$sue->{'Z'} = 8;
		$john->{'Q'} = 9;

		$james1->save();

		$james2->readlock();
		$fred->savelater();
		$bob->savelater();
		$sue->savelater();
		$john->savelater();

		Object::Transaction::commit();

		# should have died by now...
		okay(0);
	};


	okay ($@ =~ /^DATACHANGE: file/);

	Object::Transaction->abandon();

	my $xsue = read_frozen("$tmp/1");
	my $xbob = read_frozen("$tmp/2");
	my $xfred = read_frozen("$tmp/3");
	my $xjames = read_frozen("$tmp/4");
	my $xjohn = read_frozen("$tmp/5");

	okay ($xfred->{'Y'} == 77);
	okay (! ($xfred->{'Q'} && $xfred->{'Q'} == 99));

	okay ($xsue->{'__transfollowers'});
	okay (! $xbob->{'__transfollowers'});
	okay (! $xfred->{'__transfollowers'});
	okay (! $xjames->{'__transfollowers'});
	okay (! $xjohn->{'__transfollowers'});

	okay ($xsue->{'__rollback'});
	okay ($xbob->{'__rollback'});
	okay ($xfred->{'__rollback'});
	okay (! $xjames->{'__rollback'});
	okay (! $xjohn->{'__rollback'});

	okay (! $xsue->{'__transleader'});
	okay ($xbob->{'__transleader'});
	okay ($xfred->{'__transleader'});
	okay (! $xjames->{'__transleader'});
	okay (! $xjohn->{'__transleader'});

	Object::Transaction->abandon();
	Object::Transaction->uncache();

	my $fred = load Employee 'fred';

	my $ysue = read_frozen("$tmp/1");
	my $ybob = read_frozen("$tmp/2");
	my $yfred = read_frozen("$tmp/3");
	my $yjames = read_frozen("$tmp/4");
	my $yjohn = read_frozen("$tmp/5");

	okay (! $ysue->{'__transfollowers'});
	okay (! $ybob->{'__transfollowers'});
	okay (! $yfred->{'__transfollowers'});
	okay (! $yjames->{'__transfollowers'});
	okay (! $yjohn->{'__transfollowers'});

	okay (! $ysue->{'__rollback'});
	okay (! $ybob->{'__rollback'});
	okay (! $yfred->{'__rollback'});
	okay (! $yjames->{'__rollback'});
	okay (! $yjohn->{'__rollback'});

	okay (! $ysue->{'__transleader'});
	okay (! $ybob->{'__transleader'});
	okay (! $yfred->{'__transleader'});
	okay (! $yjames->{'__transleader'});
	okay (! $yjohn->{'__transleader'});
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# test transaction() replay of failed transactions
{
	my $seq = 0;

	sub testit
	{
		my ($parm) = @_;

		$seq++;

		my $james1 = load Employee 'james';
		Object::Transaction->uncache();

		my $james2 = load Employee 'james';

		okay ($james1 ne $james2);

		my $bob = load Employee 'bob';
		my $fred = load Employee 'fred';
		my $sue = load Employee 'sue';
		my $john = load Employee 'john';

		$james1->{SEQ} = $seq;
		$james1->{'NX'} = 'mary had a little lamb';
		$james2->{'X'} = 92;
		$bob->{'PARM'} = $parm;
		$fred->{'Y'} = 77;
		$sue->{'Z'} = 8;
		$john->{'SEQ'} = $seq;

		$james1->save() if $seq < 3;

		$james2->savelater();
		$fred->savelater();
		$bob->savelater();
		$sue->savelater();
		$john->savelater();

		Object::Transaction::commit();
		okay(0, $seq) if $seq < 3;
		#Object::Transaction->uncache();
	};

	Object::Transaction->transaction(\&testit, 12);

	my $bob = load Employee 'bob';
	my $john = load Employee 'john';
	my $james = load Employee 'james';

	okay($bob->{'PARM'} == 12);
	okay($john->{'SEQ'} == 3, $john->{SEQ});
	okay($james->{'X'} == 92);
}

Object::Transaction->abandon();
Object::Transaction->uncache();

# test pre- & post- save fucntion
{
	okay (-e "$tmp/bob");

	my $bob = load Employee 'bob';
	$bob->{'NAME'} = 'albert';
	$bob->save();

	okay (-e "$tmp/albert");
	okay (! -e "$tmp/bob");
}

Object::Transaction->abandon();
Object::Transaction->uncache();

my $okaytoremove;
BEGIN	{
	die "$tmp exists, please remove" if -d $tmp;
	mkdir($tmp,0700);
	$okaytoremove = 1;
}
END 	{
	system("/bin/rm -rf $tmp") if $okaytoremove;
}

1;


