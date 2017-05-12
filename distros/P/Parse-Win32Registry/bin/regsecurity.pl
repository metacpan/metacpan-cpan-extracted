#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Parse::Win32Registry 0.50;

binmode(STDOUT, ':utf8');

my $filename = shift or die usage();

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

# Use the root key to get the first security entry
my $security = $root_key->get_security
    or die "Root key of '$filename' does not have any security information\n";

my %offsets_seen = ();
my $offset = $security->get_offset;
while (!exists $offsets_seen{$offset}) {
    $offsets_seen{$offset} = undef; # value not required

    printf "Security at offset 0x%x, %d references\n",
        $offset, $security->get_reference_count;
    my $sd = $security->get_security_descriptor;
    print $sd->as_stanza;
    print "\n";

    $security = $security->get_next;
    if (!defined $security) {
        die "Unable to get next security entry\n";
    }
    $offset = $security->get_offset;
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays all the security entries in a registry file.
Each key contains a reference to one of these security entries.
Only Windows NT registry files contain security information.

$script_name <filename>
USAGE
}
