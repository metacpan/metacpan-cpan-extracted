#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry 0.40;

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('types|t' => \my $count_types);

my $filename = shift or die usage();

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

warn "Counting keys and values...\n";

my $total_keys = 0;
my $total_values = 0;
my %type_count = ();

traverse($root_key);

print "Filename: $filename\n";
if (defined $registry->get_timestamp) {
    print "Registry Timestamp: ", $registry->get_timestamp_as_string, "\n";
}
if (defined $registry->get_embedded_filename) {
    print "Embedded Filename: ", $registry->get_embedded_filename, "\n";
}
print "Root Key Name: ", $root_key->get_name, "\n";

print "Keys: $total_keys\n";
print "Values: $total_values\n";
if ($count_types) {
    foreach my $type_as_string (sort keys %type_count) {
        print "$type_as_string: $type_count{$type_as_string}\n";
    }
}

sub traverse {
    my $key = shift;
    $total_keys++;
    foreach my $value ($key->get_list_of_values) {
        $type_count{$value->get_type_as_string}++;
        $total_values++;
    }
    foreach my $subkey ($key->get_list_of_subkeys) {
        traverse($subkey);
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays information about a registry file.

$script_name <filename> [-t]
    -t or --types       count value types
USAGE
}
