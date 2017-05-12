# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

die "syntax: $0 URI DOMAIN-NAME\n" unless int(@ARGV) == 2;

my $uri = shift @ARGV;
my $domname = shift @ARGV;

print "Addr $uri\n";
my $con = Sys::Virt->new(address => $uri, readonly => 0);

my $dom = $con->get_domain_by_name($domname);

my @codes = (
    35, 18, 38, 38, 24,
    57,
    17, 24, 19, 38, 32,
    28,
    );

$dom->send_key(Sys::Virt::Domain::KEYCODE_SET_LINUX,
	       100,
	       \@codes);
