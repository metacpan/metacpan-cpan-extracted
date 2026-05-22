use Mojo::Base -strict;

use Test::More;

use Mojolicious::Plugin::Statsd::Adapter::Statsd;
use Net::Statsd::Tiny v0.4.0;

{
  package Mock::Socket;
  use Mojo::Base -base;

  has buffer => sub { [] };

  sub send {
      my ($self, $data) = @_;
      push @{$self->buffer}, $data;
  }

  sub pop {
    shift @{(shift)->buffer};
  }
}

my $sock = new_ok 'Mock::Socket';

my $statsd = new_ok
  'Mojolicious::Plugin::Statsd::Adapter::Statsd',
  [socket => $sock];

can_ok $statsd => qw(timing counter);

ok $statsd->counter(['test1'], 1), 'bumped test1 by 1';

is $sock->pop, "test1:1|c\n", 'recorded 1 hit for test1';

ok $statsd->counter(['test2'], 1, 0.99) || 1, 'bumped test2 by 1, sampled';
is $sock->pop // "test2:1|c|@0.99\n", "test2:1|c|@0.99\n", 'recorded 1 hit for test2';

ok $statsd->counter(['test1', 'test3'], 1),
  'bumped test1 and test3 by 1';
is $sock->pop, "test1:1|c\n",
  'recorded hits for test1 ...';
is $sock->pop, "test3:1|c\n",
  '... and test3';

ok $statsd->timing(['test4'], 1000),
  'timing test4 for 1000ms';
is $sock->pop, "test4:1000|ms\n",
  'recorded timing of 1000 for test4';

ok $statsd->gauge(['test6'], 42),
  'gauge test6 at 42';
is $sock->pop, "test6:42|g\n",
   'recorded gauge at 42 for test6';

ok $statsd->gauge(['test7'], -42),
  'gauge test7 at -42';
is $sock->pop, "test7:-42|g\n",
   'recorded gauge change -42 for test7';

ok $statsd->set_add(['test8'], qw/a b c/),
  'add to test8 a b c';
is $sock->pop, "test8:a|s\n", 'recordset set add for a';
is $sock->pop, "test8:b|s\n", 'recordset set add for b';
is $sock->pop, "test8:c|s\n", 'recordset set add for c';


done_testing();
