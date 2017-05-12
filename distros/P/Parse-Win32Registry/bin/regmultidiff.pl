#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry 0.51 qw( make_multiple_subtree_iterator
                                  compare_multiple_keys
                                  compare_multiple_values
                                  hexdump );

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('values|v'  => \my $show_values,
           'hexdump|x' => \my $show_hexdump,
           'long|l'    => \my $show_long,
           'all|a'     => \my $show_all);

my $show_keys = 1;

my @filenames = ();
my @root_keys = ();
my @start_keys = ();
my $initial_key_path;

if (@ARGV) {
    while (my $filename = shift) {
        if (-r $filename) {
            my $registry = Parse::Win32Registry->new($filename);
            if (defined $registry) {
                my $root_key = $registry->get_root_key;
                if (defined $root_key) {
                    push @root_keys, $root_key;
                    push @filenames, $filename;
                }
            }
        }
        else {
            # If $filename is not a readable file, assume it is a key path:
            $initial_key_path = $filename;
        }
    }
}
else {
    die usage();
}

if (@root_keys < 2) {
    die "Specify two or more filenames\n";
}

@start_keys = @root_keys;
if ($initial_key_path) {
    @start_keys = map { $_->get_subkey($initial_key_path) || undef } @root_keys;
}

my $num_start_keys = grep { defined } @start_keys;
if ($num_start_keys < 1) {
    die "Could not locate the key '$initial_key_path' in any file\n";
}

my $subtree_iter = make_multiple_subtree_iterator(@start_keys);
my $batch_size = @start_keys;

if ($show_long) {
    for (my $num = 0; $num < $batch_size; $num++) {
        print "[$num]:\tFILE\t'$filenames[$num]'\n";
    }
}

my $last_key_shown;

while (my ($keys_ref, $values_ref) = $subtree_iter->get_next) {
    my @keys = @$keys_ref;
    my $any_key = (grep { defined } @keys)[0];
    die "Unexpected error: no keys!" if !defined $any_key;

    if (defined $values_ref) {
        my @values = @$values_ref;
        my $any_value = (grep { defined } @values)[0];
        die "Unexpected error: no values!" if !defined $any_value;

        my @changes = compare_multiple_values(@values);
        my $num_changes = grep { $_ } @changes;
        if ($num_changes > 0 && $show_values) {
            if (!defined $last_key_shown
                      || $last_key_shown ne $any_key->get_path)
            {
                print "-" x $batch_size, "\t", $any_key->get_path, "\n";
                $last_key_shown = $any_key->get_path;
            }
            if (!$show_long) {
                for (my $num = 0; $num < $batch_size; $num++) {
                    my $diff = substr($changes[$num], 0, 1) ||
                                (defined $values[$num] ? '.' : ' ');
                    print $diff;
                }
                print "\t", $any_value->get_name, "\n";
            }
            else {
                for (my $num = 0; $num < $batch_size; $num++) {
                    my $next_change = $changes[$num + 1];
                    if ($changes[$num] || $show_all
                                       || defined $next_change
                                               && $next_change eq 'DELETED')
                    {
                        print "[$num]:\t$changes[$num]\t";
                        if (defined $values[$num]) {
                            if (!$show_hexdump) {
                                print $values[$num]->as_string, "\n";
                            }
                            else {
                                my $value_name = $values[$num]->get_name;
                                $value_name = "(Default)" if $value_name eq "";
                                my $value_type
                                    = $values[$num]->get_type_as_string;
                                print "$value_name ($value_type):\n";
                                print hexdump($values[$num]->get_raw_data);
                            }
                        }
                        else {
                            print "\n";
                        }
                    }
                }
            }
        }
    }
    else {
        my @changes = compare_multiple_keys(@keys);
        my $num_changes = grep { $_ } @changes;
        if ($num_changes > 0 && $show_keys) {
            if (!$show_long) {
                for (my $num = 0; $num < $batch_size; $num++) {
                    my $diff = substr($changes[$num], 0, 1) ||
                                (defined $keys[$num] ? '.' : ' ');
                    print $diff;
                }
                print "\t", $any_key->get_path, "\n";
            }
            else {
                for (my $num = 0; $num < $batch_size; $num++) {
                    my $next_change = $changes[$num+1];
                    if ($changes[$num] || $show_all
                                       || defined $next_change
                                               && $next_change eq 'DELETED')
                    {
                        print "[$num]:\t$changes[$num]\t";
                        if (defined $keys[$num]) {
                            print $keys[$num]->as_string;
                            $last_key_shown = $keys[$num]->get_path;
                        }
                        elsif ($changes[$num] eq 'DELETED') {
                            print $keys[$num-1]->as_string;
                            $last_key_shown = $keys[$num-1]->get_path;
                        }
                        print "\n";
                    }
                }
            }
            $last_key_shown = $any_key->get_path;
        }
    }
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Compares two or more registry files.
Defaults to displaying a summary of the changes where each letter
represents a change (N=NEWER, O=OLDER, A=ADDED, D=DELETED, C=CHANGED).
The long output will display full details of each change.

$script_name <file1> <file2> <file3> ... [<subkey>] [-v] [-x] [-l] [-a]
    -v or --values      display values
    -x or --hexdump     display value data as a hex dump
    -l or --long        show each changed key or value instead of a summary
    -a or --all         show all keys and values before and after a change
USAGE
}
