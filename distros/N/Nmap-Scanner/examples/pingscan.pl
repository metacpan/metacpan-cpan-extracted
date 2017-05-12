#!/usr/bin/perl

package PingScanner;

use lib 'lib';
use Nmap::Scanner;
use Nmap::Scanner::Scanner;

use strict;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Scanner);

sub new {

    my $class = shift;
    my $self = $class->SUPER::new();

    $self->ack_icmp_ping();
    $self->ping_scan();
    $self->add_target($_[0] || die "Need target in constructor!\n");
    $self->register_scan_started_event(\&pinged);

    return bless $self, $class;

}

sub scan {
    die "Need callback!\n" unless ref($_[0]->{CALLBACK}) eq 'CODE';
    $_[0]->SUPER::scan();
}

sub callback {
    (defined $_[1]) ? ($_[0]->{CALLBACK} = $_[1]) : return $_[0]->{CALLBACK};
}

sub pinged {
    &{$_[0]->{'CALLBACK'}}($_[0], $_[1], $_[2], $_[3]);
}

1;

use lib 'lib';

my $p = PingScanner->new($ARGV[0] || 
                             die "Missing host to scan!\n$0 host\n");
$p->callback(
    sub { 
          shift;
          printf "%s (%s): %s\n", $_[0]->hostname(), ($_[0]->addresses())[0]->addr(),
                                  $_[0]->status(); 
    }
);
$p->scan();
