#!/usr/bin/perl

package WebScanner;

use strict;
use lib 'lib';
use Nmap::Scanner::Util::BannerScanner;
use vars qw(@ISA);

@ISA = qw(Nmap::Scanner::Util::BannerScanner);

sub new {

    my $class = shift;
    my $self = $class->SUPER::new();

    $self->regex('Server:\s*(.+)$');
    $self->send_on_connect("HEAD / HTTP/1.0\r\n\r\n");
    $self->add_scan_port(80);
    $self->add_scan_port(8080);
    $self->add_target($_[0] || die "Need target in constructor!\n");

    return bless $self, $class;

}

1;

use lib 'lib';
use strict;

my $web = WebScanner->new($ARGV[0] || 
                              die "Missing host to scan!\n$0 host\n");

$web->register_banner_found_event(
    sub { shift; print $_[0]->hostname(), 
                 " (" . ($_[0]->addresses())[0]->addr() . "): $_[1]\n"; });
$web->scan();
