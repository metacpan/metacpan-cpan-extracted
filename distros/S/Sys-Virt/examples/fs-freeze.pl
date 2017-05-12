# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

die "syntax: $0 URI DOMAIN-NAME MOUNT-POINTS\n" unless int(@ARGV) >= 2;

my $uri = shift @ARGV;
my $domname = shift @ARGV;

my @mountpoints = @ARGV;

print "Addr $uri\n";
my $con = Sys::Virt->new(address => $uri, readonly => 0);

my $dom = $con->get_domain_by_name($domname);

$dom->fs_freeze(\@mountpoints);
