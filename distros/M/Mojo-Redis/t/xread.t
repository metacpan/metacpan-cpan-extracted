use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost/8' unless $ENV{TEST_ONLINE};

my $redis       = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db          = $redis->db;
my $stream_name = "test:stream:$0";
my ($err, $len, $range, $read, $struct, @p);

note 'Fresh start';
$db->del($stream_name);

push @p,
  $redis->db->xread_p(BLOCK => 2000, STREAMS => $stream_name, '$')->then(sub { $read = shift })
  ->catch(sub { $err = shift });

push @p,
  $redis->db->xread_structured_p(BLOCK => 2000, STREAMS => $stream_name, '$')->then(sub { $struct = shift })
  ->catch(sub { $err = shift });

Mojo::IOLoop->timer(
  0.2 => sub {
    my $db = $redis->db;
    Mojo::Promise->all(map { $db->xadd_p($stream_name, '*', xn => $_) } 11, 22)->then(sub {
      push @p, $db->xlen_p($stream_name)->then(sub { $len = shift });
      push @p, $db->xrange_p($stream_name, '-', '+')->then(sub { $range = shift });
      return Mojo::Promise->all(@p);
    })->finally(sub { Mojo::IOLoop->stop });
  }
);

Mojo::IOLoop->start;

plan skip_all => 'xread is not supported' if $err and $err =~ m!unknown command!i;

ok !$err, 'no error' or diag $err;
is $len, 2, 'xlen';
is_deeply $range->[1][1], [xn => 22], 'xrange[1]' or diag explain($range);
is_deeply $read->[0][0], $stream_name, 'xread stream_name' or diag explain($read);
is_deeply $read->[0][1][0][1],           [xn => 11], 'xread data'       or diag explain($read);
is_deeply $struct->{$stream_name}[0][1], [xn => 11], 'xread_structured' or diag explain($struct);

note 'Cleanup';
$db->del($stream_name);

done_testing;
