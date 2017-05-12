use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;
use Parse::Win32Registry 0.60 qw(:REG_ make_multiple_subtree_iterator);

$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_subtree_iterator_tests
{
    my $key = shift;
    my @tests = @_;

    my ($os) = ref($key) =~ /Win(NT|95)/;

    # key+value tests

    my $subtree_iter = $key->get_subtree_iterator;
    ok(defined $subtree_iter, "$os get_subtree_iterator defined");
    isa_ok($subtree_iter, "Parse::Win32Registry::Iterator");
    for (my $i = 0; $i < @tests; $i++) {
        my ($key_path, $value_name) = @{$tests[$i]};

        my ($key, $value) = $subtree_iter->get_next;

        my $desc = "$os (list) TEST" . ($i + 1);

        ok(defined $key, "$desc key defined (valid key)");
        is($key->get_path, $key_path,
            "$desc key get_path");

        if (defined $value_name) {
            ok(defined $value, "$desc value defined (valid value)");
            is($value->get_name, $value_name,
                "$desc value get_name");
        }
        else {
            ok(!defined $value, "$desc value undefined (no value)");
        }
    }
    my @final = $subtree_iter->get_next;
    is(@final, 0, "$os (list) iterator empty");

    # key tests

    @tests = grep { !defined $_->[1] } @tests;

    $subtree_iter = $key->get_subtree_iterator;
    ok(defined $subtree_iter, "$os get_subtree_iterator defined");
    isa_ok($subtree_iter, "Parse::Win32Registry::Iterator");
    for (my $i = 0; $i < @tests; $i++) {
        my ($key_path, $value_name) = @{$tests[$i]};

        my $key = $subtree_iter->get_next;

        my $desc = "$os (scalar) TEST" . ($i + 1);

        ok(defined $key, "$desc key defined (valid key)");
        is($key->get_path, $key_path,
            "$desc key get_path");
    }
    my $final = $subtree_iter->get_next;
    ok(!defined $final, "$os (scalar) iterator empty");
}

sub run_multiple_subtree_iterator_tests {
    my $key = shift;
    my @tests = @_;

    my ($os) = ref($key) =~ /Win(NT|95)/;

    # key+value tests

    my $subtree_iter = make_multiple_subtree_iterator($key);
    ok(defined $subtree_iter,
        "$os make_multiple_subtree_iterator defined");
    isa_ok($subtree_iter, "Parse::Win32Registry::Iterator");
    for (my $i = 0; $i < @tests; $i++) {
        my ($key_path, $value_name) = @{$tests[$i]};

        my ($keys_ref, $values_ref) = $subtree_iter->get_next;

        my $desc = "$os (list) TEST" . ($i + 1);

        ok(defined $keys_ref, "$desc keys_ref defined (valid keys)");
        is(ref $keys_ref, 'ARRAY', "$desc keys_ref array");
        is($keys_ref->[0]->get_path, $key_path,
            "$desc keys_ref->[0] get_path");

        if (defined $value_name) {
            ok(defined $values_ref, "$desc values_ref defined (valid values)");
            is(ref $values_ref, 'ARRAY', "$desc values_ref array");
            is($values_ref->[0]->get_name, $value_name,
                "$desc values_ref->[0] get_name");
        }
        else {
            ok(!defined $values_ref, "$desc values_ref undefined (no values)");
        }
    }
    my @final = $subtree_iter->get_next;
    is(@final, 0, "$os (list) iterator empty");

    # key tests

    @tests = grep { !defined $_->[1] } @tests;

    $subtree_iter = make_multiple_subtree_iterator($key);
    ok(defined $subtree_iter,
        "$os make_multiple_subtree_iterator defined");
    isa_ok($subtree_iter, "Parse::Win32Registry::Iterator");
    for (my $i = 0; $i < @tests; $i++) {
        my ($key_path, $value_name) = @{$tests[$i]};

        my $keys_ref = $subtree_iter->get_next;

        my $desc = "$os (scalar) TEST" . ($i + 1);

        ok(defined $keys_ref, "$desc keys_ref defined (valid keys)");
        is(ref $keys_ref, 'ARRAY', "$desc keys_ref array");
        is($keys_ref->[0]->get_path, $key_path,
            "$desc keys_ref->[0] get_path");
    }
    my $final = $subtree_iter->get_next;
    ok(!defined $final, "$os (scalar) iterator empty");
}

{
    my $filename = find_file('win95_iter_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);

    my $root_key = $registry->get_root_key;

    my @tests = (
        [""],
        ["\\key1"],
        ["\\key1", "value1"],
        ["\\key1", "value2"],
        ["\\key1\\key3"],
        ["\\key1\\key3", "value5"],
        ["\\key1\\key3", "value6"],
        ["\\key1\\key4"],
        ["\\key1\\key4", "value7"],
        ["\\key1\\key4", "value8"],
        ["\\key2"],
        ["\\key2", "value3"],
        ["\\key2", "value4"],
        ["\\key2\\key5"],
        ["\\key2\\key5", "value9"],
        ["\\key2\\key5", "value10"],
        ["\\key2\\key6"],
        ["\\key2\\key6", "value11"],
        ["\\key2\\key6", "value12"],
    );

    run_subtree_iterator_tests($root_key, @tests);

    @tests = (
        [""],
        ["\\key1"],
        ["\\key1", "value1"],
        ["\\key1", "value2"],
        ["\\key1\\key3"],
        ["\\key1\\key3", "value5"],
        ["\\key1\\key3", "value6"],
        ["\\key1\\key4"],
        ["\\key1\\key4", "value7"],
        ["\\key1\\key4", "value8"],
        ["\\key2"],
        ["\\key2", "value3"],
        ["\\key2", "value4"],
        ["\\key2\\key5"],
        ["\\key2\\key5", "value10"],
        ["\\key2\\key5", "value9"],
        ["\\key2\\key6"],
        ["\\key2\\key6", "value11"],
        ["\\key2\\key6", "value12"],
    );

    run_multiple_subtree_iterator_tests($root_key, @tests);
}


{
    my $filename = find_file('winnt_iter_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);

    my $root_key = $registry->get_root_key;

    my @tests = (
        ["\$\$\$PROTO.HIV"],
        ["\$\$\$PROTO.HIV", "value1"],
        ["\$\$\$PROTO.HIV", "value2"],
        ["\$\$\$PROTO.HIV\\key1"],
        ["\$\$\$PROTO.HIV\\key1", "value3"],
        ["\$\$\$PROTO.HIV\\key1", "value4"],
        ["\$\$\$PROTO.HIV\\key1\\key3"],
        ["\$\$\$PROTO.HIV\\key1\\key3", "value7"],
        ["\$\$\$PROTO.HIV\\key1\\key3", "value8"],
        ["\$\$\$PROTO.HIV\\key1\\key4"],
        ["\$\$\$PROTO.HIV\\key1\\key4", "value9"],
        ["\$\$\$PROTO.HIV\\key1\\key4", "value10"],
        ["\$\$\$PROTO.HIV\\key2"],
        ["\$\$\$PROTO.HIV\\key2", "value5"],
        ["\$\$\$PROTO.HIV\\key2", "value6"],
        ["\$\$\$PROTO.HIV\\key2\\key5"],
        ["\$\$\$PROTO.HIV\\key2\\key5", "value11"],
        ["\$\$\$PROTO.HIV\\key2\\key5", "value12"],
        ["\$\$\$PROTO.HIV\\key2\\key6"],
        ["\$\$\$PROTO.HIV\\key2\\key6", "value13"],
        ["\$\$\$PROTO.HIV\\key2\\key6", "value14"],
    );

    run_subtree_iterator_tests($root_key, @tests);

    @tests = (
        ["\$\$\$PROTO.HIV"],
        ["\$\$\$PROTO.HIV", "value1"],
        ["\$\$\$PROTO.HIV", "value2"],
        ["\$\$\$PROTO.HIV\\key1"],
        ["\$\$\$PROTO.HIV\\key1", "value3"],
        ["\$\$\$PROTO.HIV\\key1", "value4"],
        ["\$\$\$PROTO.HIV\\key1\\key3"],
        ["\$\$\$PROTO.HIV\\key1\\key3", "value7"],
        ["\$\$\$PROTO.HIV\\key1\\key3", "value8"],
        ["\$\$\$PROTO.HIV\\key1\\key4"],
        ["\$\$\$PROTO.HIV\\key1\\key4", "value10"],
        ["\$\$\$PROTO.HIV\\key1\\key4", "value9"],
        ["\$\$\$PROTO.HIV\\key2"],
        ["\$\$\$PROTO.HIV\\key2", "value5"],
        ["\$\$\$PROTO.HIV\\key2", "value6"],
        ["\$\$\$PROTO.HIV\\key2\\key5"],
        ["\$\$\$PROTO.HIV\\key2\\key5", "value11"],
        ["\$\$\$PROTO.HIV\\key2\\key5", "value12"],
        ["\$\$\$PROTO.HIV\\key2\\key6"],
        ["\$\$\$PROTO.HIV\\key2\\key6", "value13"],
        ["\$\$\$PROTO.HIV\\key2\\key6", "value14"],
    );

    run_multiple_subtree_iterator_tests($root_key, @tests);
}
