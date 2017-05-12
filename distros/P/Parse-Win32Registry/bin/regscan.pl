#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use Getopt::Long;
use Parse::Win32Registry 0.50;

binmode(STDOUT, ':utf8');

Getopt::Long::Configure('bundling');

GetOptions('parse-info|p' => \my $show_parse_info,
           'unparsed|u'   => \my $show_unparsed,
           'allocated|a'  => \my $list_allocated,
           'keys|k'       => \my $list_keys,
           'values|v'     => \my $list_values,
           'security|s'   => \my $list_security);

my $filename = shift or die usage();

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";

my $entry_iter = $registry->get_entry_iterator;

while (defined(my $entry = $entry_iter->get_next)) {
    next if $list_allocated && !$entry->is_allocated;
    next if !((!$list_keys && !$list_values && !$list_security) ||
              ($list_keys && $entry->can('get_subkey')) ||
              ($list_values && $entry->can('get_data')) ||
              ($list_security && $entry->can('get_security_descriptor')));

    if ($show_parse_info) {
        print $entry->parse_info, "\n";
    }
    else {
        printf "0x%x ", $entry->get_offset;
        print $entry->as_string, "\n";
    }
    print $entry->unparsed if $show_unparsed;
}

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

Displays the component elements of a registry file, without traversing
the current active key structure. This will display elements that are
associated with but are not actually keys or values. Additionally,
some of the keys, values, and associated elements displayed
will no longer be active and may be invalid or deleted.

$script_name <filename> [-k] [-v] [-s] [-a] [-p] [-u]
    -k or --keys        list only 'key' entries
    -v or --values      list only 'value' entries
    -s or --security    list only 'security' entries
    -a or --allocated   list only 'allocated' entries
    -p or --parse-info  show the technical information for an entry
                        instead of the string representation
    -u or --unparsed    show the unparsed on-disk entries as a hex dump
USAGE
}
