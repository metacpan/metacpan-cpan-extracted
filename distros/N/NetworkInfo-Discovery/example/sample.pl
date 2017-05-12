#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib );

use warnings;
use strict;

use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Register;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;

my $d = new NetworkInfo::Discovery::Register ('file' => 'sample.register', 'autosave' => 1) 
    || warn ("failed to make new obj");

my $s = new NetworkInfo::Discovery::Sniff;


$s->maxcapture(10);
$s->do_it;
$d->add_interface($_) for ($s->get_interfaces);


my @traced;
foreach my $h ($s->get_interfaces) {
    (print "----- already traced to " . $h->{ip} . "\n" && next ) if (grep { $_ eq $h->{ip}  } @traced);
    print "Tracing to " . $h->{ip} . "\n";
    push (@traced, $h->{ip}); 

    my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->{ip});
    $t->do_it;
    $d->add_interface($_) for ($t->get_interfaces);
    $d->add_gateway($_) for ($t->get_gateways);
}

$d->write_register;
$d->print_register;
