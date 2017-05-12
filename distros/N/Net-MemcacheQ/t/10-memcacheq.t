use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;
use Test::Trap;
use t::sock qw(setup teardown);

our $PKG = 'Net::MemcacheQ';

eval {
  qx(memcacheq -h) or croak $ERRNO;
} or do {
  plan skip_all => 'memcacheq not found';
  exit;
};

plan tests => 14;

use_ok($PKG);
can_ok($PKG, qw(new queues delete_queue push shift));

{
  my $nmq = $PKG->new();
  isa_ok($nmq, $PKG);
}

{
  my $nmq = $PKG->new;
  is($nmq->_host, '127.0.0.1', 'default host');
}

{
  my $nmq = $PKG->new({host => 'foobar'});
  is($nmq->_host, 'foobar', 'configured host');
}

{
  my $nmq = $PKG->new;
  is($nmq->_port, '22201', 'default port');
}

{
  my $nmq = $PKG->new({port => 12345});
  is($nmq->_port, 12345, 'configured port');
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is_deeply($nmq->queues, []);

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  $nmq->push('myqueue', 'my message');
  is_deeply($nmq->queues, [qw(myqueue)]);

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is($nmq->push('myqueue', 'my message'), q[], 'push new queue');
  is($nmq->shift('myqueue'), q[my message], 'pop existing queue');

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is($nmq->delete_queue('myqueue'), q[], 'delete non-existent queue');

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  $nmq->push('myqueue', 'my message');
  is($nmq->delete_queue('myqueue'), q[], 'delete existing queue');

  teardown();
}

{
  local $Net::MemcacheQ::DEBUG = 1;
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  trap {
    $nmq->push('myqueue', 'my message');
    $nmq->shift('myqueue');
  };
  like($trap->stderr, qr/Going.*Read.*Processed.*Read.*Finished/smx, 'push+shift with debug');

  teardown();
}
