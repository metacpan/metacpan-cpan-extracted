#!/usr/bin/perl

package FtpScanner;

use strict;
use lib 'lib';
use Nmap::Scanner;
use Nmap::Scanner::Util::BannerScanner;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Util::BannerScanner);

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new();

    $self->regex('^\d+ (.*)$');
    $self->add_scan_port(21);
    $self->add_target($_[0] || die "Need target in constructor!\n");

    return bless $self, $class;
}

1;

use lib 'lib';

my $ftp = FtpScanner->new($ARGV[0] || 'localhost');
$ftp->register_banner_found_event(
    sub { 
        shift; 
        my @addresses = $_[0]->addresses();
        print $_[0]->hostname()," ( ";
        for my $a (@addresses) {
            print $a->addr()," ";
        }
        print "): $_[1]\n";
    }
);

my $hosts = $ftp->scan()->get_host_list;

while ($hosts->get_next()) { print $_->name()."\n" if $_};
