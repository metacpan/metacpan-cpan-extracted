#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Parse::RecDescent;
use FindBin qw/$Bin/;

chdir "$Bin/../lib/Parse/FieldPath";

my $grammar = join('', <DATA>);
Parse::RecDescent->Precompile($grammar, 'Parse::FieldPath::Parser');

__DATA__

parse: fields /^\Z/
    {
        $return = $item[1];
    }

fields: field(s /,/)
    {
        use Hash::Merge qw//;
        use List::Util qw//;
        $return = List::Util::reduce { Hash::Merge::merge($a, $b) } {}, @{$item[1]};
    }

field: field_list | field_path | <error>

field_name: /\w+/ | '*' | '' | <error?>
field_list: field_path '(' fields ')'
    {
        sub deepest {
            my $hashref = shift;
            return $hashref if scalar(keys %$hashref) == 0;
            my $key = (keys %$hashref)[0];
            return deepest($hashref->{$key});
        }
        my $deepest = deepest($item{field_path});
        $deepest->{$_} = $item{fields}->{$_} for keys %{$item{fields}};
        $return = $item{field_path};
    }

# Matches "a/b", "a/b/c" or just "a"
field_path: field_name(s /\//)
    {
        use List::Util qw//;

        # Turn qw/a b c/ into { a => { b => { c => {} } } }
        my $fields = {};
        List::Util::reduce { $a->{$b} = {} if $b } $fields, @{$item{'field_name(s)'}};
        $return = $fields;
    }
