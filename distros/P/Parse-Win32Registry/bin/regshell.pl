#!/usr/bin/perl
use strict;
use warnings;

binmode(STDOUT, ':utf8');

use File::Basename;
use Parse::Win32Registry 0.50 qw(hexdump);
use Term::ReadLine;

Parse::Win32Registry->disable_warnings;

my $filename = shift or die usage();
my $initial_key_path = shift;

my $registry = Parse::Win32Registry->new($filename)
    or die "'$filename' is not a registry file\n";
my $root_key = $registry->get_root_key
    or die "Could not get root key of '$filename'\n";

my $key = $root_key; # location as we navigate the registry tree

my $term = Term::ReadLine->new("regshell");
my $attribs = $term->Attribs;
$attribs->{completion_function} = sub {
    my ($text, $line, $start) = @_;
    my $preceding_text = substr($line, 0, $start);
    if ($preceding_text =~ /^\s*$/) { # first word = command completion
        return grep /^\Q$text/,
            qw(help cd pwd ls dir cat type xxd hexdump find next exit quit);
    }
    else { # second word = parameter completion
        if ($preceding_text =~ /\b(cd)\b/) {
            # subkey path completion
            if ($text =~ /^(.*)\\[^\\]*$/) {
                my $path = $1;
                if (my $subkey = $key->get_subkey($path)) {
                    my @subkeys = $subkey->get_list_of_subkeys;
                    my @names = map { "$path\\" . $_->get_name } @subkeys;
                    return grep /^\Q$text/, @names;
                }
                else {
                    return;
                }
            }
            my @names = map { $_->get_name } $key->get_list_of_subkeys;
            return grep /^\Q$text/, @names;
        }
        elsif ($preceding_text =~ /\b(cat|type|xxd|hexdump)\b/) {
            # value name completion
            my @names = map { $_->get_name } $key->get_list_of_values;
            return grep /^\Q$text/, @names;
        }
        else {
            return;
        }
    }
};
$attribs->{completer_word_break_characters} = ' ';
$attribs->{completer_quote_characters} = '"';

my $find_iter;
my $find_param;
my $prompt = $key->get_path;

while (defined(my $line = $term->readline("$prompt> "))) {
    # trim white space from line
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    my ($cmd, $param) = split /\s+/, $line, 2;

    # strip quotes around $param if present
    if (defined $param && $param =~ /^"(.*)"$/) {
        $param = $1;
    }

    if ($cmd) {
        if ($cmd eq 'help') {
            print <<HELP;
cd <subkey>             Change to the specified subkey.
                        Specify '..' to change to the parent key.
                        Omit the subkey name to change to the root key.
ls | dir                List the subkeys and values of the current key.
cat | type <value>      Display the specified value.
                        Omit the value name to display the default value.
xxd | hexdump <value>   Display the specified value in hex.
                        Omit the value name to display the default value.
find <string>           Start a search for a key or value matching
                        the supplied string. The search is not case sensitive.
next | n                Search for the next matching key or value.
exit | quit             Exit the program.
HELP
        }
        elsif ($cmd eq 'cd') {
            if (!defined $param) {
                $key = $root_key; # go to root key if no param supplied
            }
            elsif ($param =~ /\.\.(\\\.\.)*/) {
                my $count = ($param =~ tr/\\//);
                my $new_key = $key;
                for (my $i = 0; $i <= $count; $i++) {
                    $new_key = $new_key->get_parent;
                    if (!defined $new_key) {
                        last;
                    }
                }
                if (defined $new_key) {
                    print $new_key->as_string, "\n";
                    $key = $new_key;
                }
                else {
                    print "Invalid parent key\n";
                }
            }
            else {
                if (my $new_key = $key->get_subkey($param)) {
                    $key = $new_key;
                }
                else {
                    print "No subkey named '$param'\n";
                }
            }
        }
        elsif ($cmd eq 'pwd') {
            print $key->get_path, "\n";
        }
        elsif ($cmd eq 'ls' || $cmd eq 'dir') {
            foreach my $subkey ($key->get_list_of_subkeys) {
                if ($cmd eq 'ls') {
                    print $subkey->get_name, "\n";
                }
                else {
                    print "[", $subkey->get_name, "]\n";
                }
            }
            foreach my $value ($key->get_list_of_values) {
                if ($cmd eq 'ls') {
                    print $value->as_string, "\n";
                }
                else {
                    print $value->as_regedit_export;
                }
            }
        }
        elsif ($cmd eq 'cat' || $cmd eq 'type') {
            if (!defined $param) {
                $param = ''; # assume default value if no param supplied
            }
            if (my $value = $key->get_value($param)) {
                if ($cmd eq 'cat') {
                    print $value->as_string, "\n";
                }
                else {
                    print $value->as_regedit_export;
                }
            }
            else {
                print "No value named '$param'\n";
            }
        }
        elsif ($cmd eq 'xxd' | $cmd eq 'hexdump') {
            if (!defined $param) {
                $param = ''; # assume default value if no param supplied
            }
            if (my $value = $key->get_value($param)) {
                print hexdump($value->get_raw_data);
            }
            else {
                print "No value named '$param'\n";
            }
        }
        elsif ($cmd eq 'exit' || $cmd eq 'quit') {
            last;
        }
        elsif ($cmd eq 'find') {
            if (!defined $param) {
                if (defined $find_param) {
                    print "Currently searching for '$find_param'\n";
                }
                print "Specify a search term to start a new search\n";
            }
            else {
                $find_param = $param;
                $find_iter = $root_key->get_subtree_iterator;
                find_next();
            }
        }
        elsif ($cmd eq 'next' || $cmd eq 'n') {
            find_next();
        }
        else {
            print "Unrecognised command '$cmd'\n";
        }
    }

    $prompt = $key->get_path;
}
print "\nGoodbye...\n";

sub usage {
    my $script_name = basename $0;
    return <<USAGE;
$script_name for Parse::Win32Registry $Parse::Win32Registry::VERSION

An interactive shell for examining registry files where you navigate keys
using 'cd' and display keys and values using 'ls' or 'dir'. Tab completion
for key and value names is available if the underlying platform supports
it. Type 'help' at the prompt for a list of available commands.

$script_name <filename>
USAGE
}

sub find_next {
    if (!defined $find_param || !defined $find_iter) {
        print "No search started...\n";
        return;
    }

    while (my ($next_key, $next_value) = $find_iter->get_next) {
        my $key_name = $next_key->get_name;

        if (defined $next_value) {
            my $value_name = $next_value->get_name;
            if (index(lc $value_name, lc $find_param) > -1) {
                print "Found value '$value_name' in key '$key_name'\n";
                $key = $next_key;
                return;
            }
            else {
                next;
            }
        }

        if (index(lc $key_name, lc $find_param) > -1) {
            print "Found key '$key_name'\n";
            $key = $next_key;
            return;
        }
        else {
            next;
        }
    }
    print "No (more) matches found\n";
}
