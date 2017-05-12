#!/usr/bin/perl

package t::Test::Port;

use base 't::Test';
use Test::More;

sub fields : Tests {
    my ($self) = @_;
=begin
       $self->{port1} = Port->new(     port => 80,
                                    banner => 'HTTP',
                                    start_time => 1,
                                    end_time => 2000,
                                    elasped => 20,
                                    items => [],
                                    items_tested => 100,
                                    items_found => 2
                                );
    $self->{port2} = Port->new(     port => 443,
                                    banner => 'HTTPS',
                                    start_time => 1,
                                    end_time => 1000,
                                    elasped => 20
                                    items_tested => 100,
                                    items_found => 5,
                                    items => [ $self->{item2} ],
                                );
    $self->{port3} = Port->new(     port => 8080,
                                    banner => 'HTTPS',
                                    start_time => 1,
                                    end_time => 1000,
                                    elasped => 20
                                    items_tested => 100,
                                    items_found => 5,
                                    items => [ $self->{item1},  $self->{item2} ],
                                );

=end
=cut

    is ( $self->{port1}->port, 80, 'port');    
    is ( $self->{port1}->banner, 'HTTP', 'port banner');    
    is ( $self->{port1}->start_scan_time, 1, 'port start scan time');    
    is ( $self->{port1}->end_scan_time, 2000, 'port end scan time');    
    is ( $self->{port1}->elasped_scan_time, 20, 'port elapsed scan time');    
    is ( scalar(@{$self->{port1}->items}), 0, 'ports items');    
    is ( $self->{port1}->items_tested, 100 , 'port items tested');    
    is ( $self->{port1}->items_found, 2, 'port items found');    

    is ( $self->{port2}->port, 443, 'port');    
    is ( $self->{port2}->banner, 'HTTPS', 'port banner');    
    is ( $self->{port2}->start_scan_time, 1, 'port start scan time');    
    is ( $self->{port2}->end_scan_time, 1000, 'port end scan time');    
    is ( $self->{port2}->elasped_scan_time, 20, 'port elapsed scan time');    
    
    is ( @{$self->{port2}->items}[0]->description,'this is a description2' , 'ports items description');    
    is ( @{$self->{port2}->items}[0]->id,2 , 'ports items id ');    
    is ( @{$self->{port2}->items}[0]->osvdbid,200 , 'ports items osvdbid');    
    is ( @{$self->{port2}->items}[0]->osvdblink,'http://osvdblink.com/200' , 'ports items osvdblink');    
    is ( @{$self->{port2}->items}[0]->method,'POST' , 'ports items osvdbid');    
    is ( @{$self->{port2}->items}[0]->uri,'http://127.0.0.1' , 'ports items uri');    
    is ( @{$self->{port2}->items}[0]->namelink,'http://localhost' , 'ports items namelink');    
    is ( @{$self->{port2}->items}[0]->iplink,'http://127.0.0.1' , 'ports items iplink');    
    is ( $self->{port2}->items_tested, 100 , 'port items tested');    
    is ( $self->{port2}->items_found, 5, 'port items found');    


    is ( @{$self->{host1}->ports}[0]->port, 80, 'port');
    is ( @{$self->{host1}->ports}[0]->banner, 'HTTP', 'port banner');
    is ( @{$self->{host1}->ports}[0]->start_scan_time, 1, 'port start scan time');
    is ( @{$self->{host1}->ports}[0]->end_scan_time, 2000, 'port end scan time');
    
    is ( @{$self->{host1}->ports}[1]->port, 443, 'port');
    is ( @{$self->{host1}->ports}[1]->banner, 'HTTPS', 'port banner');
    is ( @{$self->{host1}->ports}[1]->start_scan_time, 1, 'port start scan time');
    is ( @{$self->{host1}->ports}[1]->end_scan_time, 1000, 'port end scan time');
    is ( @{$self->{host1}->ports}[1]->elasped_scan_time, 20, 'port elapsed scan time');

}
1;
