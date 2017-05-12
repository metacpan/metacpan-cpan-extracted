# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 3;
use t::TestMockListener;
use t::TestEtherealGlue;
use Storable qw(nstore retrieve);

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;

#########################

BEGIN { use_ok('Net::Analysis::Listener::TCP') }

#### Create Dispatcher, TCP listener, and mock object listening for TCP events
#
my ($d)     = Net::Analysis::Dispatcher->new();
my ($l_tcp) = Net::Analysis::Listener::TCP->new (dispatcher => $d);
my ($mock)  = mock_listener (qw(tcp_session_start
                                tcp_session_end
                                tcp_monologue));
$d->add_listener (listener => $mock);

#### Simple manual test for google ...
#
my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);
$el->loop_file (filename => "t/t1_google.tcp");

my (@found_ev);
while (my (@call) = $mock->next_call()) {
    #print ">> $call[0] (". join(',', sort keys %{$call[1][2]} ).")\n";
    push (@found_ev, $call[0]);
}

# Now look at the emitted events - check they match what we expect from google
my (@ev) = qw(tcp_session_start tcp_monologue tcp_monologue tcp_session_end);
is_deeply (\@found_ev, \@ev, "basic TCP events for t1_google");


#### Test for max_session stuff
#
{
    my ($max_session_size) = (5000);
    my ($d)     = Net::Analysis::Dispatcher->new();
    my ($l_tcp) = Net::Analysis::Listener::TCP->new
        (dispatcher => $d,
         config => {max_session_size => $max_session_size}
        );
    my ($mock)  = mock_listener (qw(tcp_session_start
                                    tcp_session_end
                                    _internal_tcp_packet
                                    tcp_monologue));
    $d->add_listener (listener => $mock);

    my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);
    $el->loop_file (filename => "t/t8_multi_pkt_mono.tcp");

    # Check that the final output monologue is only $max_session_size bytes.
    # Check that not all packet events were emitted.
    my (@found_ev);
    my (@mono);
    while (my (@call) = $mock->next_call()) {
        #print ">> $call[0] (". join(',', sort keys %{$call[1][1]} ).")\n";
        push (@found_ev, $call[0]);
        push (@mono, $call[1][1]{monologue}) if (exists $call[1][1]{monologue});
    }

    # This mono would be 26125 bytes without truncation via max_session_size
    is ($mono[1]->length(), 5792, "that mono is truncated");
}


__END__

# I don't like these tests. They essentially repeat the 21_TCPSession tests in
#  a brittle fashion.

#### Step through our TCP test files ...
#
foreach my $test_file (list_testfiles(qr/./)) {
    my $fname = "t/$test_file.tcp";
    my (@calls);

    # Create fresh objects, in case they leak state
    my ($d)     = Net::Analysis::Dispatcher->new();
    my ($l_tcp) = Net::Analysis::Listener::TCP->new (dispatcher => $d);
    my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);
    $d->add_listener (listener => $mock); # Reuse mock object
    $el->loop_file (filename => $fname);

    # Now look at the emitted events
    while (my (@call) = $mock->next_call()) {
        #print "-- $call[0]\n";
        push (@calls, \@call);
    }

    if (0) {
        # When things look OK, use this to create events.TCP compare_file
        nstore (\@calls, "t/$test_file.events.TCP")
            || die "could not store into $test_file.events.TCP\n";
        #die Data::Dumper::Dumper (\@calls);

    } else {
        # Load in events file
        my ($events) = retrieve("t/$test_file.events.TCP")
            || die "could not retrieve from $test_file.events\n";

        is_deeply (\@calls, $events, "TCP events emitted for '$test_file'");
    }
}
