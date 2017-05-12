#!/usr/bin/perl

package SmtpScanner;

use lib 'lib';
use Nmap::Scanner;
use Nmap::Scanner::Util::BannerScanner;

use strict;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Util::BannerScanner);

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new();

    $self->regex('^\d+ (.*)$');
    $self->add_scan_port(25);
    $self->add_target($_[0] || die "Need target in constructor!\n");

    return bless $self, $class;
}

1;

use lib 'lib';
use strict;

my $smtp = SmtpScanner->new($ARGV[0] || 
                                die "Missing host to scan!\n$0 host\n");

$smtp->register_banner_found_event(
    sub { shift; print $_[0]->hostname(), 
                 " (" . ($_[0]->addresses())[0]->addr() . "): $_[1]\n"; });
$smtp->scan();
