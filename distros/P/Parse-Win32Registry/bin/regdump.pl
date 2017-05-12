#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry 0.50 qw(hexdump);

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('recurse|r'    => \my $recurse,
           'values|v'     => \my $show_values,
           'hexdump|x'    => \my $show_hexdump,
           'class-name|c' => \my $show_class_name,
           'security|s'   => \my $show_security,
           'owner|o'      => \my $show_owner);

my $filename = shift or die usage();
my $initial_key_path = shift;

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

if (defined($initial_key_path)) {
    $root_key = $root_key->get_subkey($initial_key_path);
    if (!defined($root_key)) {
        die "Could not locate the key '$initial_key_path' in '$filename'\n";
    }
}

traverse($root_key);

sub traverse {
    my $key = shift;

    print $key->as_string;
    if ($show_class_name) {
        my $class_name = $key->get_class_name;
        if (defined $class_name) {
            print " '$class_name'";
        }
    }
    if ($show_owner) {
        my $security = $key->get_security;
        if (defined $security) {
            my $sd = $security->get_security_descriptor;
            if (defined $sd) {
                my $owner = $sd->get_owner;
                if (defined $owner) {
                    print " ", $owner->as_string;
                }
            }
        }
    }
    print "\n";
    if ($show_security) {
        my $security = $key->get_security;
        if (defined $security) {
            my $sd = $security->get_security_descriptor;
            if (defined $sd) {
                print $sd->as_stanza;
            }
        }
    }

    # Display names of subkeys if we are not descending the tree
    if (!$recurse) {
        foreach my $subkey ($key->get_list_of_subkeys) {
            print "..\\", $subkey->get_name, "\n";
        }
    }

    if ($show_values) {
        foreach my $value ($key->get_list_of_values) {
            if (!$show_hexdump) {
                print $value->as_string, "\n";
            }
            else {
                my $value_name = $value->get_name;
                $value_name = "(Default)" if $value_name eq "";
                my $value_type = $value->get_type_as_string;
                print "$value_name ($value_type):\n";
                print hexdump($value->get_raw_data);
            }
        }
    }

    if ($show_security || $show_values) {
        print "\n";
    }

    if ($recurse) {
        foreach my $subkey ($key->get_list_of_subkeys) {
            traverse($subkey);
        }
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Dumps the keys and values of a registry file.

$script_name <filename> [subkey] [-r] [-v] [-x] [-c] [-s] [-o]
    -r or --recurse     traverse all child keys from the root key
                        or the subkey specified
    -v or --values      display values
    -x or --hexdump     display value data as a hex dump
    -c or --class-name  display the class name for the key (if present)
    -s or --security    display the security information for the key,
                        including the owner and group SIDs,
                        and the system and discretionary ACLs (if present)
    -o or --owner       display the owner SID for the key (if present)
USAGE
}
