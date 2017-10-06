use strict;
use warnings;
use Test::More;
use Patro;
use Carp;

if (!$Patro::Server::threads_avail ||
    !eval "require Patro::Archy;1") {
    diag "# synchronization tests require threads and Patro::Archy";
    ok(1,'# synchronization tests require threads and Patro::Archy');
    done_testing;
    exit;
}

$Patro::Server::OPTS{keep_alive} = 999;
$Patro::Server::OPTS{idle_timeout} = 999;
$Patro::Server::OPTS{fincheck_freq} = 999;

my $r = { foo => 0, bar => 0 };
my $c = patronize($r);

my $N = 206;

my $t1 = threads->create(
    sub {
	my $p1 = getProxies($c);
	my ($f1,$b1) = 0;
	srand(0+$p1+$r);
	my $t = time;
	for (my $i=0; $i<$N; $i++) {
	    my $y = rand;
	    if ($y >= 0.75) {
		$b1++;
		Patro::synchronize($p1, sub { $p1->{bar}++ });
	    } elsif ($y >= 0.5) {
		$b1--;
		Patro::synchronize($p1, sub { $p1->{bar}-- });
	    } elsif ($y >= 0.25) {
		$f1++;
		Patro::synchronize($p1, sub { $p1->{foo}++ });
	    } else {
		$f1--;
		Patro::synchronize($p1, sub { $p1->{foo}-- });
	    }
	}
	return [$f1,$b1];
    });

my $t2 = threads->create(
    sub {
	my ($f2,$b2) = (0,0);
	my $p2 = getProxies($c);
	my $t = time;
	srand(0+$p2+$r);
	for (my $i=0; $i < $N; $i++) {
	    my $y = rand;
	    if ($y >= 0.75) {
		$b2++; 
		Patro::synchronize($p2, sub { $p2->{bar}++ });
	    } elsif ($y >= 0.50) {
		$b2--; 
		Patro::synchronize($p2, sub { $p2->{bar}-- });
	    } elsif ($y >= 0.25) {
		$f2++; 
		Patro::synchronize($p2, sub { $p2->{foo}++ });
	    } else {
		$f2--; 
		Patro::synchronize($p2, sub { $p2->{foo}-- });
	    }
	}
	return [$f2,$b2];
    });

my $fb1 = $t1->join;
my $fb2 = $t2->join;

my $p3 = getProxies($c);
diag "p3=",$p3->{foo},",",$p3->{bar}," local=",$fb1->[0]+$fb2->[0],
    ",",$fb1->[1]+$fb2->[1];


ok($p3->{foo} == $fb1->[0] + $fb2->[0],
   "thread-private counter consistent with synchronized counter");
ok($p3->{bar} == $fb1->[1] + $fb2->[1],
   "thread-private counter consistent with synchronized counter");

alarm 10;
ok(Patro::lock_state($p3) == 0, 'proxy is unlocked');
ok(Patro::lock_state($p3) eq 'NULL', 'can read NULL state as num or str');
Patro::synchronize($p3, sub {
    my $v1 = Patro::lock_state($p3);
    ok($v1 eq 'LOCK', 'proxy locked inside synchronize block');
    Patro::synchronize($p3, sub {
	my $v2 = Patro::lock_state($p3);
	ok($v2 eq 'LOCK', 'proxy locked inside nested synchronize');
	ok($v2 == $v1+1, 'lock state demonstrates lock stack');
		       } );
		   } );
alarm 0;


done_testing;
