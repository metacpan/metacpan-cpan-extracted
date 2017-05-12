use strict;
use warnings;

use Data::Dumper;
use Test::More 'no_plan';
use Parse::Win32Registry 0.60 qw(make_multiple_subtree_iterator
                                 compare_multiple_keys
                                 compare_multiple_values);

$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_compare_tests
{
    my @registries = @{shift @_};
    my @tests = @_;

    my $any_registry = (grep { defined } @registries)[0];

    my ($os) = ref($any_registry) =~ /Win(NT|95)/;

    my @root_keys = map { $_->get_root_key } @registries;
    my $subtree_iter = make_multiple_subtree_iterator(@root_keys);

    foreach my $test (@tests) {
        my $key_path = $test->[0];
        my $value_name = $test->[1];
        my @changes = @{$test->[2]};
        my $changes_as_text = join ", ", map { "'$_'" } @changes;

        my $desc = "$os";

        my ($keys_ref, $values_ref) = $subtree_iter->get_next;
        my @keys = @$keys_ref;
        my $any_key = (grep { defined } @keys)[0];

        if (defined $values_ref) {
            my @values = @$values_ref;
            my $any_value = (grep { defined } @values)[0];

            is($any_value->get_name, $value_name,
                "$desc comparing values " . Dumper($value_name));

            is_deeply([compare_multiple_values(@values)], \@changes,
                "$desc ...changes are ($changes_as_text)");
        }
        else {
            is($any_key->get_path, $key_path,
                "$desc comparing keys " . Dumper($key_path));

            is_deeply([compare_multiple_keys(@keys)], \@changes,
                "$desc ...changes are ($changes_as_text)");

        }
    }
}

{
    my @filenames = map { find_file($_) } qw(win95_compare_tests1.rf
                                             win95_compare_tests2.rf
                                             win95_compare_tests3.rf);

    my @registries = map { Parse::Win32Registry->new($_) } @filenames;

    my $num = 0;
    foreach my $registry (@registries) {
        ok(defined($registry), 'registry '.++$num.' defined');
        isa_ok($registry, 'Parse::Win32Registry::Win95::File');
    }

    my @tests = (
        ['', '', ['', '', ''],],
        ['\key1', '', ['', '', ''],],
        ['\key1', 'value1', ['', '', ''],],
        ['\key1', 'value2', ['', '', ''],],
        ['\key1', 'value3', ['', '', ''],],
        ['\key1', 'value4', ['', 'DELETED', ''],],
        ['\key1', 'value5', ['', '', 'ADDED'],],
        ['\key2', '', ['', '', ''],],
        ['\key2\key3', '', ['', '', ''],],
        ['\key2\key4', '', ['', 'DELETED', ''],],
        ['\key2\key5', '', ['', '', 'ADDED'],],
    );

    run_compare_tests(\@registries, @tests);
}

{
    my @filenames = map { find_file($_) } qw(winnt_compare_tests1.rf
                                             winnt_compare_tests2.rf
                                             winnt_compare_tests3.rf);

    my @registries = map { Parse::Win32Registry->new($_) } @filenames;

    my $num = 0;
    foreach my $registry (@registries) {
        ok(defined($registry), 'registry '.++$num.' defined');
        isa_ok($registry, 'Parse::Win32Registry::WinNT::File');
    }

    my @tests = (
        ['$$$PROTO.HIV', '', ['', '', ''],],
        ['$$$PROTO.HIV\key1', '', ['', '', ''],],
        ['$$$PROTO.HIV\key1', 'value1', ['', '', ''],],
        ['$$$PROTO.HIV\key1', 'value2', ['', '', ''],],
        ['$$$PROTO.HIV\key1', 'value3', ['', '', ''],],
        ['$$$PROTO.HIV\key1', 'value4', ['', 'DELETED', ''],],
        ['$$$PROTO.HIV\key1', 'value5', ['', '', 'ADDED'],],
        ['$$$PROTO.HIV\key2', '', ['', '', ''],],
        ['$$$PROTO.HIV\key2\key3', '', ['', '', ''],],
        ['$$$PROTO.HIV\key2\key4', '', ['', 'DELETED', ''],],
        ['$$$PROTO.HIV\key2\key5', '', ['', '', 'ADDED'],],
    );

    run_compare_tests(\@registries, @tests);
}
