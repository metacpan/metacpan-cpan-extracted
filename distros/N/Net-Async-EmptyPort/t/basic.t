use strict;

use Test::More;

use Net::Async::EmptyPort;

use IO::Async::Loop;

my $l = IO::Async::Loop->new;

ok(
   my $ep = Net::Async::EmptyPort->new( loop => $l ),
   'instantiation',
);

{
   my $attempt = $ep->empty_port;
   ok($attempt->get->read_handle->sockport, 'listened');
   note('GOT PORT ' . $attempt->get->read_handle->sockport);
}

{
   my $attempt = $ep->empty_port({ port => 50_000 });
   ok($attempt->get->read_handle->sockport, 'listened');
   note('GOT PORT ' . $attempt->get->read_handle->sockport);
}

my $listen = $ep->empty_port->get;

ok(
   $ep->wait_port({ port => $listen->read_handle->sockport })->get,
   'wait_port',
);

done_testing;
