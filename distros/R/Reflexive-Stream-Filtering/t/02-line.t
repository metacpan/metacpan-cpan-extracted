use warnings;
use strict;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use POE::Filter::Line;
use POE::Filter::Stream;

BEGIN
{
    use_ok('Reflexive::Stream::Filtering');
}

my ($socket1, $socket2);
socketpair($socket1, $socket2, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die $!;
my $line1 = POE::Filter::Line->new();
my $line2 = POE::Filter::Line->new();

my $filtered_stream1 = Reflexive::Stream::Filtering->new(handle => $socket1, input_filter => $line1, output_filter => $line1);
my $filtered_stream2 = Reflexive::Stream::Filtering->new(handle => $socket2, input_filter => $line2, output_filter => $line2);

$filtered_stream1->put("Here is some test data\r\n1\r\n2\r\n3");

my $e_count = 0;
while(my $e = $filtered_stream2->next())
{
    $e_count++;
    is($e->_name(), 'data', 'make sure the event we get is data 1/5');
    if($e_count == 1)
    {
        is($e->data(), 'Here is some test data', 'and that the data is correct 2/5');
    }
    elsif($e_count == 2)
    {
        is($e->data(), '1', 'Got the next element 3/5');
    }
    elsif($e_count == 3)
    {
        is($e->data(), '2', 'Got the next element 4/5');
    }
    elsif($e_count == 4)
    {
        is($e->data(), '3', 'Got the next element 5/5');
        last;
    }
}

is($e_count, 4, 'Got the right number of events');

$filtered_stream2->put("And here is some data back\r\n3\r\n2\r\n1");

my $e_count2 = 0;
while(my $e2 = $filtered_stream1->next())
{
    $e_count2++;
    is($e2->_name, 'data', 'make sure the return event we get is data 1/5');
    if($e_count2 == 1)
    {
        is($e2->data(), 'And here is some data back', 'and that the return data is correct 2/5');
    }
    elsif($e_count2 == 2)
    {
        is($e2->data(), '3', 'Got the next element 3/5');
    }
    elsif($e_count2 == 3)
    {
        is($e2->data(), '2', 'Got the next element 4/5');
    }
    elsif($e_count2 == 4)
    {
        is($e2->data(), '1', 'Got the next element 5/5');
        last;
    }
}

is($e_count2, 4, 'Got the right number of events');

# swap the filters live

$filtered_stream1->input_filter(POE::Filter::Stream->new());
$filtered_stream1->output_filter(POE::Filter::Stream->new());

$filtered_stream2->input_filter(POE::Filter::Stream->new());
$filtered_stream2->output_filter(POE::Filter::Stream->new());

$filtered_stream1->put("Some data\r\n1\r\n2\r\n3\r\n");

my $e = $filtered_stream2->next();
is($e->data(), "Some data\r\n1\r\n2\r\n3\r\n", 'after first filter change');

$filtered_stream2->put("Return data\r\n3\r\n2\r\n1\r\n");

$e = $filtered_stream1->next();
is($e->data(), "Return data\r\n3\r\n2\r\n1\r\n", 'after second filter change');

done_testing();
