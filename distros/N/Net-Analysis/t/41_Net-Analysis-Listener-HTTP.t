# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 13;
use t::TestMockListener;

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;
use Net::Analysis::Listener::TCP;

#########################

BEGIN { use_ok('Net::Analysis::Listener::HTTP') }

#### Create Dispatcher, TCP listener, and mock object listening for TCP events
#
my ($d)      = Net::Analysis::Dispatcher->new();
my ($l_tcp)  = Net::Analysis::Listener::TCP->new (dispatcher => $d);
my ($l_http) = Net::Analysis::Listener::HTTP->new (dispatcher => $d);
my ($mock)   = mock_listener (qw(http_transaction));
$d->add_listener (listener => $mock);

#### Simple google test; check we get the right sequence of events
#
my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);
$el->loop_file (filename => "t/t1_google.tcp");

my (@found_ev);
my ($args);
while (my (@call) = $mock->next_call()) {
    #print ">> $call[0] (". join(',', sort keys %{$call[1][1]} ).")\n";
    push (@found_ev, $call[0]);
    $args = $call[1][1];
}

# Check that a single HTTP event was emitted
my (@ev) = qw(http_transaction);
is_deeply (\@found_ev, \@ev, "HTTP events for t1_google");

# Now check that the event had the right data
is ($args->{socketpair_key}, '145.246.233.194:33403-216.239.59.147:80', 'key');

is_deeply ([sort keys %{$args}],
           [sort qw(socketpair_key req resp req_mono resp_mono
                    t_start t_end t_elapsed)],
           'keys present');

# Check we have nice HTTP objects for the request and response
is   ($args->{req}->uri(),                      '/index.html', 'req1');
is   ($args->{resp}->header('content_length'),  1925,          'resp1');
like ($args->{req}->as_string(),  qr{Host: www.google.com}, 'req2');
like ($args->{resp}->as_string(), qr{Server: GWS/2.1},      'resp2');

# Check that the overall timings are here
is (sprintf ("%017.6f", $args->{t_start}),   '1096989582.687684', 't_start');
is (sprintf ("%017.6f", $args->{t_end}),     '1096989582.739386', 't_end');
is (sprintf ("%017.6f", $args->{t_elapsed}), '0000000000.051702', 't_elapsed');

# Now check that we have the monologue objects for more accurate timings
is (sprintf("%017.6f",$args->{req_mono}->t_end()), '1096989582.687684','req');
is (sprintf("%017.6f",$args->{resp_mono}->t_end()),'1096989582.739386','resp');

__DATA__
