#!/usr/bin/perl

package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;

    my $session1 = $self->{parser1}->session;
    my $scandetails1 = $self->{parser1}->session->scandetails;
    
    is ( $session1->options, '-host hostnikto.txt -Format xml -output test1.xml', 'options');
    is ( $session1->version, '2.1.0', 'version');
    is ( $session1->nxmlversion, '1.1', 'nxmlversion');

    my $host1 =  $self->{parser1}->get_host('127.0.0.1');
    is ( $host1->ip, '127.0.0.1', 'hoststest');
    is ( $host1->hostname, 'localhost', 'hoststest');
    is ( @{$host1->ports}[0]->port, '80', 'xmlscandetails1 host 1 port');

    is ( @{$host1->ports}[0]->banner, 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'xmlscandetails1 host 1 banner');
    is ( @{$host1->ports}[0]->start_scan_time, '2009-09-02 2:00:02', 'xmlscandetails1 host 1 start scan time');
    is ( @{$host1->ports}[0]->end_scan_time, undef,, 'xmlscandetails1 host 1 end scan time');
    is ( @{$host1->ports}[0]->elasped_scan_time, undef, 'xmlscandetails1 host 1 elasped scan time');
    is ( @{$host1->ports}[0]->sitename, 'http://localhost:80/', 'xmlscandetails1 host 1 sitename');
    is ( @{$host1->ports}[0]->siteip, 'http://127.0.0.1:80/', 'xmlscandetails1 host 1 siteip');
    is ( @{$host1->ports}[0]->items_found, undef, 'xmlscandetails1 host 1 items found');
    is ( @{$host1->ports}[0]->items_tested, undef, 'xmlscandetails1 host 1 items tested');


    is ( @{$scandetails1->hosts}[0]->ip, '127.0.0.1', 'hoststest');
    is ( @{$scandetails1->hosts}[0]->hostname, 'localhost', 'hoststest');

    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->port, '80', 'xmlscandetails1 host 1 port');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->banner, 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch', 'xmlscandetails1 host 1 banner');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->start_scan_time, '2009-09-02 2:00:02', 'xmlscandetails1 host 1 start scan time');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->end_scan_time, undef, 'xmlscandetails1 host 1 end scan time');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->elasped_scan_time, undef, 'xmlscandetails1 host 1 elasped scan time');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->sitename, 'http://localhost:80/', 'xmlscandetails1 host 1 sitename');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->siteip, 'http://127.0.0.1:80/', 'xmlscandetails1 host 1 siteip');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->items_found, undef, 'xmlscandetails1 host 1 items found');
    is ( @{@{$scandetails1->hosts}[0]->ports}[0]->items_tested, undef, 'xmlscandetails1 host 1 items tested');

    $host1 =  $self->{parser2}->get_host('127.0.0.1');
    is ( $host1->ip, '127.0.0.1', 'hoststest');
    is ( $host1->hostname, 'localhost', 'hoststest');
    is ( @{$host1->ports}[0]->port, '80', 'xmlscandetails1 host 1 port');

    is ( @{$host1->ports}[0]->banner, 'Apache/2.2.9 (Ubuntu) PHP/5.2.6-bt0 with Suhosin-Patch mod_perl/2.0.4 Perl/v5.10.0', 'xmlscandetails1 host 1 banner');
    #
    # nikto bug reported...
    is ( @{$host1->ports}[0]->start_scan_time, '1969-12-32 19:00:00', 'xmlscandetails1 host 1 start scan time');
    #
    is ( @{$host1->ports}[0]->end_scan_time, '2009-10-17 14:37:43',, 'xmlscandetails1 host 1 end scan time');
    is ( @{$host1->ports}[0]->elasped_scan_time, 28, 'xmlscandetails1 host 1 elasped scan time');
    is ( @{$host1->ports}[0]->sitename, 'http://localhost:80/', 'xmlscandetails1 host 1 sitename');
    is ( @{$host1->ports}[0]->siteip, 'http://127.0.0.1:80/', 'xmlscandetails1 host 1 siteip');
    is ( @{$host1->ports}[0]->items_found, 11, 'xmlscandetails1 host 1 items found');
    is ( @{$host1->ports}[0]->items_tested, 3582, 'xmlscandetails1 host 1 items tested');
}
1;
