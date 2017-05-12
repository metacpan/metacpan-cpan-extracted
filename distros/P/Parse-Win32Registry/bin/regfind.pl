#!/usr/bin/perl
use strict;
use warnings;

use Encode;
use File::Basename;
use Getopt::Long;
use Parse::Win32Registry qw(:REG_ hexdump);

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('key|k'      => \my $search_keys,
           'value|v'    => \my $search_values,
           'data|d'     => \my $search_data,
           'type|t'     => \my $search_type,
           'hexdump|x'  => \my $show_hexdump);

my $filename = shift or die usage();
my $regexp = shift or die usage();

if (!$search_keys && !$search_values && !$search_data && !$search_type) {
    warn usage();
    die "\nYou need to specify at least one of -k, -v, -d, or -t\n";
}

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

traverse($root_key);

sub traverse {
    my $key = shift;

    my $matching_key = "";
    my %matching_values = ();

    if ($search_keys && $key->get_name =~ /$regexp/oi) {
        $matching_key = $key;
    }

    if ($search_values || $search_data || $search_type) {
        foreach my $value ($key->get_list_of_values) {
            if ($search_type && $value->get_type_as_string =~ /$regexp/oi) {
                $matching_key = $key;
                $matching_values{$value->get_name} = $value;
            }
            if ($search_values && $value->get_name =~ /$regexp/oi) {
                $matching_key = $key;
                $matching_values{$value->get_name} = $value;
            }
            if ($search_data && defined($value->get_data)) {
                if ($value->get_type_as_string =~ /SZ$/) {
                    {
                        no warnings; # hide malformed UTF-8 warnings
                        if ($value->get_data =~ /$regexp/oi) {
                            $matching_key = $key;
                            $matching_values{$value->get_name} = $value;
                        }
                    }
                }
                elsif ($value->get_type == REG_DWORD) {
                    if ($value->get_data_as_string =~ /$regexp/oi) {
                        $matching_key = $key;
                        $matching_values{$value->get_name} = $value;
                    }
                }
                else {
                    if ($value->get_data =~ /$regexp/o) {
                        $matching_key = $key;
                        $matching_values{$value->get_name} = $value;
                    }
                    no warnings; # hide malformed UTF-8 warnings
                    if (decode("UCS-2LE", $value->get_raw_data) =~ /$regexp/oi) {
                        $matching_key = $key;
                        $matching_values{$value->get_name} = $value;
                    }
                }
            }
        }
    }

    if ($matching_key) {
        print $matching_key->get_path, "\n";
        foreach my $name (keys %matching_values) {
            my $value = $matching_values{$name};
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
        print "\n" if $search_values || $search_type || $search_data;
    }

    foreach my $subkey ($key->get_list_of_subkeys) {
        traverse($subkey);
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Searches a registry file for anything that matches the specified string.

$script_name <filename> <search-string> [-k] [-v] [-d] [-t] [-x]
    -k or --key         search key names for a match
    -v or --value       search value names for a match
    -d or --data        search value data for a match
    -t or --type        search value types for a match
    -x or --hexdump     display value data as a hex dump
USAGE
}
