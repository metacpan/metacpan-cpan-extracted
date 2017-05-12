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

#it's a good idea to reset the acls before making a new acl list
$d->clear_acl;
$d->add_acl("allow", "10.20.1.0/24");
$d->add_acl("deny", "0.0.0.0/0");

my $s = new NetworkInfo::Discovery::Sniff ("maxcapture" => $sniffmax);
$s->do_it;


my @traced;
foreach my $h ($s->get_interfaces) {

    
    # this is actually done in the add_interface, but print it here so we show the test
    if ($d->test_acl($h->{ip})) {
	print "acls passed host " . $h->{ip} . "\n";
    } else {
	print "acls denied host " . $h->{ip} . "\n";
    }

    # this automatically tests againt the acl
    if ($d->add_interface($h) ) {
	if (grep { $_ eq $h->{ip}  } @traced) {
	    print "----- already traced to " . $h->{ip} . " skipping it this time!\n";
	    next;
	} 

        print "Tracing to " . $h->{ip} . "\n";
        push (@traced, $h->{ip}); 
    
        my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->{ip}, max_ttl=>4);
    
        $t->do_it;
        $d->add_interface($_) for ($t->get_interfaces);
        $d->add_gateway($_) for ($t->get_gateways);
    
        foreach my $thost ($t->get_interfaces) {
	    #again, these acls are run automaicly... just showing you...
	    if ($d->test_acl($thost->{ip})) {
		print "acls passed host " . $thost->{ip} . "\n";
	    } else {
		print "acls denied host " . $thost->{ip} . "\n";
	    }
        }
    }
}

$d->print_register;

