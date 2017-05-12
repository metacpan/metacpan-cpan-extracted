#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib );

use warnings;
use strict;

use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Register;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;

my $sniffmax = 100;
my $d = new NetworkInfo::Discovery::Register ('file' => 'sample.register', 'autosave' => 1) 
    || warn ("failed to make new obj");


my @traced;

while (1) {
    # sniff for a while
    print "sniffing for $sniffmax packets\n";
    my $s = new NetworkInfo::Discovery::Sniff;
    $s->maxcapture($sniffmax);
    $s->do_it;
    my @hosts = $s->get_interfaces;

    print "found $#hosts  hosts and adding them to the list\n";

    $d->add_interface($_) for (@hosts);

    foreach my $h (@hosts) {
	(print "----- already traced to " . $h->{ip} . "\n" && next ) if (grep { $_ eq $h->{ip}  } @traced);
	print "Tracing to " . $h->{ip} . "\n";
	push (@traced, $h->{ip}); 
	my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->{ip}, max_ttl=>4);

	$t->do_it;
	$d->add_interface($_) for ($t->get_interfaces);
	$d->add_gateway($_) for ($t->get_gateways);
    }
    $d->write_register;
    $d->print_register;

}



