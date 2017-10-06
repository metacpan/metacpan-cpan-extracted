use Test::More;
use Patro ':test';


# blocking queue - server will put objects on the queue
#    and proxy clients will take them. Exercises wait/notify.

$Patro::Server::OPTS{keep_alive} = 15;
$Patro::Server::OPTS{idle_timeout} = 15;
$Patro::Server::OPTS{fincheck_freq} = 15;

if (!$Patro::Server::threads_avail ||
    !eval "require Patro::Archy;1") {
    diag "# synchronization tests require threads and Patro::Archy";
    ok(1,'# synchronization tests require threads and Patro::Archy');
    done_testing;
    exit;
}

if (Storable->VERSION < 2.45) {
    diag "Storable version is ", Storable->VERSION;
    diag "If this test hangs or segfaults, upgrade to at least Storable 2.45";
}

alarm 15;  # in case the tests don't work and we deadlock
my $q1 = BlockingQueue->new(10);
my $cfg = patronize($q1);

sub take_thread {
    my ($inc) = @_;
    $q = getProxies($cfg);

    # BlockingQueue::take has Patro::wait/Patro::notify calls,
    # which should be called from a proxy client. If we say
    # $q->take, then the take function will run on the server
    # and the embedded wait/notify calls will fail, so we
    # use direct BlockingQueue::take call instead.
    
    while (defined(my $item = BlockingQueue::take($q))) {
	select undef,undef,undef,$item;
	# diag "Took $item in ",threads->tid;
	Patro::synchronize($q,sub { $q->{val3} += $item });
    }
    Patro::synchronize($q, sub { $q->{finished} += $inc });
    #diag "---------- finished ", threads->tid, " ----------";
}

sub make_thread {
    my $p0 = getProxies($cfg);

    # Prefer BlockingQueue::put($q,...) to $q->put,
    # see note in 'take_thread'
    
    for my $i (1..4) {
	for my $j (1 .. 10) {
	    BlockingQueue::put($p0, 0.001 * int(200 * rand));
	}
    }
    Patro::synchronize($p0, sub { $p0->{done} = 1 });
}


my $t1 = threads->create( sub { alarm 10; take_thread(1) } );
my $t2 = threads->create( sub { take_thread(2) } );
my $t3 = threads->create( sub { take_thread(4) } );
my $t4 = threads->create( 'make_thread' );

ok($t1 && $t2 && $t3 && $t4, 'threads created');
$_->join for $t1,$t2,$t3,$t4;

ok(1, 'threads joined');

is_deeply($q1->{queue}, [], 'queue processed');
is($q1->{finished}, 7, 'processed by three threads');
ok($q1->{val1} > 0, 'things were added to the queue');
is($q1->{val1}, $q1->{val2}, 'make == take');
is($q1->{val2}, $q1->{val3}, 'take == processed');

done_testing;


package BlockingQueue;
sub new {
    my ($pkg,$capacity) = @_;
    my $self = { queue => [], capacity => $capacity,
		 val1 => 0, val2 => 0, val3 => 0 };
    return bless $self, $pkg;
}

sub put {  # call from synchronized block
    my ($self,$element) = @_;
    Patro::synchronize( $self, 
	sub {
	    while (@{$self->{queue}} >= $self->{capacity}) {
		#Test::More::diag "Blocking queue waiting to put";
		Patro::wait($self);
	    }
	    $self->{val1} += $element;
	    push @{$self->{queue}}, $element;
	    Patro::notify($self, -1);
	});
}

sub take {
    my $self = shift;
    return Patro::synchronize(
	$self,
	sub {
	    while (@{$self->{queue}} == 0) {
		return if $self->{done};
		#Test::More::diag
		#    "BlockingQueue waiting to take in ",threads->tid;
		Patro::wait($self);
	    }
	    my $item = shift @{$self->{queue}};
	    Patro::notify($self,-1);
	    $self->{val2} += $item;
	    return $item;
	} );
}

=pod notes

segfaults with Storable 2.27
segfaults with Storable 2.39
ok with Storable 2.45
ok with Storable 2.53_01

=cut
