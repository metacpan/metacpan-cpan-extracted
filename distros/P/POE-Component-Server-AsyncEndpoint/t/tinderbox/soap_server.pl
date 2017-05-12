#!/usr/bin/perl
# simple SOAP Server for Testing
# perl Cookbook Recipe 18.13



use SOAP::Transport::HTTP;
use warnings;
use strict;


my $daemon = SOAP::Transport::HTTP::Daemon
    -> new (LocalPort => 8081)
    -> dispatch_with ({'urn://MyTestSOAPClass' => 'MyTestSOAPClass'})
    -> dispatch_to('MyTestSOAPClass')
    ->handle();




package MyTestSOAPClass;
use SOAP::Lite;


sub test1{

    my ($class, $args) = @_;

    my $soapdata = SOAP::Data
        -> name('myname')
        -> type('string')
        -> uri('MySOAPClass')
        -> value('HELLO THERE');

    return $soapdata;

}



1;
