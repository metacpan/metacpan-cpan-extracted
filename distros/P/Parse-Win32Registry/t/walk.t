use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;
use Parse::Win32Registry 0.60;

$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;


sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_walk_tests
{
    my $key = shift;
    my @tests = @_;

    my ($os) = ref($key) =~ /Win(NT|95)/;

    my $subtree_iter = $key->walk(sub {
            my $key = shift;
            my $key_path = shift @tests;
            is($key->get_path, $key_path,
                "$os entering key " . Dumper($key_path));
        },
        sub {
            my $value = shift;
            my $name = shift @tests;
            is($value->get_name, $name,
                "$os value " . Dumper($name));
        },
        sub {
            my $key = shift;
            my $key_path = shift @tests;
            is($key->get_path, $key_path,
                "$os leaving key " . Dumper($key_path));
        },
    );
}

{
    my $filename = find_file('win95_iter_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);

    my $root_key = $registry->get_root_key;

    my @tests = (
        "", # KEY ENTER
        "\\key1", # KEY ENTER
        "value1", # VALUE
        "value2", # VALUE
        "\\key1\\key3", # KEY ENTER
        "value5", # VALUE
        "value6", # VALUE
        "\\key1\\key3", # KEY EXIT
        "\\key1\\key4", # KEY ENTER
        "value7", # VALUE
        "value8", # VALUE
        "\\key1\\key4", # KEY EXIT
        "\\key1", # KEY EXIT
        "\\key2", # KEY ENTER
        "value3", # VALUE
        "value4", # VALUE
        "\\key2\\key5", # KEY ENTER
        "value9", # VALUE
        "value10", # VALUE
        "\\key2\\key5", # KEY EXIT
        "\\key2\\key6", # KEY ENTER
        "value11", # VALUE
        "value12", # VALUE
        "\\key2\\key6", # KEY EXIT
        "\\key2", # KEY EXIT
        "", # KEY EXIT
    );

    run_walk_tests($root_key, @tests);
}

{
    my $filename = find_file('winnt_iter_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);

    my $root_key = $registry->get_root_key;

    my @tests = (
        "\$\$\$PROTO.HIV", # KEY ENTER
        "value1", # VALUE
        "value2", # VALUE
        "\$\$\$PROTO.HIV\\key1", # KEY ENTER
        "value3", # VALUE
        "value4", # VALUE
        "\$\$\$PROTO.HIV\\key1\\key3", # KEY ENTER
        "value7", # VALUE
        "value8", # VALUE
        "\$\$\$PROTO.HIV\\key1\\key3", # KEY EXIT
        "\$\$\$PROTO.HIV\\key1\\key4", # KEY ENTER
        "value9", # VALUE
        "value10", # VALUE
        "\$\$\$PROTO.HIV\\key1\\key4", # KEY EXIT
        "\$\$\$PROTO.HIV\\key1", # KEY EXIT
        "\$\$\$PROTO.HIV\\key2", # KEY ENTER
        "value5", # VALUE
        "value6", # VALUE
        "\$\$\$PROTO.HIV\\key2\\key5", # KEY ENTER
        "value11", # VALUE
        "value12", # VALUE
        "\$\$\$PROTO.HIV\\key2\\key5", # KEY EXIT
        "\$\$\$PROTO.HIV\\key2\\key6", # KEY ENTER
        "value13", # VALUE
        "value14", # VALUE
        "\$\$\$PROTO.HIV\\key2\\key6", # KEY EXIT
        "\$\$\$PROTO.HIV\\key2", # KEY EXIT
        "\$\$\$PROTO.HIV", # KEY EXIT
    );

    run_walk_tests($root_key, @tests);
}
