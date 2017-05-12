#!/usr/bin/perl

use lib 'lib';

package OsGuesser;

use Nmap::Scanner::Scanner;

use strict;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Scanner);

# $Nmap::Scanner::DEBUG = 1;

sub new {

    my $class = shift;
    my $self = $class->SUPER::new();

    my $target = $_[0] || die "Need target (host spec/file)!";
    $self->{'OS_SCAN_TARGET'} = $target;

    $self->tcp_syn_scan();
    $self->add_scan_port('1-5000');
    $self->guess_os();
    $self->register_scan_complete_event(\&complete);

    return bless $self, $class;

}

sub scan {

    die "Need callback!\n" unless $_[0]->{'CALLBACK'};

    my $target = $_[0]->{'OS_SCAN_TARGET'};

    if ( -r $target ) {

        $_[0]->SUPER::scan_from_file($target);

    } else {

        $_[0]->add_target($target);
        $_[0]->SUPER::scan();

    }

}

sub callback {
    $_[0]->{'CALLBACK'} = $_[1] || return $_[0]->{'CALLBACK'};
}

sub complete {
    &{$_[0]->{'CALLBACK'}}($_[0], $_[1]);
}

1;

use lib 'lib';

use strict;

use Nmap::Scanner;

my $os = OsGuesser->new($ARGV[0] || 
         die "Missing host to scan or file to scan from!\n$0 host\n");
$os->callback(\&guessed);
$os->scan();

sub guessed {
    
    my $self = shift;
    my $host = shift;
    my $name = $host->hostname();
    my $ip   = ($host->addresses())[0]->addr();
    my $os   = $host->os();

    unless ($os) {
        print "Could not guess anything about the OS of $name ($ip)\n";
        return;
    }

    if (scalar($os->osclasses()) > 0) {

        print "OS classes: $name ($ip) could be:\n";

        for my $osc ($os->osclasses()) {
            print ' * ',
                  join(' ', $osc->vendor(), ($osc->osgen() || "\b")) .
                  " (" .  $osc->accuracy() . "%)",
                  "\n";
        }

    }

    if (scalar($os->osfingerprint())) {
        print "OS fingerprint: \n";
        print '=' x 60 . "\n";
        print $os->osfingerprint()->fingerprint();
        print '=' x 60 . "\n";
    }

    if (scalar($os->osmatches()) > 0) {

        print "OS matches: $name ($ip) could be:\n";

        for my $m ($os->osmatches()) {
            print ' * ', $m->name(), " (" .  $m->accuracy() . "%)",
                  "\n";
        }

    } else {

        print "OS matches: $name ($ip):\n";
        print " * No matches found\n";

    }

    my $u = $os->uptime();

    if (defined($u) && ($u->seconds() > 0)) {
        print "Uptime: ", ($u->seconds()/(24*60*60)),
              " days (",$u->lastboot(),")\n";
    }

    print "Ports used for OS fingerprint: ";
    print join(', ', map { $_->portid() } $os->ports_used());
    print "\n";

}
