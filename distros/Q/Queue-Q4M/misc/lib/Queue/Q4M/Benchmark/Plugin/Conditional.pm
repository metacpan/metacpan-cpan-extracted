# $Id: Conditional.pm 15435 2008-07-08 00:27:14Z daisuke $

package Queue::Q4M::Benchmark::Plugin::Conditional;
use Moose;
use Time::HiRes qw(time);

with 'Queue::Q4M::Benchmark::Plugin';

has 'table' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'q4mbench_conditional'
);

no Moose;

sub setup
{
    my ($self, $c) = @_;

    my $table = $self->table;
    my $dbh = $c->dbh;
    $dbh->do(<<EOSQL);
        CREATE TABLE IF NOT EXISTS $table (
            data TEXT NOT NULL,
            ready INTEGER NOT NULL
        ) ENGINE=queue;
EOSQL

    print "populating $table with ", $c->items, " items\n";
    my $max = $c->items;
    my $i = 0;
    my $dummy = 0;

    # We need to mix the data with data that will never be pulled
    # and some data that will be pulled immediately

    my $rate = $c->define->{dummy_rate} || 0.98;
    $dbh->do("DELETE FROM $table");
    while ($max > $i) {
        my $ok = rand() > $rate;
        my $ready;
        if ($ok) {
            $i++;
            $ready = 0;
        } else {
            $dummy++;
            $ready = CORE::time() * 2;
        }
        $dbh->do("INSERT INTO $table (data, ready) VALUES (?, ?)", undef,
            $c->random_string(64),
            $ready,
        );
        print " + $i\n" if $ok && $i % 100 == 0;
    }

    $c->add_task(
        name => 'conditional',
        coderef => sub {
            my $queue = Queue::Q4M->connect(
                connect_info => [ $c->connect_info ],
            );

            my $start = time();
            print " + Start ", scalar(localtime($start)), "\n";
            my $count = 0;
            my $cond = "$table:ready<1";
            while ( $queue->next($cond, 1) ) {
                my $h = $queue->fetch_hashref;
                $count++;
                last if $count >= $max;
            }
            my $end      = time();
            my $duration = $end - $start;
            my $avg      = $duration / $count;
            print " + End ", scalar(localtime($end)), "\n";
            print " + Created $i items and $dummy dummies (dummy rate = $rate)\n";
            print " + Processed $count messages in ", $duration, " secs, average $avg mess/sec\n";
        }
    );
}

1;