use warnings;
use strict;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

BEGIN
{
    use_ok('Reflexive::Stream::Filtering');
}

my ($socket1, $socket2);
socketpair($socket1, $socket2, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;

my $filtered_stream1 = Reflexive::Stream::Filtering->new(handle => $socket1);
my $filtered_stream2 = Reflexive::Stream::Filtering->new(handle => $socket2);

$filtered_stream1->put('Here is some test data');

my $e = $filtered_stream2->next();
is($e->_name(), 'data', 'make sure the event we get is data');
is($e->data(), 'Here is some test data', 'and that the data is correct');

$filtered_stream2->put('And here is some data back');

my $e2 = $filtered_stream1->next();

is($e2->_name(), 'data', 'make sure the event we get is data for the return event');
is($e2->data(), 'And here is some data back', 'and that the data is correct for the return event');

done_testing();
