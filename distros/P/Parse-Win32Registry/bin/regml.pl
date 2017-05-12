#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Parse::Win32Registry 0.60;

binmode(STDOUT, ':utf8');

my $filename = shift or die usage();

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

my $security = $root_key->get_security
    or die "Root key of '$filename' does not have any security information\n";

traverse($root_key);

sub traverse {
    my $key = shift;

    my $security = $key->get_security;
    if (defined $security) {
        my $sd = $security->get_security_descriptor;
        my $sacl = $sd->get_sacl;
        if (defined $sacl) {
            foreach my $ace ($sacl->get_list_of_aces) {
                if ($ace->get_type == 0x11) {
                    print $key->as_string, "\n";
                    print "ACE: ", $ace->as_string, "\n\n";
                }
            }
        }
    }

    foreach my $subkey ($key->get_list_of_subkeys) {
        traverse($subkey);
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays those keys in a registry file that have a System ACL
that includes a System Mandatory Label ACE.
Only Windows NT registry files contain security information.

$script_name <filename>
USAGE
}
