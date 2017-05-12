#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:slow :filter Data::Dumper Clone::PP);
use OOPS::OOPS1004::TestCommon;
use OOPS::OOPS1004;
use Clone::PP qw(clone);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

print "1..2204\n";

resetall; # --------------------------------------------------
if (0) {

	my $t22 = bless { 
		a	=>	'1',
		b	=>	'2',
		c	=>	'3',
	}, 'T22';

	$r1->object_refcount($t22, 1);
	$r1->commit;
	rcon;
	my $t22a = $r1->load_object(4);
	samesame($t22, $t22a);
}
resetall; # --------------------------------------------------
if ($multiread) {

	my $a = { a => 1, };
	$r1->{named_objects}{a} = $a;
	$r1->commit;

	rcon12;
	my $b;
	$a = $r1->{named_objects}{a};
	$b = $r2->{named_objects}{a};


	samesame($a, $b);
	$a->{a} = 2;
	$b->{a} = 3;
	$r1->commit;
#	eval ' \$r2->commit ';
#	test(! $@, $@);
#print "ERROR = $@.\n";
#exit;
}
resetall; # --------------------------------------------------
if ($multiread) {

	my $a = { a => 1, };
	$r1->{named_objects}{a} = $a;
	$r1->commit;

	rcon12;
	my $b;
	$a = $r1->{named_objects}{a};
	$b = $r2->{named_objects}{a};


	samesame($a, $b);
	$a->{b} = 2;
	$b->{b} = 3;
	$r1->commit;
#	eval ' \$r2->commit ';
#	test(! $@, $@);
}
resetall; # --------------------------------------------------
{
	my $x = $OOPS::OOPS1004::oopses;
	$x = 4 if $x > 4;
	samesame($OOPS::OOPS1004::oopses, $x);

	rcon;
	rcon;
	rcon;
	rcon;

	my $y = $OOPS::OOPS1004::oopses;
	$y = 4 if $y > 4;
	samesame($OOPS::OOPS1004::oopses, $y);
}
resetall; # --------------------------------------------------
{
	nocon;
	qcheck "select * from TP_attribute where id != 2", <<END;
		+----+------------------+-------+-------+
		| id | pkey             | pval  | ptype |
		+----+------------------+-------+-------+
		+----+------------------+-------+-------+
END

	rcon;
	my $c = $r1->load_object(3);
	$c->{foo} = 9;
	$r1->commit;
	nocon;

	qcheck "select * from TP_attribute where id != 2", <<END;
		+----+------------------+-------+-------+
		| id | pkey             | pval  | ptype |
		+----+------------------+-------+-------+
		|  3 | foo              | 9     | 0     |
		+----+------------------+-------+---+---+
END

	rcon;
	my $no = $r1->{named_objects};
	$no->{myobject} = [ 'abc', 'xyz' ];
	$r1->commit;
	nocon;

	my $oi = ($dbms =~ /sqlite/) ? 101 : 111;

	qcheck "select * from TP_attribute where id != 2", <<END;
		+-----+----------+------+-------+
		| id  | pkey     | pval | ptype |
		+-----+----------+------+-------+
		|   1 | myobject | $oi  | R     |
		|   3 | foo      | 9    | 0     |
		| $oi | 0        | abc  | 0     |
		| $oi | 1        | xyz  | 0     |
		+-----+----------+------+-------+
END

}
resetall; # --------------------------------------------------
{
	my $x = $OOPS::OOPS1004::oopses;
	$x = 4 if $x > 4;
	samesame($OOPS::OOPS1004::oopses, $x);
}
resetall; # --------------------------------------------------
if (0) {
	my $t23 = bless [ 'x', 'y', 'z' ], 'T23';

	$r1->object_refcount($t23, 1);
	$r1->commit;
	rcon;
	my $t23a = $r1->load_object(4);
	samesame($t23, $t23a);
}
resetall; # --------------------------------------------------
if ($multiread) {

	my $a = { a => 1, };
	$r1->{named_objects}{a} = $a;
	$r1->commit;

	rcon12;
	my $b;
	$b = $r2->{named_objects}{a};
	$a = $r1->{named_objects}{a};


	samesame($a, $b);
	$a->{a} = 2;
	$b->{a} = 3;
	$r1->commit;

	# XXX sometimes crashes here
	rcon12;
	delete $r2->{named_objects}{a};
	$r2->commit;

	nocon;
	nodata;
}
resetall; # --------------------------------------------------
if (0) {
	my $t25s = 'foobar';
	my $t25 = bless \$t25s, 'T25';

	$r1->object_refcount($t25, 1);
	$r1->commit;
	rcon;
	my $t25a = $r1->load_object(4);
	samesame($t25, $t25a);
}
resetall; # --------------------------------------------------
if (0) {
	my $t25s = '99';
	my $t25 = \$t25s;

	$r1->object_refcount($t25, 1);
	$r1->commit;
	rcon;
	my $t25a = $r1->load_object(4);
	samesame($t25, $t25a);
}
resetall; # --------------------------------------------------
if (0) {
	my $t25s = 'foobar';
	my $t25 = bless \$t25s, 'T28';

	my $x = \$t25;

	$r1->object_refcount($x, 1);
	$r1->commit;
	rcon;
	my $xa = $r1->load_object(4);
	samesame($x, $xa);
}
resetall; # --------------------------------------------------
{
	my $b = bless { foobar => 2 }, 'Foobar';
	my $a = bless { a => 1, b => $b }, 'Barfoo';
	$r1->{named_objects}{a} = $a;
	$r1->commit;

	rcon;
	my $c = $r1->{named_objects}{a};
	samesame($a, $c);

	rcon;

	my $d = $r1->{named_objects}{a};
	bless $d->{b}, 'Zatop';
	bless $b, 'Zatop';
	$r1->commit;

	rcon;
	my $e = $r1->{named_objects}{a};
	samesame($a, $e);
}
resetall; # --------------------------------------------------
if (0) {
	my $xs = '77';
	my $xa = [ \$xs, ];
	my $xh = { K1=> \$xs, K2=>$xa };
	push(@$xa, $xh);

	my $foo = bless {
		Key1	=> \$xs,
		Key2	=> $xa,
		Key3 	=> $xh,
	}, 'MyFoo2';

	$r1->object_refcount($foo, 1);
	$r1->commit;
	nocon;


	qcheck "select * from TP_attribute", <<END;
		+----+------------------+-------+-------+
		| id | pkey             | pval  | ptype |
		+----+------------------+-------+-------+
		|  2 | counters         | 3     | 1     |
		|  2 | internal objects | 2     | 1     |
		|  2 | user objects     | 1     | 1     |
		|  4 | Key1             | 6     | 1     |
		|  4 | Key2             | 5     | 1     |
		|  4 | Key3             | 7     | 1     |
		|  5 | 0                | 6     | 1     |
		|  5 | 1                | 7     | 1     |
		|  6 | nokey            | 77    | 0     |
		|  7 | K1               | 6     | 1     |
		|  7 | K2               | 5     | 1     |
		+----+------------------+-------+-------+
END
	rcon;
	samesame($foo, $r1->load_object(4));

	rcon;
	my (@k5) = sort keys %{$r1->load_object(4)};
	my (@kk5) = (qw{ Key1 Key2 Key3 });


	samesame(\@k5, \@kk5);

}
resetall; # --------------------------------------------------
{
	my $a1 = [ 'A', 'B', 'C', 'D', 'E' ];
	my $a2 = [ 'F', 'G', 'H', 'I', 'J' ];

	$r1->{named_objects}{a1} = $a1;
	$r1->{named_objects}{a2} = $a2;
	$r1->commit;

	rcon;

	my $e1 = $r1->{named_objects}{a1};
	pop(@$e1);
	pop(@$a1);
	$r1->commit;

	rcon;

	my $f1 = $r1->{named_objects}{a1};
	samesame($a1, $f1);
	samesame($a1, $e1);
}
resetall; # --------------------------------------------------
{
	my $x = $OOPS::OOPS1004::oopses;
	$x = 6 if $x > 6;
	samesame($OOPS::OOPS1004::oopses, $x);
}
resetall; # --------------------------------------------------
{
	 $r1->{named_objects}{x} = { A => 1 };
	 $r1->commit;
	 rcon;
	 samesame($r1->{named_objects}{x},$r1->{named_objects}{x});
	 $r1->{named_objects}{x}{B} = 2;
	 $r1->commit;
	 rcon;
	 samesame($r1->{named_objects}{x},$r1->{named_objects}{x});
}
resetall; # --------------------------------------------------
{
	resetall;
	
	$r1->{named_objects}{e1} = [ 'E1' ];
	$r1->{named_objects}{e2} = [ 'E2' ];
	$r1->{named_objects}{e3} = [ 'E3' ];
	$r1->{named_objects}{e4} = [ 'E4' ];
	$r1->{named_objects}{e5} = [ 'E5' ];
	$r1->{named_objects}{h1} = { map { ("K$_" => $r1->{named_objects}{"e$_"}) } 1..5 };
	$r1->commit;
	rcon;
	$r1->{named_objects}{h2} = { map { ("K$_" => $r1->{named_objects}{"e$_"}) } 1..5 };
	$r1->commit;
	rcon;
	#$r1->{named_objects}{h3} = { map { ("K$_" => [ "E$_" ])} 1..5 };
	#$r1->commit;
	#rcon;

	my $x1 = { map { ("K$_" => [ "E$_" ])} 1..5 };
	my $x2 = { map { ("K$_" => [ "E$_" ])} 1..5 };

	my $h2 = $r1->{named_objects}{h2};
	samesame($h2, $x1);

	$h2->{AA} = 'ZZ';
	$x1->{AA} = 'ZZ';

	samesame($h2, $x1);
	$r1->commit;
	$r1->{commitdone} = 0;
	eval { $r1->commit };
	samesame($@, "");
	rcon;

	$h2 = $r1->{named_objects}{h2};
	samesame($h2, $x1);


	delete $r1->{named_objects}{e1};
	delete $r1->{named_objects}{e2};
	delete $r1->{named_objects}{e3};
	delete $r1->{named_objects}{e4};
	delete $r1->{named_objects}{e5};
	delete $r1->{named_objects}{h1};
	delete $r1->{named_objects}{h2};
	delete $r1->{named_objects}{h3};
	$r1->commit;
	nocon;
	nodata;
}
resetall; # --------------------------------------------------
{
	my $tests = <<'END';
		unshift(@$a, '22');

		push(@$a, { x => '1'});

		splice(@$a, 2, 2);

		splice(@$a, 2, 2, 'xyz');

		shift(@$a);

		pop(@$a);

		splice(@$a, 2, 2, 'xyz', 'def');

		splice(@$a, 2, 2, 'xyz', 'def', 'ghi');

		splice(@$a, 2, 2, [ 'E9' ]);

		splice(@$a, 2, 2, [ 'E9' ], [ 'E8' ]);

		splice(@$a, 2, 2, $a->[3]);

		splice(@$a, 2, 2, 'abc', $a->[3]);

		splice(@$a, 2, 2, 'abc', $a->[3], 'def');

		splice(@$a, 2, 2, 'abc', $a->[3], $a->[3]);

		splice(@$a, 2, 2, $a->[3], $a->[2]);

		splice(@$a, 2, 2, @$a[4, 4]);

		my (@b) = @$a[3, 2];
		splice(@$a, 2, 2, @b);

		$#$a = 2;

		@$a = ();

		undef @$a;

		splice(@$a, -3, 1);

		$a->[3] = $a->[0];

		undef $a->[2];

		delete $a->[2];

		my (@b) = ( 99 );
		unshift(@$a, @b);
		
		my (@b) = splice(@$a, 0, 1);
		unshift(@$a, @b);

		my (@b) = shift(@$a);
		unshift(@$a, @b);

		my $b = shift(@$a);
		unshift(@$a, $b);

		splice(@$a, 3, 1);
		my $x = shift(@$a);
		push(@$a, $x);

		splice(@$a, 4, 0, undef);

		splice(@$a, $#$a, 0, undef);

		push(@$a, undef, 'x');

		push(@$a, 'x', undef);

		push(@$a, undef);

		splice(@$a, 6, 0, undef);

		splice(@$a, scalar(@$a), 0, undef);

		$#$a = 20;

		splice(@$a, 2, 2, @$a[3, 2]);

		splice(@$a, 2, 2, @$a[2, 2]);

		splice(@$a, 2, 2, @$a[3, 3]);

		splice(@$a, 3, 1);
		push(@$a, shift(@$a));

		unshift(@$a, shift(@$a));

		$a->[3] = $a->[0];
		push(@$a, shift(@$a));

		$a->[5] = $a->[2];

		$a->[2] = $a->[5];

		@$a = ( '1', '2', '3' );

		push(@$a, '');

		push(@$a, '0');

		push(@$a, '', '0', undef);

		push(@$a, 1);

		delete $a->[1];
		delete $a->[2];

		push(@$a, exists $a->[1]);

		push(@$a, exists $a->[30]);

		delete $a->[1];
		delete $a->[2];
		for my $i (0..$#$a) {
			push(@$a, exists $a->[$i]);
		}
END
	for my $test (split(/^\s*$/m, $tests)) {

		resetall($test);
		
		$r1->{named_objects}{e1} = [ 'E1' ];
		$r1->{named_objects}{e2} = [ 'E2' ];
		$r1->{named_objects}{e3} = [ 'E3' ];
		$r1->{named_objects}{e4} = [ 'E4' ];
		$r1->{named_objects}{e5} = [ 'E5' ];
		$r1->{named_objects}{a1} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)}, 'abc' ];
		$r1->commit;
		rcon($test);
		$r1->{named_objects}{a2} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)}, 'abc' ];
		$r1->commit;
		rcon($test);
		$r1->{named_objects}{a3} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)}, 'abc' ];
		$r1->commit;
		rcon($test);

		my $sub;
		eval " \$sub = sub { my \$a = shift; $test } ";
		die "on test $test.... $@" if $@;

		my $x1 = [ [ 'E1' ], [ 'E2' ], [ 'E3' ], [ 'E4' ], [ 'E5' ], 'abc' ];

		my $a2 = $r1->{named_objects}{a2};
		samesame($a2, $x1, $test);

		&$sub($a2);
		&$sub($x1);

		samesame($a2, $x1, $test);
		$r1->commit;
		rcon($test);

		samesame($r1->{named_objects}{a2}, $x1, $test);
		samesame($r1->{named_objects}{a2}, $x1, $test);

		&$sub($r1->{named_objects}{a1});
		$r1->commit;
		rcon($test);

		&$sub($r1->{named_objects}{a3});
		$r1->commit;
		rcon($test);

		samesame($r1->{named_objects}{a1}, $r1->{named_objects}{a3}, "#4 $test");
		samesame($r1->{named_objects}{a1}, $r1->{named_objects}{a3}, "#5 $test");

		delete $r1->{named_objects}{e1};
		delete $r1->{named_objects}{e2};
		delete $r1->{named_objects}{e3};
		delete $r1->{named_objects}{e4};
		delete $r1->{named_objects}{e5};
		delete $r1->{named_objects}{a1};
		delete $r1->{named_objects}{a2};
		delete $r1->{named_objects}{a3};
		$r1->commit;
		rcon($test);
#		nodata($test);
	}
}
resetall; # --------------------------------------------------
{
	my $tests = <<'END';
		$h->{z} = 'a';

		delete $h->{K2};

		%$h = ();

		%$h = ('Q' => [ 'E6' ]);

		@$h{qw(K1 K2 K3)} = @$h{qw(K4 K5 K4)};

		@$h{qw(K1 K2 K3)} = @$h{qw(K2 K3 K1)};

		$h->{X} = '0';

		$h->{Y} = '';

		$h->{UD} = undef;
END
	
	for my $test (split(/^\s*$/m, $tests)) {

		resetall;
		
		$r1->{named_objects}{e1} = [ 'E1' ];
		$r1->{named_objects}{e2} = [ 'E2' ];
		$r1->{named_objects}{e3} = [ 'E3' ];
		$r1->{named_objects}{e4} = [ 'E4' ];
		$r1->{named_objects}{e5} = [ 'E5' ];
		$r1->{named_objects}{h1} = { map { ("K$_" => $r1->{named_objects}{"e$_"}) } 1..5 };
		$r1->commit;
		rcon;
		$r1->{named_objects}{h2} = { map { ("K$_" => $r1->{named_objects}{"e$_"}) } 1..5 };
		$r1->commit;
		rcon;
		#$r1->{named_objects}{h3} = { map { ("K$_" => [ "E$_" ])} 1..5 };
		#$r1->commit;
		#rcon;

		my $sub;
		eval " \$sub = sub { my \$h = shift; $test } ";
		die "on test $test.... $@" if $@;

		my $x1 = { map { ("K$_" => [ "E$_" ])} 1..5 };
		my $x2 = { map { ("K$_" => [ "E$_" ])} 1..5 };

		my $h2 = $r1->{named_objects}{h2};
		samesame($h2, $x1, $test);

		&$sub($h2);
		&$sub($x1);

		samesame($h2, $x1, $test);
#print "------------------ should now save with $test";
		$r1->commit;
#print "------------------ done save with $test";
		rcon;

		$h2 = $r1->{named_objects}{h2};
#print "KEYS A H2 = ".join(' ',keys %$h2)."\n";
#print "KEYS B H2 = ".join(' ',keys %$h2)."\n";
#my $xyx = Dumper($h2);
#print "KEYS C H2 = ".join(' ',keys %$h2)."\n";
#print "KEYS D H2 = ".join(' ',keys %$h2)."\n";
		samesame($h2, $x1, $test);

		rcon;
		my $h1 = $r1->{named_objects}{h1};

		&$sub($h1);
		$r1->commit;

		samesame($r1->{named_objects}{h1}, $x1, $test);
		samesame($r1->{named_objects}{h2}, $r1->{named_objects}{h1}, $test);
		samesame($r1->{named_objects}{h2}, $x1, $test);
	}
}
resetall; # --------------------------------------------------
{
	$r1->{named_objects}{e1} = [ 'E1' ];

	$r1->commit;
	rcon;

	$r1->{named_objects}{e2} = [ 'E2' ];

	$r1->commit;
	rcon;

	$r1->{named_objects}{e3} = [ 'E3' ];

	$r1->commit;
	rcon;

	$r1->{named_objects}{e4} = [ 'E4' ];

	$r1->commit;
	rcon;

	$r1->{named_objects}{e5} = [ 'E5' ];

	$r1->commit;
	rcon;

	$r1->{named_objects}{a1} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)} ];
	$r1->commit;
	rcon;

	$r1->{named_objects}{a2} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)} ];
	$r1->commit;
	rcon;

	$r1->{named_objects}{a3} = [ @{$r1->{named_objects}}{qw(e1 e2 e3 e4 e5)} ];
	$r1->commit;
	rcon;

	my $a2 = $r1->{named_objects}{a2};

	my $x1 = [ [ 'E1' ], [ 'E2' ], [ 'E3' ], [ 'E4' ], [ 'E5' ] ];
	my $y1 = [ [ 'E1' ], [ 'E2' ], [ 'E3' ], [ 'E4' ], [ 'E5' ] ];
	samesame($r1->{named_objects}{a1}, $x1);

	rcon;
	my $a2a = $r1->{named_objects}{a2};

	unshift(@$a2a, 'us');
	unshift(@$x1, 'us');

	splice(@$a2a, 3, 1, '333');
	splice(@$x1, 3, 1, '333');

	pop(@$a2a);
	pop(@$x1);

	$r1->commit;

	rcon;

	samesame($r1->{named_objects}{a2}, $x1);

	my $a3 = $r1->{named_objects}{a3};
	samesame($a3, $y1);
	samesame($a3, $y1);
	samesame($r1->{named_objects}{a1}, $a3);

#print Dumper($a3);

	unshift(@$a3, 'us');
	splice(@$a3, 3, 1, '333');
	pop(@$a3);


	samesame($a3, $x1);
	$r1->commit;

	rcon;
	samesame($r1->{named_objects}{a3}, $x1);


	delete $r1->{named_objects}{a1};
	delete $r1->{named_objects}{a2};
	delete $r1->{named_objects}{a3};
	delete $r1->{named_objects}{e1};
	delete $r1->{named_objects}{e2};
	delete $r1->{named_objects}{e3};
	delete $r1->{named_objects}{e4};
	delete $r1->{named_objects}{e5};
	$r1->commit;
	nocon;
	nodata;
}
resetall; # --------------------------------------------------
{
	$r1->{named_objects}{foo} = { 'bar' => 1 };
	$r1->{named_objects}{bas} = $r1->{named_objects}{foo};
	$r1->commit;

	rcon;


	samesame($r1->{named_objects}{foo}, $r1->{named_objects}{bas});

	rcon;

	my (@k) = sort keys %{$r1->load_object(2)};
	my @kk;
	if ($dbms =~ /sqlite/) {
		(@kk) = ('SCHEMA_VERSION', 'VERSION', 'counters', 'internal objects', 'last reserved object id', 'user objects');
	} else {
		(@kk) = ('SCHEMA_VERSION', 'VERSION', 'counters', 'internal objects', 'user objects');
	}


	samesame(\@k, \@kk);
}
resetall; # --------------------------------------------------
if ($multiread) {

	my $a = { a => 1, };
	$r1->{named_objects}{a} = $a;
	$r1->commit;

	rcon12;
	my $b;
	$a = $r1->{named_objects}{a};
	$b = $r2->{named_objects}{a};


	samesame($a, $b);
	$a->{b} = 2;
	$b->{c} = 3;
	$r1->commit;
	eval { $r2->commit; };

}
resetall; # --------------------------------------------------
{
	my $t1 = sub {
		my $named = shift;
		my (@iterations) = @{shift()};
		my (%iterations) = map { $_ => 1 } @iterations;
		my (@codes) = @{shift()};
		my (%codes) = map { $_ => 1 } @codes;
		$named->{root} = {};
		for my $i (@iterations) {
			my $u1 = undef;
			my $u2 = undef;
			my $u3 = undef; 
			my $n1 = '';
			my $n2 = '';
			my $n3 = '';
			my $z1 = '0';
			my $z2 = '0';
			my $z3 = '0';
			my $o1 = {o => 't1'};
			my $o2 = {o => 't2'};
			my $o3 = {o => 't3'};
			my $a1 = [ 'a1' ];
			my $a2 = [ 'a2' ];
			my $a3 = [ 'a3' ];
			my $s1 = 's1';
			my $s2 = 's2';
			my $s3 = 's3';
			$named->{root}{"udkey$i"} = undef 			if $codes{ud};
			$named->{root}{"nskey$i"} = ''	 			if $codes{ns};
			$named->{root}{"zekey$i"} = '0' 			if $codes{ze};
			$named->{root}{"arkey$i"} = [ "n$i" ] 			if $codes{ar};
			$named->{root}{"hakey$i"} = { Hx => "x$i" } 		if $codes{ha};

			$named->{root}{"rudkey$i"} = \$u2 			if $codes{rud};
			$named->{root}{"rnskey$i"} = \$n2 			if $codes{rns};
			$named->{root}{"rzekey$i"} = \$z2 			if $codes{rze};
			$named->{root}{"rnskey$i"} = \$s2 			if $codes{rns};
			$named->{root}{"rarkey$i"} = \$a2 			if $codes{rar};
			$named->{root}{"rhakey$i"} = \$o2 			if $codes{rha};
		}
	};
	my $t2 = sub {
		my $named = shift;
		my (@iterations) = @{shift()};
		my (%iterations) = map { $_ => 1 } @iterations;
		my (@codes) = @{shift()};
		my (%codes) = map { $_ => 1 } @codes;
		my $root = $named->{root};
		for my $p (@codes) {
			my $u1 = undef;
			my $u2 = undef;
			my $u3 = undef; 
			my $n1 = '';
			my $n2 = '';
			my $n3 = '';
			my $z1 = '0';
			my $z2 = '0';
			my $z3 = '0';
			my $o1 = {o => 1};
			my $o2 = {o => 2};
			my $o3 = {o => 3};
			my $a1 = [ '1' ];
			my $a2 = [ '2' ];
			my $a3 = [ '3' ];
			my $s1 = 's1';
			my $s2 = 's2';
			my $s3 = 's3';
			$root->{$p."key1"} = undef			if $iterations{1};
			$root->{$p."key2"} = ''				if $iterations{2};
			$root->{$p."key3"} = '0'			if $iterations{3};
			$root->{$p."key4"} = "k$p"			if $iterations{4};
			$root->{$p."key5"} = [ "a$p" ]			if $iterations{5};
			$root->{$p."key6"} = { HH => "h$p" }		if $iterations{6};
			$root->{$p."key7"} = \$u1			if $iterations{7};
			$root->{$p."key8"} = \$n1			if $iterations{8};
			$root->{$p."key9"} = \$z1			if $iterations{9};
			$root->{$p."key10"} = \$o1			if $iterations{10};
			$root->{$p."key11"} = \$a1			if $iterations{11};
			$root->{$p."key12"} = \$s1			if $iterations{12};
		}
	};
	runtests($t1, $t2, [qw(virt0 virt1)], [0..31], [ 1..12 ], [ qw(ud ns ze ar ha rud rns rze rar rha) ]);
}
resetall; # --------------------------------------------------
{
	my $t1 = sub {
		my $named = shift;
		my (@iterations) = @{shift()};
		my (%iterations) = map { $_ => 1 } @iterations;
		my (@codes) = @{shift()};
		my (%codes) = map { $_ => 1 } @codes;
		my $root = $named->{root} = {};
		for my $i (@iterations) {
			my $u1 = undef;
			my $u2 = undef;
			my $u3 = undef; 
			my $n1 = '';
			my $n2 = '';
			my $n3 = '';
			my $z1 = '0';
			my $z2 = '0';
			my $z3 = '0';
			my $o1 = {o => 1};
			my $o2 = {o => 2};
			my $o3 = {o => 3};
			my $a1 = [ '1' ];
			my $a2 = [ '2' ];
			my $a3 = [ '3' ];
			my $s1 = 's1';
			my $s2 = 's2';
			my $s3 = 's3';
			$named->{root}{"nakey$i"} = [ '0', undef, '', '', undef, undef, '0', '0', '', '0' ]
				if $codes{na};
			$named->{root}{"oakey$i"} = [ ['1'], {h=>'2'}, {h=>'3'}, \$u1, \$a1, ['4'], ['5'], \$o1, {h=>6} ]
				if $codes{oa};
			$named->{root}{"bakey$i"} = [ scalar("x$i"x($ocut/length("x$i")+1)), undef, ['x29'], scalar("y$i"x($ocut/length("x$i")+1)) ]
				if $codes{ba};
		}
	};
	my $t2 = sub {
		my $named = shift;
		my (@iterations) = @{shift()};
		my (%iterations) = map { $_ => 1 } @iterations;
		my (@codes) = @{shift()};
		my (%codes) = map { $_ => 1 } @codes;
		my $root = $named->{root};
		for my $p (@codes) {
			shift(@{$root->{$p."key1"}})
				if $iterations{1};
			pop(@{$root->{$p."key2"}})
				if $iterations{2};
			unshift(@{$root->{$p."key3"}}, ['zz3'])
				if $iterations{3};
			push(@{$root->{$p."key4"}}, { Z=>'22'} )
				if $iterations{4};
			splice(@{$root->{$p."key5"}}, 0, 4)
				if $iterations{5};
			splice(@{$root->{$p."key6"}}, 1, 4)
				if $iterations{6};
			splice(@{$root->{$p."key7"}}, 2, 1, undef, [ "u9$p" ], { B=>"y$p" }, 'xxxy')
				if $iterations{7};
			splice(@{$root->{$p."key7"}}, 1, 2, undef, [ "u9$p" ], { B=>"y$p" })
				if $iterations{7};
			if ($iterations{8}) {
				for my $i (0..$#{$root->{$p."key8"}}) {
					$root->{$p."key8"}[$i] = scalar("$p$i"x($ocut/length("$p$i")+1))
				}
			}
			if ($iterations{9}) {
				for my $i (0..$#{$root->{$p."key9"}}) {
					splice(@{$root->{$p."key9"}}, $i, 1, scalar("9$p$i"x($ocut/length("9$p$i")+1)))
				}
			}
		}

	};
	russian_roulette(map { $_, $_ } runtests($t1, $t2, [qw( virt0 )], [qw( 0 )], [qw( 1 )], [qw( oa )]));

	runtests($t1, $t2, [qw(virt0 virt1)], [0..31], [ 1..9 ], [ qw(na oa ba) ]);
}
resetall; # --------------------------------------------------
print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;

