use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
my ($res, @res);

# SET
$db = $redis->db;
$db->set($0 => 123, sub { @res = @_; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is_deeply \@res, [$db, '', 'OK'], 'set';

# GET
$db->get($0 => sub { @res = @_; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is_deeply \@res, [$db, '', '123'], 'get';

$db->get_p($0)->then(sub { @res = (then => @_) })->catch(sub { @res = (catch => @_) })->wait;
is_deeply \@res, [then => '123'], 'get_p';

# DEL
is_deeply $db->del($0), 1, 'blocking del';

# BLPOP
@res = ();
$db->del_p('some:empty:list', $0);
$db->lpush_p($0 => '456')->then(gather_cb('then'))->catch(gather_cb('catch'));
$db->blpop_p('some:empty:list', $0, 2)->then(gather_cb('popped'))->wait;
is_deeply \@res, ["then: 1", "popped: 456 $0"], 'blpop_p' or diag join ', ', @res;

# HASHES
$db->hmset_p($0, a => 11, b => 22);
$db->hgetall_p($0)->then(sub { $res = shift })->wait;
is_deeply $res, {a => 11, b => 22}, 'hgetall_p';

$res = $db->hkeys($0);
is_deeply $res, [qw(a b)], 'hkeys';

done_testing;

sub gather_cb {
  my $prefix = shift;
  return sub { push @res, "$prefix: @_" };
}
