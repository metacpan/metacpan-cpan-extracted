# $Id: /mirror/coderepos/lang/perl/Queue-Q4M/trunk/misc/lib/Queue/Q4M/Benchmark/Plugin/Default.pm 65253 2008-07-08T02:20:49.109770Z daisuke  $

package Queue::Q4M::Benchmark::Plugin::Default;
use Moose;
use Time::HiRes qw(time);

with 'Queue::Q4M::Benchmark::Plugin';

has 'table' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'q4mbench_default'
);

no Moose;

sub setup
{
    my ($self, $c) = @_;

    my $table = $self->table;
    my $dbh = $c->dbh;
    $dbh->do(<<EOSQL);
        CREATE TABLE IF NOT EXISTS $table (
            data TEXT NOT NULL
        ) ENGINE=queue;
EOSQL
    $dbh->do("DELETE FROM $table");

    print "populating $table with ", $c->items, " items\n";
    my $max = $c->items;
    my $i = 0;
    while ($max > $i) {
        $i++;
        $dbh->do("INSERT INTO $table (data) VALUES (?)", undef,
            $c->random_string(64));
        print " + $i\n" if $i % 100 == 0;
    }

    $c->add_task(
        name => 'default',
        coderef => sub {
            my $queue = Queue::Q4M->connect(
                connect_info => [ $c->connect_info ],
            );

            my $start = time();
            print " + Start ", scalar(localtime($start)), "\n";
            my $count = 0;
            while ( $queue->next($table, 1) ) {
                my $h = $queue->fetch_hashref;
                $count++;
            }
            my $end      = time();
            my $duration = $end - $start;
            my $avg      = $duration / $count;
            print " + End ", scalar(localtime($end)), "\n";
            print " + Processed $count messages in ", $duration, " secs, average $avg mess/sec\n";
        }
    );
}

1;