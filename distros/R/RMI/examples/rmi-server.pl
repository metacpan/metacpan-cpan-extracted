#!/usr/bin/env perl
use RMI::Server::Tcp;
my $s = RMI::Server::Tcp->new(port => 1234); 
$s->run;
