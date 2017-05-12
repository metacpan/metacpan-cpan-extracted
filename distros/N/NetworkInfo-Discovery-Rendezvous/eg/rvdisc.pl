#!/usr/bin/perl
use strict;
use NetworkInfo::Discovery::Rendezvous;

@ARGV = qw(local.) and print "No domain specified. Using 'local.'\n" unless @ARGV;

my $scanner = new NetworkInfo::Discovery::Rendezvous domain => [ @ARGV ];
$scanner->do_it;

for my $service (sort {$a->{name} cmp $b->{name}} $scanner->get_services) {
    printf "--- %s ---\n", $service->{name};
    
    for my $host (sort @{$service->{hosts}}) {
        printf "  %s (%s:%s:%d)\n    %s\n", $host->{nodename}, $host->{ip}, 
            $host->{services}[0]{protocol}, $host->{services}[0]{port}, join(', ', 
                map { $_ && $_.'='.$host->{services}[0]{attrs}{$_} } keys %{$host->{services}[0]{attrs}}
            ) || ''
    }
}
