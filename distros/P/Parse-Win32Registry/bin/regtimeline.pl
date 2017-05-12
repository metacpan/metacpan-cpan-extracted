#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry qw(iso8601 hexdump);

binmode(STDOUT, ":utf8");

Getopt::Long::Configure('bundling');

GetOptions('last|l=f'  => \my $period,
           'values|v'  => \my $show_values,
           'hexdump|x' => \my $show_hexdump);

my $filename = shift or die usage();
my $initial_key_path = shift;

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

if (!defined($root_key->get_timestamp)) {
    die "'$filename' needs to be an NT-based registry file\n"
}

if (defined($initial_key_path)) {
    $root_key = $root_key->get_subkey($initial_key_path);
    if (!defined($root_key)) {
        die "Could not locate the key '$initial_key_path' in '$filename'\n";
    }
}

warn "Ordering keys...\n";

my $first_timestamp = 0;
my $last_timestamp = 0;
my %keys_by_timestamp = ();

traverse($root_key);

sub traverse {
    my $key = shift;

    my $timestamp = $key->get_timestamp;
    push @{$keys_by_timestamp{$timestamp}}, $key;
    $first_timestamp = $timestamp if $timestamp < $first_timestamp;
    $last_timestamp = $timestamp if $timestamp > $last_timestamp;

    foreach my $subkey ($key->get_list_of_subkeys) {
        traverse($subkey);
    }
}

if ($period) {
    $first_timestamp = $last_timestamp - $period * 86400;
}

foreach my $timestamp (sort { $a <=> $b } keys %keys_by_timestamp) {
    next if $timestamp < $first_timestamp;
    foreach my $key (@{$keys_by_timestamp{$timestamp}}) {
        print iso8601($timestamp), "\t", $key->get_path, "\n";
        if ($show_values) {
            foreach my $value ($key->get_list_of_values) {
                if (!$show_hexdump) {
                    print "\t", $value->as_string, "\n";
                }
                else {
                    my $value_name = $value->get_name;
                    $value_name = "(Default)" if $value_name eq "";
                    my $value_type = $value->get_type_as_string;
                    print "\t$value_name ($value_type):\n";
                    print hexdump($value->get_raw_data);
                }
            }
            print "\n";
        }
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays the keys and values of a registry file in date order.

$script_name <filename> [subkey] [-l <number>] [-v] [-x]
    -l or --last        display only the last <number> days
                        of registry activity
    -v or --values      display values
    -x or --hexdump     display value data as a hex dump
USAGE
}
