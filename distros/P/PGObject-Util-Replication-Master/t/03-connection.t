use Test::More;
use Test::Exception;
use Data::Dumper;
use PGObject::Util::Replication::Master;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 7;

my $master = PGObject::Util::Replication::Master->new();
my $pmaster = PGObject::Util::Replication::Master->new(persist_connect => 1);

my $badmaster = PGObject::Util::Replication::Master->new(port => 5433);

=head1 TOPIC

Master replication database connection testing

=head1 GUARANTEES

=head2 Can get connection

=cut

ok($master->connect(), 'got a connection');

=head3 same connection if persistence is enabled.

=cut

is($pmaster->connect(), $pmaster->connect(), 'got a persistent connection');

=head3 from non-recovering database

=head3 not from recovering database, exception thrown

We should get an error if connecting to a recovering database.

=cut

SKIP: {
   skip 'REPLICA_TESTING not set', 1 unless $ENV{REPLICA_TESTING};
   throws_ok {$badmaster->connect} 'Database Is Recovering', 'Correct exception thrown';
};


=head3 Superuser and replica role testing

=cut

lives_ok { $master->can_manage } 'We can determine if we can manage the db';

=head3 WAL pinging

=cut

ok ($master->ping_wal, 'pinged the wal, got back a value');
my $nextref = $master->ping_wal;
ok(defined $nextref->{delta_bytes}, 'Delta bytes defined') or diag Dumper($nextref);
ok($nextref->{delta_secs}, 'Positive delta seconds') or diag Dumper($nextref);
