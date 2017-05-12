#!/usr/bin/perl

use strict;
use warnings;

# provide a SOAP webcat interface to PICA+Wiki

use SOAP::Transport::HTTP;
use PICA::SOAPServer;
use PICA::Store;

my $server = eval {
    PICA::SOAPServer->new( 
        PICA::SQLiteStore->new( config => 'picawiki.conf' )
    );
} or FailServer->new($@);

SOAP::Transport::HTTP::CGI   
    -> serializer( SOAP::Serializer->new->envprefix('soap') )
    -> dispatch_with( { 'http://www.gbv.de/schema/webcat-1.0' => $server } )
    -> handle;

# SOAP Server that always returns an error
package FailServer;
use SOAP::Lite;
our @ISA = qw(SOAP::Server::Parameters);

sub new {
    my $msg = $_[1] ? $_[1] : 'failed to set up SOAP Server';
    bless { error => $msg }, $_[0];
}
sub get { 
    die SOAP::Fault->new( faultcode => 0, faultstring => $_[0]->{error} ); 
}
sub create { $_[0]->get; }
sub update { $_[0]->get; }
sub delete { $_[0]->get; }

1;