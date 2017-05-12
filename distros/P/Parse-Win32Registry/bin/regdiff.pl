#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry;

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('previous|p' => \my $show_previous,
           'values|v'   => \my $show_values);

my $left_filename = shift or die usage();
my $right_filename = shift or die usage();

my $initial_key_path = shift;

my $left_registry = Parse::Win32Registry->new($left_filename)
    or die "'$left_filename' is not a registry file\n";
my $right_registry = Parse::Win32Registry->new($right_filename)
    or die "'$right_filename' is not a registry file\n";
my $left_root_key = $left_registry->get_root_key
    or die "Could not get root key of '$left_filename'\n";
my $right_root_key = $right_registry->get_root_key
    or die "Could not get root key of '$right_filename'\n";

if (defined($initial_key_path)) {
    $left_root_key = $left_root_key->get_subkey($initial_key_path);
    if (!defined($left_root_key)) {
        die "Could not find the key '$initial_key_path' in '$left_filename'\n";
    }
    $right_root_key = $right_root_key->get_subkey($initial_key_path);
    if (!defined($right_root_key)) {
        die "Could not find the key '$initial_key_path' in '$right_filename'\n";
    }
}

# Descend both registry trees together
traverse_together($left_root_key, $right_root_key);

sub traverse_together {
    my $left_key = shift;
    my $right_key =shift;

    # Build a combined list of 'left' and 'right' values
    my %values = ();
    if (defined($left_key)) {
        foreach my $left_value ($left_key->get_list_of_values) {
            $values{$left_value->get_name}{left} = $left_value;
        }
    }
    if (defined($right_key)) {
        foreach my $right_value ($right_key->get_list_of_values) {
            $values{$right_value->get_name}{right} = $right_value;
        }
    }

    # Count the number of changed values
    my $changed = 0;
    foreach my $value_name (keys %values) {
        if (defined $values{$value_name}{left}
            && defined $values{$value_name}{right}) {
            if ($values{$value_name}{left}->get_data
                ne $values{$value_name}{right}->get_data) {
                # value has been changed
                $changed++;
            }
        }
        else {
            # Value has been deleted or inserted
            $changed++;
        }
    }

    if (defined($left_key) && !defined($right_key)) {
        # Right key has been deleted
        print "DELETED\t", $left_key->as_string, "\n";
    }
    elsif (!defined($left_key) && defined($right_key)) {
        # Right key has been inserted
        print "ADDED\t", $right_key->as_string, "\n";
    }
    else {
        # If both keys are present, compare timestamps
        # to see if there have been any changes.
        # If the keys do not have timestamps, use the count of changed values
        # to determine if the key should be displayed or not.
        my $left_timestamp = $left_key->get_timestamp;
        my $right_timestamp = $right_key->get_timestamp;
        my $is_winnt = defined($left_timestamp) && defined($right_timestamp);
        if ($is_winnt && $left_timestamp < $right_timestamp) {
            # Right key is newer
            print "NEWER\t", $right_key->as_string, "\n";
            if ($show_previous) {
                print "WAS\t", $left_key->as_string, "\n";
            }
        }
        elsif ($is_winnt && $left_timestamp > $right_timestamp) {
            # Right key is older
            print "OLDER\t", $right_key->as_string, "\n";
            if ($show_previous) {
                print "WAS\t", $left_key->as_string, "\n";
            }
        }
        else {
            # There are no differences between the timestamps
            # or neither key has a valid timestamp.
            if ($show_values) {
                if ($changed > 0) {
                    #print "\t$changed VALUES CHANGED IN\n";
                    if (defined($left_key)) {
                        print "\t", $left_key->as_string, "\n";
                    }
                    else {
                        print "\t", $right_key->as_string, "\n";
                    }
                }
            }
        }
    }

    if ($show_values) {
        # Print out changed values
        foreach my $value_name (keys %values) {
            my $left_value = $values{$value_name}{left};
            my $right_value = $values{$value_name}{right};
            if (defined($left_value) && !defined($right_value)) {
                print "DELETED\t", $left_value->as_string, "\n";
            }
            elsif (!defined($left_value) && defined($right_value)) {
                print "ADDED\t", $right_value->as_string, "\n";
            }
            else {
                if ($left_value->get_data ne $right_value->get_data) {
                    print "CHANGED\t", $right_value->as_string, "\n";
                    if ($show_previous) {
                        print "WAS\t", $left_value->as_string, "\n";
                    }
                }
            }
        }
    }

    # Build a combined list of 'left' and 'right' subkeys
    my %subkeys = ();
    if (defined($left_key)) {
        foreach my $left_subkey ($left_key->get_list_of_subkeys) {
            $subkeys{$left_subkey->get_name}{left} = $left_subkey;
        }
    }
    if (defined($right_key)) {
        foreach my $right_subkey ($right_key->get_list_of_subkeys) {
            $subkeys{$right_subkey->get_name}{right} = $right_subkey;
        }
    }

    foreach my $key_name (keys %subkeys) {
        traverse_together($subkeys{$key_name}{left},
                          $subkeys{$key_name}{right});
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Compares two registry files.

$script_name <filename1> <filename2> [subkey] [-p] [-v]
    -p or --previous    show the previous key or value
                        (this is not normally shown)
    -v or --values      display values
USAGE
}
