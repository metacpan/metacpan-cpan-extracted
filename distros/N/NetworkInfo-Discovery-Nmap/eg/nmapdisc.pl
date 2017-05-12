#!/usr/bin/perl
use strict;
use NetworkInfo::Discovery::Nmap;

print STDERR "usage: $0 IP_addr [IP_addr ...]\n" and exit unless @ARGV;

my $scanner = new NetworkInfo::Discovery::Nmap hosts => [ @ARGV ], guess_system => 1;
$scanner->do_it;

for my $host ($scanner->get_interfaces) {
    print 'Host ', $host->{ip}, ($host->{mac}?' (MAC: '.$host->{mac}.')':''), $/;
    
    for my $service (@{$host->{services}}) {
        printf "%5d/%s  %5s  %-15s  %s\n", $service->{port}, $service->{protocol}, 
            $service->{state}, $service->{name}, ( $service->{application} ? 
                join ' ', $service->{application}{product}, $service->{application}{version}, 
                '(' . $service->{application}{extrainfo} . ')' : ''
            )
    }
    
    if($host->{system_info}) {
        printf "Uptime: %ds, last boot: %s\n", 
            $host->{system_info}{uptime}, $host->{system_info}{last_boot};
        
        my %os_class = ();
        @os_class{qw(accuracy version family vendor type)} = ('') x 5;
        
        for my $class (@{$host->{system_info}{os_classes}}) {
            for my $attr (qw(accuracy version family vendor type)) {
                $os_class{$attr} .= ', '.$class->{$attr} 
                  unless index($os_class{$attr}, $class->{$attr}) >= 0
            }
        }
        
        for my $attr (qw(accuracy version family vendor type)) {
            $os_class{$attr} =~ s/^, //;
        }
        
        printf "Device type: %s\nRunning: %s %s\nDetails: %s", 
            $os_class{type}, $os_class{family}, $os_class{version}, 
            join(', ', map {$_->{name}} @{$host->{system_info}{os_matches}});
    }
    
    print $/;
}
