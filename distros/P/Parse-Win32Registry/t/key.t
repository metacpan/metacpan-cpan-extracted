use strict;
use warnings;

use Data::Dumper;
use Test::More 'no_plan';
use Parse::Win32Registry 0.60;

$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_key_tests
{
    my $root_key = shift;
    my @tests = @_;

    my ($os) = ref($root_key) =~ /Win(NT|95)/;

    my $root_key_name = $root_key->get_name; # should already be tested

    foreach my $test (@tests) {
        my $path = $test->{path};
        my $name = $test->{name};
        my $num_subkeys = $test->{num_subkeys};
        my $num_values = $test->{num_values};
        my $timestamp = $test->{timestamp};
        my $timestamp_as_string = $test->{timestamp_as_string};
        my $class_name = $test->{class_name};

        my $key_path = "$root_key_name\\$path";

        my $desc = "$os " . Dumper($name);

        my $key = $root_key->get_subkey($path);
        ok(defined($key), "$desc key defined (valid key)")
            or diag Dumper $key_path;
        ok(!$key->is_root, "$desc key is not root");
        is($key->get_name, $name, "$desc get_name");
        is($key->get_path, $key_path, "$desc get_path");

        my @subkeys = $key->get_list_of_subkeys;
        is(@subkeys, $num_subkeys, "$desc has $num_subkeys subkeys");

        my @values = $key->get_list_of_values;
        is(@values, $num_values, "$desc has $num_values values");

        if (defined($timestamp)) {
            cmp_ok($key->get_timestamp, '==', $timestamp,
                "$desc get_timestamp");
        }
        else {
            ok(!defined($key->get_timestamp),
                "$desc get_timestamp undefined");
        }

        is($key->get_timestamp_as_string,
            $timestamp_as_string, "$desc get_timestamp_as_string");

        if (defined($class_name)) {
            is($key->get_class_name, $class_name, "$desc get_class_name");
        }
        else {
            ok(!defined($key->get_class_name),
                "$desc get_class_name undefined (not present)");
        }

        my $as_string = defined($timestamp)
                      ? "$key_path [$timestamp_as_string]"
                      : "$key_path";
        is($key->as_string, $as_string, "$desc as_string");

        is($key->as_regedit_export, "[$key_path]\n", "$desc as_regedit_export");

        # parent key tests
        my $parent_key = $key->get_parent;
        ok(defined($parent_key), "$desc parent key defined (valid key)");

        # $parent_key->get_subkey should be the same as key
        my $clone_key = $parent_key->get_subkey($name);
        ok(defined($clone_key), "$desc parent subkey defined (valid key)");
        is($clone_key->get_path, "$key_path",
            "$desc parent subkey get_path");
        is($clone_key->get_timestamp_as_string,
            $timestamp_as_string,
            "$desc parent subkey get_timestamp_as_string");

        is($key->regenerate_path, $key_path, "$desc regenerate_path");
        is($key->get_path, $key_path, "$desc get_path after regenerate_path");
    }
}

{
    my $filename = find_file('win95_key_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::Win95::File');

    my $root_key = $registry->get_root_key;
    ok(defined($registry), 'root key defined');
    isa_ok($root_key, 'Parse::Win32Registry::Win95::Key');
    ok($root_key->is_root, 'root key is root');
    is($root_key->get_name, '', 'root key name');
    is($root_key->get_path, '', 'root key path');
    is($root_key->as_regedit_export, "[]\n", 'root key as_regedit_export');
    my @subkeys = $root_key->get_list_of_subkeys;
    is(@subkeys, 3, 'root key has 3 subkeys');

    my @tests = (
        {
            path => "key1",
            name => "key1",
            num_subkeys => 3,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key1\\key4",
            name => "key4",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key1\\key5",
            name => "key5",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key1\\key6",
            name => "key6",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2",
            name => "key2",
            num_subkeys => 6,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key7",
            name => "key7",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key8",
            name => "key8",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key9",
            name => "key9",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key10",
            name => "key10",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key11",
            name => "key11",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key2\\key12",
            name => "key12",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3",
            name => "key3",
            num_subkeys => 5,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3\\",
            name => "",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3\\0",
            name => "0",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3\\\0",
            name => "\0",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3\\\0name",
            name => "\0name",
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
        {
            path => "key3\\" . pack("U*", 0xe0..0xff),
            name => pack("U*", 0xe0..0xff),
            num_subkeys => 0,
            num_values => 0,
            timestamp => undef,
            timestamp_as_string => "(undefined)",
        },
    );
    run_key_tests($root_key, @tests);
}

{
    my $filename = find_file('winnt_key_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::WinNT::File');

    my $root_key = $registry->get_root_key;
    ok(defined($registry), 'root key defined');
    isa_ok($root_key, 'Parse::Win32Registry::WinNT::Key');
    ok($root_key->is_root, 'root key is_root');
    is($root_key->get_name, '$$$PROTO.HIV', 'root key name');
    is($root_key->get_path, '$$$PROTO.HIV', 'root key path');
    is($root_key->as_regedit_export, "[\$\$\$PROTO.HIV]\n",
        'root key as_regedit_export');
    my @subkeys = $root_key->get_list_of_subkeys;
    is(@subkeys, 3, 'root key has 3 subkeys');

    my @tests = (
        {
            path => "key1",
            name => "key1",
            flags => 0x20,
            num_subkeys => 3,
            num_values => 0,
            timestamp => 993752854,
            timestamp_as_string => "2001-06-28T18:27:34Z",
            class_name => "key1",
        },
        {
            path => "key1\\key4",
            name => "key4",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1021900351,
            timestamp_as_string => "2002-05-20T13:12:31Z",
        },
        {
            path => "key1\\key5",
            name => "key5",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1022010303,
            timestamp_as_string => "2002-05-21T19:45:03Z",
        },
        {
            path => "key1\\key6",
            name => "key6",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1022120254,
            timestamp_as_string => "2002-05-23T02:17:34Z",
        },
        {
            path => "key2",
            name => "key2",
            flags => 0x20,
            num_subkeys => 6,
            num_values => 0,
            timestamp => 993862805,
            timestamp_as_string => "2001-06-30T01:00:05Z",
            class_name => "key2",
        },
        {
            path => "key2\\key7",
            name => "key7",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050047849,
            timestamp_as_string => "2003-04-11T07:57:29Z",
        },
        {
            path => "key2\\key8",
            name => "key8",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050157800,
            timestamp_as_string => "2003-04-12T14:30:00Z",
        },
        {
            path => "key2\\key9",
            name => "key9",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050267751,
            timestamp_as_string => "2003-04-13T21:02:31Z",
        },
        {
            path => "key2\\key10",
            name => "key10",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050377703,
            timestamp_as_string => "2003-04-15T03:35:03Z",
        },
        {
            path => "key2\\key11",
            name => "key11",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050487654,
            timestamp_as_string => "2003-04-16T10:07:34Z",
        },
        {
            path => "key2\\key12",
            name => "key12",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1050597605,
            timestamp_as_string => "2003-04-17T16:40:05Z",
        },
        {
            path => "key3",
            name => "key3",
            flags => 0x20,
            num_subkeys => 6,
            num_values => 0,
            timestamp => 993972756,
            timestamp_as_string => "2001-07-01T07:32:36Z",
            class_name => "key3",
        },
        {
            path => "key3\\",
            name => "",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078195347,
            timestamp_as_string => "2004-03-02T02:42:27Z",
            class_name => "",
        },
        {
            path => "key3\\0",
            name => "0",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078305298,
            timestamp_as_string => "2004-03-03T09:14:58Z",
            class_name => "0",
        },
        {
            path => "key3\\\0",
            name => "\0",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078415249,
            timestamp_as_string => "2004-03-04T15:47:29Z",
            class_name => "\0",
        },
        {
            path => "key3\\\0name",
            name => "\0name",
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078525200,
            timestamp_as_string => "2004-03-05T22:20:00Z",
            class_name => "\0name",
        },
        {
            path => "key3\\" . pack("U*", 0xe0..0xff),
            name => pack("U*", 0xe0..0xff),
            flags => 0x20,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078635151,
            timestamp_as_string => "2004-03-07T04:52:31Z",
            class_name => pack("U*", 0xe0..0xff),
        },
        {
            path => "key3\\" . pack("U*", 0x3b1..0x3c9),
            name => pack("U*", 0x3b1..0x3c9),
            flags => 0x0,
            num_subkeys => 0,
            num_values => 0,
            timestamp => 1078745103,
            timestamp_as_string => "2004-03-08T11:25:03Z",
            class_name => pack("U*", 0x3b1..0x3c9),
        },
    );
    run_key_tests($root_key, @tests);
}
