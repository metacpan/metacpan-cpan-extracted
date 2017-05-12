#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry 0.40;

binmode(STDOUT, ":utf8");

Getopt::Long::Configure('bundling');

GetOptions('recurse|r' => \my $recurse);

my $filename = shift or die usage();
my $initial_key_path = shift;

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_virtual_root_key
    or die "Could not get root key of '$filename'\n";

if (defined($initial_key_path)) {
    $root_key = $root_key->get_subkey($initial_key_path);
    if (!defined($root_key)) {
        die "Could not locate the key '$initial_key_path' in '$filename'\n";
    }
}

print "Windows Registry Editor Version 5.00\n";

traverse($root_key);

sub traverse {
    my $key = shift;

    print "\n";
    print $key->as_regedit_export;

    foreach my $value ($key->get_list_of_values) {
        print $value->as_regedit_export;
    }

    if ($recurse) {
        foreach my $subkey ($key->get_list_of_subkeys) {
            traverse($subkey);
        }
    }
    else {
        print "\n";
        foreach my $subkey ($key->get_list_of_subkeys) {
            print "; SUBKEY ", $subkey->get_name, "\n";
        }
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Exports the keys and values of a registry file in REGEDIT format.

$script_name <filename> [subkey] [-r]
    -r or --recurse     traverse all child keys from the root key
                        or the subkey specified
USAGE
}
