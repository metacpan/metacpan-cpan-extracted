#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry;

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('values|v' => \my $show_values);

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
    my @siblings = @_;
    # @siblings tracks the number of remaining keys at each level of depth
    # $siblings[0] = count of remaining sibling keys at level 0
    # $siblings[1] = count of remaining sibling keys at level 1
    # etc.

    if (@siblings) {
        foreach my $remaining (@siblings[0..$#siblings-1]) {
            print $remaining > 0 ? "| " : "  ";
        }
        print $siblings[-1] > 0 ? "+-" : "`-";
    }

    print $key->get_name;
    if (defined($key->get_timestamp)) {
        print " [", $key->get_timestamp_as_string, "]"
    }
    print "\n";

    # initialize the count of remaining sibling keys for this depth
    push @siblings, scalar $key->get_list_of_subkeys;

    if ($show_values) {
        foreach my $value ($key->get_list_of_values) {
            foreach my $remaining (@siblings) {
                print $remaining > 0 ? "| " : "  ";
            }
            print $value->as_string, "\n";
        }
    }

    foreach my $subkey ($key->get_list_of_subkeys) {
        $siblings[-1]--;
        traverse($subkey, @siblings);
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays the keys and values of a registry file as an indented tree.

$script_name <filename> [subkey] [-v]
    -v or --values      display values
USAGE
}
