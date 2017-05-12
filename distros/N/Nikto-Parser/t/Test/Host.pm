#!/usr/bin/perl

package t::Test::Host;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
    
    is ( $self->{host1}->ip, '127.0.0.1', 'host ip');    
    is ( $self->{host1}->hostname, 'localhost', 'host hostname');    

    is ( $self->{host2}->ip, '10.0.0.1', 'host ip');   
    is ( $self->{host2}->hostname, 'notlocal', 'host hostname');   

    my $parser = $self->{parser1};
    my $host = $parser->get_host('127.0.0.1');

    my @ports = $host->get_all_ports();
    my $first_port = $ports[0];
    is ( $first_port->port(), '80', 'port');
    is ( $first_port->banner(), 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'port banner');
    is ( $first_port->start_scan_time(), '2009-09-02 2:00:02', 'port start scan time');
    #is ( $first_port->end_scan_time(), '2008-04-28 19:20:24', 'port end scan time');

    my @hosts = $parser->get_all_hosts()  ;
    my $host1 = $hosts[0];
    my $host2 = $hosts[1];
    is ( $host1->ip(),'127.0.0.1','get_all_hosts(): Host1 IP');
    is ( $host2->ip(),'127.0.0.1','get_all_hosts(): Host2 IP');
    
    @ports = $host1->get_all_ports();
    $port = $ports[0];
    is ( $port->port(), '80', 'port');
    is ( $port->banner(), 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'port banner');
    is ( $port->start_scan_time(), '2009-09-02 2:00:02', 'port start scan      time');
#    is ( $port->end_scan_time(), '2008-04-28 19:20:24', 'port end scan time');

    # host and host1 are the same host
    $port = $host->get_port('80');
    is ( $port->port(), '80', 'port');
    is ( $port->banner(), 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'port banner');
    is ( $port->start_scan_time(), '2009-09-02 2:00:02', 'port start scan time');
#    is ( $port->end_scan_time(), '2008-04-28 19:20:24', 'port end scan time');
    
    $port = $host1->get_port('80');
    is ( $port->port(), '80', 'host1 port 80 port');
    is ( $port->banner(), 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'host1 port 80  banner');
    is ( $port->start_scan_time(), '2009-09-02 2:00:02', 'host1 port 80 start scan time');
#    is ( $port->end_scan_time(), '2008-04-28 19:20:24', 'host1 port 80 end scan time');
    
    $port = $host2->get_port('80');
    is ( $port->port(), '80', 'host2 port 80 port');
    is ( $port->banner(), 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'host2 port 80 banner');
    is ( $port->start_scan_time(), '2009-09-02 2:00:02', 'host2 port 80 start scan time');
#    is ( $port->end_scan_time(), '2008-04-28 19:20:43', 'host2 port 80 port end scan time');
#    is ( $port->items_tested(), '2967', 'host2 port 80 items_tested');
#    is ( $port->items_found(), '6', 'host2 port 80 items_found');
}
1;
