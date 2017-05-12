#!/usr/bin/perl -W
use strict;
use Net::P0f;

my $p0f = new Net::P0f backend => 'cmd', interface => 'eth0', 
    program_path => '/usr/local/src/p0f/p0f', 
    fingerprints_file => '/usr/local/src/p0f/p0f.fp';
$p0f->loop(callback => \&packet, count => 2);

sub packet {
    my($self,$header,$os_info,$link_info) = @_;
    printf "TCP stream from %s:%s to %s:%s\n" .
           "  %s is probably a %s machine (%s %s)%s\n" .
           "  connected by %s, at a distance of %d\n", 
        $header->{ip_src}, $header->{port_src}, $header->{ip_dest}, $header->{port_dest}, 
        $header->{ip_src}, $os_info->{genre}, $os_info->{genre}, $os_info->{details}, 
        ($os_info->{uptime} ? " up since $$os_info{uptime} hours" : ''), 
        $link_info->{link_type}, $link_info->{distance};
}
