#!/usr/bin/perl

package t::Test::Item;

use base 't::Test';
use Test::More;

sub fields : Tests {
    my ($self) = @_;

    is ( $self->{item1}->description, 'this is a description', 'item description');    
    is ( $self->{item1}->id, 1, 'item id');    
    is ( $self->{item1}->osvdbid, 100, 'item osvdbid');    
    is ( $self->{item1}->osvdblink, 'http://osvdblink.com/100', 'item osvdblink');    
    is ( $self->{item1}->method, 'GET', 'item method');    
    is ( $self->{item1}->uri, 'http://127.0.0.1', 'item uri');    
    is ( $self->{item1}->namelink, 'http://localhost', 'item namelink');    
    is ( $self->{item1}->iplink, 'http://127.0.0.1', 'item iplink');    

    is ( $self->{item2}->description, 'this is a description2', 'item description');    
    is ( $self->{item2}->id, 2, 'item id');    
    is ( $self->{item2}->osvdbid, 200, 'item osvbid');    
    is ( $self->{item2}->osvdblink, 'http://osvdblink.com/200', 'item osvdblink');    
    is ( $self->{item2}->method, 'POST', 'item method');    
    is ( $self->{item2}->uri, 'http://127.0.0.1', 'item uri');    
    is ( $self->{item2}->namelink, 'http://localhost', 'item namelink');    
    is ( $self->{item2}->iplink, 'http://127.0.0.1', 'item iplink');    

    my $parser = $self->{parser1};
    my $host = $parser->get_host('127.0.0.1');
    my $port = $host->get_port('80');

    my @items =  $port->get_all_items();
    is ( scalar(@items), 10, 'port->get_all_items');
    is ( $items[0]->id(), '999100', 'get_all_items: item0 id');
    is ( $items[0]->description(), 'Non-standard header keep-alive returned by server, with contents: timeout=15, max=100', 'get_all_items: item0 description');
    is ( $items[1]->id(), '600050', 'get_all_items: item1 id');
    is ( $items[1]->description(), 'Apache/2.2.9 appears to be outdated (current is at least Apache/2.2.11). Apache 1.3.41 and 2.0.63 are also current.', 'get_all_items: id');

    is ( $items[0]->osvdbid(), 0, 'get_all_items: item0 osvdbid');
    is ( $items[0]->osvdblink(), 'http://osvdb.org/0', 'get_all_items: item0 osvdblink');
    is ( $items[0]->uri(), '/', 'get_all_items: item0 uri');
    is ( $items[0]->namelink(), 'http://localhost:80/',
        'get_all_items: item0 namelink');
    is ( $items[0]->iplink(), 'http://127.0.0.1:80/',
        'get_all_items: item0 iplink');

 
    is ( $items[3]->id(), '999990', 'get_all_items: item3 id');
    is ( $items[3]->osvdbid(), '0', 'get_all_items: item3 osvdbid');
    is ( $items[3]->osvdblink(), 'http://osvdb.org/0', 'get_all_items: item3 osvdblink');
    is ( $items[3]->uri(), '/', 'get_all_items: item3 uri');
    is ( $items[3]->namelink(), 'http://localhost:80/',
        'get_all_items: item3 namelink');
    is ( $items[3]->iplink(), 'http://127.0.0.1:80/',
        'get_all_items: item3 iplink');
}
1;
