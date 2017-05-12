#!/usr/bin/perl

package t::Test::ScanDetails;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
    my $host1 = @{$self->{scandetails1}->hosts}[0];

    my @hosts = $self->{scandetails1}->all_hosts();
    is ( $hosts[0]->ip, '127.0.0.1', 'all_hosts ip');
    is ( $hosts[0]->hostname, 'localhost', 'all_hosts hostname');

    is ( $self->{scandetails1}->get_host_ip('127.0.0.1')->ip, '127.0.0.1', 'get_host_ip ip');
    is ( $self->{scandetails1}->get_host_ip('127.0.0.1')->hostname, 'localhost', 'get_host_ip hostname');

    #is ( $host1->hostname, 'localhost', 'host hostname');

    #is ( $host_lookup[0]->ip, '127.0.0.1', 'host ip');    
    #is ( $host_lookup[0]->hostname, 'localhost', 'host hostname');    


    is ( $host1->ip, '127.0.0.1', 'host ip');    
    is ( $host1->hostname, 'localhost', 'host hostname');    
    my $host2 = @{$self->{scandetails2}->hosts}[1];
    is ( $host2->ip, '10.0.0.1', 'host ip');   
    is ( $host2->hostname, 'notlocal', 'host hostname');   

    is ( @{$host1->ports}[0]->banner, 'HTTP', 'port banner');    
    is ( @{$host1->ports}[0]->start_scan_time, 1, 'port start scan time');    
    is ( @{$host1->ports}[0]->end_scan_time, 2000, 'port end scan time');    
    
    is ( @{$host2->ports}[0]->port, 443, 'port');    
    is ( @{$host2->ports}[0]->banner, 'HTTPS', 'port banner');    
    is ( @{$host2->ports}[0]->start_scan_time, 1, 'port start scan time');    
    is ( @{$host2->ports}[0]->end_scan_time, 1000, 'port end scan time');    
    is ( @{$host2->ports}[0]->elasped_scan_time, 20, 'port elapsed scan time');    
   
    is ( @{$self->{xmlscandetails1}->hosts}[0]->ip, '127.0.0.1', 'hoststest');
    is ( @{$self->{xmlscandetails1}->hosts}[0]->hostname, 'localhost', 'hoststest');

    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->port, '80', 'xmlscandetails1 host 1 port');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->banner, 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'xmlscandetails1 host 1 banner');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->start_scan_time, '2009-09-02 2:00:02', 'xmlscandetails1 host 1 start scan time');
    #is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->end_scan_time, 'undef', 'xmlscandetails1 host 1 end scan time');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->elasped_scan_time, undef, 'xmlscandetails1 host 1 elasped scan time');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->sitename, 'http://localhost:80/', 'xmlscandetails1 host 1 sitename');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->siteip, 'http://127.0.0.1:80/', 'xmlscandetails1 host 1 siteip');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->items_found, undef, 'xmlscandetails1 host 1 items found');
    is ( @{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->items_tested, undef, 'xmlscandetails1 host 1 items tested');

    is ( @{$self->{xmlscandetails1}->hosts}[1]->ip, '127.0.0.1', 'hoststest');
    is ( @{$self->{xmlscandetails1}->hosts}[1]->hostname, 'localhost', 'hoststest');

    my @items = @{@{@{$self->{xmlscandetails1}->hosts}[0]->ports}[0]->items};
    is ( $items[0]->id, '999100', 'hosts 1 item 1 id');
    is ( $items[0]->description, 'Non-standard header keep-alive returned by server, with contents: timeout=15, max=100', 'hosts 1 item 1 description');
    is ( $items[0]->osvdbid, 0, 'hosts 1 item 1 osvdbid');
    is ( $items[0]->osvdblink, 'http://osvdb.org/0', 'hosts 1 item 1 osvdbid');
    is ( $items[0]->method, 'GET', 'hosts 1 item 1 method');
    is ( $items[0]->uri, '/', 'hosts 1 item 1 uri');
    is ( $items[0]->iplink, 'http://127.0.0.1:80/', 'hosts 1 item 1 iplinke');
    is ( $items[0]->namelink, 'http://localhost:80/', 'hosts 1 item 1 namelink');

    is ( $items[1]->id, '600050', 'hosts 1 item 2 id');
    is ( $items[1]->description, 'Apache/2.2.9 appears to be outdated (current is at least Apache/2.2.11). Apache 1.3.41 and 2.0.63 are also current.','hosts 1 item 2 description');

    is ( $items[2]->id, '699999', 'hosts 1 item 3 id');
    is ( $items[2]->description, "Number of sections in the version string differ from those in the database, the server reports: 5.2.6.45.98.116.0 while the database has: 5.2.6. This may cause false positives.", 'hosts 1 item 3 description');
    is ( $items[2]->uri, '/', 'hosts 1 item 3 uri');

    is ( $items[3]->id, '999990', 'hosts 1 item 4 id');
    is ( $items[3]->osvdbid, '0', 'hosts 1 item 4 osvdbid');
    is ( $items[3]->osvdblink, 'http://osvdb.org/0', 'hosts 1 item 4 osvdblink');
    is ( $items[3]->method, 'GET', 'hosts 1 item 4 method');
    is ( $items[3]->description, "Allowed HTTP Methods: GET, HEAD, POST, OPTIONS, TRACE ", 'hosts 1 item 4 description');
    is ( $items[3]->uri, '/', 'hosts 1 item 4 uri');
    is ( $items[3]->namelink, 'http://localhost:80/', 'hosts 1 item 4 namelink');
    is ( $items[3]->iplink, 'http://127.0.0.1:80/', 'hosts 1 item 4 iplink');

    is ( $items[4]->id, '999979', 'hosts 1 item 5 id');
    is ( $items[4]->osvdbid, '877', 'hosts 1 item 5 osvdbid');
    is ( $items[4]->osvdblink, 'http://osvdb.org/877', 'hosts 1 item 5 osvdblink');
    is ( $items[4]->method, 'GET', 'hosts 1 item 5 method');
    is ( $items[4]->description, "HTTP method ('Allow' Header): 'TRACE' is typically only used for debugging and should be disabled. This message does not mean the server is vulnerable to XST.",'hosts 1 item 5 description');
    is ( $items[4]->uri, '/', 'hosts 1 item 5 uri');
    is ( $items[4]->namelink, 'http://localhost:80/', 'hosts 1 item 5 namelink');
    is ( $items[4]->iplink, 'http://127.0.0.1:80/', 'hosts 1 item 5 iplink');
   
    is ( $items[5]->id, '999971', 'hosts 1 item 6 id');
    is ( $items[5]->osvdbid, '877', 'hosts 1 item 6 osvdbid');
    is ( $items[5]->osvdblink, 'http://osvdb.org/877', 'hosts 1 item 6 osvdblink');
    is ( $items[5]->method, 'GET', 'hosts 1 item 6 method');
    is ( $items[5]->description, "HTTP TRACE method is active, suggesting the host is vulnerable to XST", 'hosts 1 item 6 description');
    is ( $items[5]->uri, '/', 'hosts 1 item 6 uri');
    is ( $items[5]->namelink, 'http://localhost:80/', 'hosts 1 item 6 namelink');
    is ( $items[5]->iplink, 'http://127.0.0.1:80/', 'hosts 1 item 6 iplink');

    is ( $items[6]->id, '001213', 'hosts 1 item 7 id');
    is ( $items[6]->osvdbid, '48', 'hosts 1 item 7 osvdbid');
    is ( $items[6]->osvdblink, 'http://osvdb.org/48', 'hosts 1 item 7 osvdblink');
    is ( $items[6]->method, 'GET', 'hosts 1 item 7 method');
    is ( $items[6]->description, '/doc/: The /doc/ directory is browsable. This may be /usr/doc.', 'hosts 1 item 7 description');
    is ( $items[6]->uri, '/doc/', 'hosts 1 item 7 uri');
    is ( $items[6]->namelink, 'http://localhost:80/doc/', 'hosts 1 item 7 namelink');
    is ( $items[6]->iplink, 'http://127.0.0.1:80/doc/', 'hosts 1 item 7 iplink');
}
1;
