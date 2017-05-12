# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 24;
use t::TestMockListener;

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;
use Net::Analysis::Listener::TCP;

#########################

BEGIN { use_ok('Net::Analysis::Listener::HTTPPipelining') }

#### Create Dispatcher, TCP listener, and mock object listening for TCP events
#
my ($d)      = Net::Analysis::Dispatcher->new();
my ($l_tcp)  = Net::Analysis::Listener::TCP->new (dispatcher => $d);
#my ($l_http) = Net::Analysis::Listener::HTTPPipelining->new (dispatcher => $d, config=>{v=>1});
my ($l_http) = Net::Analysis::Listener::HTTPPipelining->new (dispatcher => $d);
my ($mock)   = mock_listener (qw(http_transaction));
$d->add_listener (listener => $mock);

#### Simple google test; check we get the right sequence of events
#
my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);

$el->loop_file (filename => "t/t6_http_pipelining.tcp");
my (@data) =
    (
     ['/emp/embed.js' => 6332],
     ['/home/object/clock/tiny.swf' => 3721],
     ['/feedengine/homepage/images/iplayer/b00rpw2k_640_360_206x115.jpg' => 2929],
     ['/feedengine/homepage/images/music/9628_75x75.jpg' => 1911],
     ['/feedengine/homepage/images/music/pd3q_75x75.jpg' => 2785],
     ['/food/recipes/database/images/chefs/feed_chefs/6.jpg' => 23052],
     ['/feedengine/homepage/images/iplayer/b00rs21p_640_360_206x115.jpg' => 8820],
     ['/home/release-40-0/img/logofooter.png?+acv+ba+neaj+hj+oab*+c1+g1ab+mc2+rad*+da+f1a7b7c7d7+i+kca+la' => 404],
     ['/feedengine/homepage/images/iplayer/b00rqkvz_640_360_206x115.jpg' => 7975],
     ['/feedengine/homepage/images/iplayer/b00rt7ss_640_360_206x115.jpg' => 8832],
     );

my (@found_ev);
while (my (@call) = $mock->next_call()) {
    #print ">> $call[0] (". join(',', sort keys %{$call[1][1]} ).")\n";
    push (@found_ev, $call[0]);
    my $http_event_args = $call[1][1];
    #print "[".length($http_event_args->{resp}->content()) . "] ".
    #    $http_event_args->{req}->method()." ".$http_event_args->{req}->uri()."\n";

    my $expected = shift (@data);
    is ($http_event_args->{req}->uri(), $expected->[0],
        "URI is correct");
    is (length($http_event_args->{resp}->content()), $expected->[1],
        "size is correct");
}

$el->loop_file (filename => "t/t7_http_post.tcp");
while (my (@call) = $mock->next_call()) {
    #print ">> $call[0] (". join(',', sort keys %{$call[1][1]} ).")\n";
    my $http_event_args = $call[1][1];
    is ($http_event_args->{req}->uri(),
        "/~jbs/aw-wwwp/docs/resources/perl/perl-cgi/programs/cgi_stdin.cgi",
        "POST URI is OK");
    is (length($http_event_args->{req}->content()), 111,
        "POST request data length is OK");
    is (length($http_event_args->{resp}->content()), 275,
        "POST response data length is OK");
}


__DATA__
