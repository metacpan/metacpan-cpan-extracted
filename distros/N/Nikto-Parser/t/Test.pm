#!/usr/bin/perl
use Test::Class;     eval 'use Test::Class';
plan( skip_all => 'Test::Class required for additional testing' ) if $@;

package t::Test;
use Nikto::Parser;
use Nikto::Parser::Session;
use Nikto::Parser::Host;
use Nikto::Parser::Host::Port;
use Nikto::Parser::Host::Port::Item;
use Nikto::Parser::ScanDetails;

use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;
    
    $self->{session1} = Nikto::Parser::Session->new( 
                                    options => '-Format xml -output out.xml',
                                    version => '2.04',
                                    nxmlversion => '1.0');

    $self->{item1} = Nikto::Parser::Host::Port::Item->new(     description => 'this is a description',
                                    id => 1,
                                    osvdbid => 100,
                                    osvdblink => 'http://osvdblink.com/100',
                                    method => 'GET',
                                    uri => 'http://127.0.0.1',
                                    namelink => 'http://localhost',
                                    iplink => 'http://127.0.0.1');

    $self->{item2} = Nikto::Parser::Host::Port::Item->new(     description => 'this is a description2',
                                    id => 2,
                                    osvdbid => 200,
                                    osvdblink => 'http://osvdblink.com/200',
                                    method => 'POST',
                                    uri => 'http://127.0.0.1',
                                    namelink => 'http://localhost',
                                    iplink => 'http://127.0.0.1');

    $self->{port1} = Nikto::Parser::Host::Port->new(     port => 80,
                                    banner => 'HTTP',
                                    start_scan_time => 1,
                                    end_scan_time => 2000,
                                    elasped_scan_time => 20,
                                    items => [],
                                    items_tested => 100,
                                    items_found => 2
                                );
    $self->{port2} = Nikto::Parser::Host::Port->new(     port => 443,
                                    banner => 'HTTPS',
                                    start_scan_time => 1,
                                    end_scan_time => 1000,
                                    elasped_scan_time => 20,
                                    items_tested => 100,
                                    items_found => 5,
                                    items => [ $self->{item2} ],
                                );
    $self->{port3} = Nikto::Parser::Host::Port->new(     port => 8080,
                                    banner => 'HTTPS',
                                    start_scan_time => 1,
                                    end_scan_time => 1000,
                                    elasped_scan_time => 20,
                                    items_tested => 100,
                                    items_found => 5,
                                    items => [ $self->{item1},  $self->{item2} ],
                                );
    $self->{host1} = Nikto::Parser::Host->new(      ip => '127.0.0.1',
                                    hostname => 'localhost',
                                    ports => [ $self->{port1}, $self->{port2} ]);

    $self->{host2} = Nikto::Parser::Host->new(      ip => '10.0.0.1',
                                    hostname => 'notlocal',
                                    ports => [ $self->{port2}, $self->{port3} ]);
    
    $self->{scandetails1} = Nikto::Parser::ScanDetails->new(   hosts => [ $self->{host1} ] );
    
    $self->{scandetails2} = Nikto::Parser::ScanDetails->new(   hosts => [ $self->{host1}, $self->{host2} ] );
   
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file('t/test1.xml');

    $self->{xmlsession1} = Nikto::Parser::Session->parse($parser,$doc);
    $self->{xmlscandetails1} = Nikto::Parser::ScanDetails->parse($parser,$doc);

    $self->{parser1} = Nikto::Parser->parse_file('t/test1.xml');
    $self->{parser2} = Nikto::Parser->parse_file('t/test2.xml');
}
1;
