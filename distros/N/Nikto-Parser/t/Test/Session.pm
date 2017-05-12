#!/usr/bin/perl

package t::Test::Session;

use base 't::Test';
use Test::More;

sub fields : Tests {
    my ($self) = @_;

    is ( $self->{session1}->options, '-Format xml -output out.xml', 'options');    
    is ( $self->{session1}->version, '2.04', 'version');    
    is ( $self->{session1}->nxmlversion, '1.0', 'nxmlversion');    

    is ( $self->{xmlsession1}->options, '-host hostnikto.txt -Format xml -output test1.xml');
    is ( $self->{xmlsession1}->version, '2.1.0', 'version');
    is ( $self->{xmlsession1}->nxmlversion, '1.1', 'nxmlversion');

    my $session1 = $self->{parser1}->session;
    my $scandetails1 = $self->{parser1}->session->scandetails;
    
    is ( $session1->options, '-host hostnikto.txt -Format xml -output test1.xml', 'options');
    is ( $session1->version, '2.1.0', 'version');
    is ( $session1->nxmlversion, '1.1', 'nxmlversion');
}
1;
