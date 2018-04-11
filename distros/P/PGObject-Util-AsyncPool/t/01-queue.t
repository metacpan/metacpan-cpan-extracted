use Test::More tests => 21;
use Test::Exception;
use PGObject::Util::AsyncPool;

=head1 NAME

t/01-queue.t = Queue/dequeue tests

=head1 CONCERNS TESTED

Data must be entered in a consistent format and errors must be caught directly.

=head1 REQUIREMENTS

None.  This does not attempt to actually connect to the database.  Instead it merely
checks queuing and dequeuing.

=cut

my $pool = PGObject::Util::AsyncPool->new('dbi:Pg:dbname=test', 'test', 'test', {}, {maxconns => 0});

ok($pool, 'Got a database connection pool');

is($pool->{maxconns}, 0, 'Maximum connections set to 0');

throws_ok {$pool->run(undef, undef, undef); } qr/query/i, "Got error on missing query"; 
throws_ok {$pool->run('select 1', 123, undef); } qr/callback/i, 'Got callback error with scalar callback';
throws_ok {$pool->run('select 1', [123], undef); } qr/callback/i, 'Got callback error with arrayref callback';
throws_ok {$pool->run('select 1', {t => 123}, undef); } qr/callback/i, 'Got callback error with hashref callback';
throws_ok {$pool->run('select 1', undef, {t => 123}); } qr/args/i, 'Got args error with hashref args';
throws_ok {$pool->run('select 1', undef, 123); } qr/args/i, 'Got args error with scalar args';
throws_ok {$pool->run('select 1', undef, sub { return }); } qr/args/i, 'Got args error with coderef args';

lives_ok {$pool->run('select 1', undef, undef); }, 'Undef callback and args works';
lives_ok {$pool->run('select 1', sub { return 1 }, undef); }, 'Coderef callback works';
lives_ok {$pool->run('select 1', undef, [123]); }, 'arrayref  args works';

my $obj;

ok($obj = $pool->_dequeue, 'Got first item back');
is(ref $obj->{callback}, 'CODE', 'Coderef callback');
is($obj->{callback}->(), undef, 'Callback returned undef');
is_deeply($obj->{args}, [], 'Args are empty array');

ok($obj = $pool->_dequeue, 'Got second item back');
is(ref $obj->{callback}, 'CODE', 'Coderef callback');
is($obj->{callback}->(), 1, 'Callback returned 1');

ok($obj = $pool->_dequeue, 'Got third item back');
is_deeply($obj->{args}, [123], 'Args are same as we passed in');;


