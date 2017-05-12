use strict;
use warnings;

use Test::More 'no_plan';
use Parse::Win32Registry 0.60;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_entry_tests
{
    my $registry = shift;
    my @tests = @_;

    my ($os) = ref($registry) =~ /Win(NT|95)/;

    foreach my $loop (1..2) {
        $registry->move_to_first_entry if $loop > 1; # check reset works
        my $entry_num = 0;
        foreach my $test (@tests) {
            my $offset = $test->{offset};
            my $length = $test->{length};
            my $tag = $test->{tag};
            my $allocated = $test->{allocated};
            my $as_string = $test->{as_string};
            $entry_num++;

            my $desc = sprintf "(pass $loop) $os entry at 0x%x", $offset;

            my $entry = $registry->get_next_entry;

            ok(defined($entry), "$desc defined (valid entry)");
            is($entry->get_offset, $offset, "$desc get_offset");
            is($entry->get_length, $length, "$desc get_length");
            is($entry->get_tag, $tag, "$desc get_tag");
            is($entry->is_allocated, $allocated, "$desc is_allocated");
            is($entry->as_string, $as_string, "$desc as_string");
        }

        # check iterator is empty
        my $entry = $registry->get_next_entry;
        my $desc = "(pass $loop) $os";
        ok(!defined $entry, "$desc entry undefined (iterator finished)");
    }
}

{
    my $filename = find_file('win95_entry_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::Win95::File');

    my @tests = (
        {
            offset => 0x40,
            length => 28,
            tag => "rgkn key",
            allocated => 1,
            as_string => "",
        },
        {
            offset => 0x5c,
            length => 28,
            tag => "rgkn key",
            allocated => 1,
            as_string => "\\key1",
        },
        {
            offset => 0x78,
            length => 28,
            tag => "rgkn key",
            allocated => 1,
            as_string => "\\key2",
        },
        {
            offset => 0xb4,
            length => 68,
            tag => "rgdb key",
            allocated => 1,
            as_string => "(rgdb key)",
        },
        {
            offset => 0xcc,
            length => 22,
            tag => "rgdb value",
            allocated => 1,
            as_string => "value1 (REG_DWORD) = 0x00000000 (0)",
        },
        {
            offset => 0xe2,
            length => 22,
            tag => "rgdb value",
            allocated => 1,
            as_string => "value2 (REG_DWORD) = 0x00000000 (0)",
        },
        {
            offset => 0xf8,
            length => 68,
            tag => "rgdb key",
            allocated => 1,
            as_string => "(rgdb key)",
        },
        {
            offset => 0x110,
            length => 22,
            tag => "rgdb value",
            allocated => 1,
            as_string => "value3 (REG_DWORD) = 0x00000000 (0)",
        },
        {
            offset => 0x126,
            length => 22,
            tag => "rgdb value",
            allocated => 1,
            as_string => "value4 (REG_DWORD) = 0x00000000 (0)",
        },

    );
    run_entry_tests($registry, @tests);
}

{
    my $filename = find_file('winnt_entry_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::WinNT::File');

    my @tests = (
        {
            offset => 0x1020,
            length => 96,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV [2000-08-06T23:42:36Z]",
        },
        {
            offset => 0x1080,
            length => 104,
            tag => "sk",
            allocated => 1,
            as_string => "(security entry)",
        },
        {
            offset => 0x10e8,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key1 [2001-06-28T18:27:34Z]",
        },
        {
            offset => 0x1140,
            length => 16,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1150,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2 [2002-05-20T13:12:31Z]",
        },
        {
            offset => 0x11a8,
            length => 16,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x11b8,
            length => 24,
            tag => "lf",
            allocated => 1,
            as_string => "(subkey list entry)",
        },
        {
            offset => 0x11d0,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key1\\key3 [2003-04-11T07:57:29Z]",
        },
        {
            offset => 0x1228,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key1\\key4 [2004-03-02T02:42:27Z]",
        },
        {
            offset => 0x1280,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key1\\key5 [2005-01-21T21:27:24Z]",
        },
        {
            offset => 0x12d8,
            length => 32,
            tag => "lh",
            allocated => 1,
            as_string => "(subkey list entry)",
        },
        {
            offset => 0x12f8,
            length => 32,
            tag => "",
            allocated => 0,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1318,
            length => 32,
            tag => "vk",
            allocated => 1,
            as_string => "sz1 (REG_SZ) = www.perl.org",
        },
        {
            offset => 0x1338,
            length => 32,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1358,
            length => 32,
            tag => "vk",
            allocated => 1,
            as_string => "binary1 (REG_BINARY) = 01 02 03 04 05 06 07 08",
        },
        {
            offset => 0x1378,
            length => 16,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1388,
            length => 32,
            tag => "vk",
            allocated => 1,
            as_string => "dword1 (REG_DWORD) = 0x04030201 (67305985)",
        },
        {
            offset => 0x13a8,
            length => 40,
            tag => "vk",
            allocated => 1,
            as_string => "multi_sz1 (REG_MULTI_SZ) = [0] abcde [1] fghij [2] klmno",
        },
        {
            offset => 0x13d0,
            length => 48,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1400,
            length => 32,
            tag => "vk",
            allocated => 1,
            as_string => "type500 (REG_500) = 01 02 03 04",
        },
        {
            offset => 0x1420,
            length => 8,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1428,
            length => 24,
            tag => "",
            allocated => 1,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1440,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key6 [2005-12-13T16:12:22Z]",
        },
        {
            offset => 0x1498,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key7 [2006-11-04T10:57:20Z]",
        },
        {
            offset => 0x14f0,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key8 [2007-09-26T05:42:18Z]",
        },
        {
            offset => 0x1548,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key9 [2008-08-17T00:27:15Z]",
        },
        {
            offset => 0x15a0,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key10 [2009-07-08T19:12:13Z]",
        },
        {
            offset => 0x15f8,
            length => 88,
            tag => "nk",
            allocated => 1,
            as_string => "\$\$\$PROTO.HIV\\key2\\key11 [2010-05-30T13:57:11Z]",
        },
        {
            offset => 0x1650,
            length => 20,
            tag => "li",
            allocated => 1,
            as_string => "(subkey list entry)",
        },
        {
            offset => 0x1664,
            length => 48,
            tag => "",
            allocated => 0,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1694,
            length => 20,
            tag => "li",
            allocated => 1,
            as_string => "(subkey list entry)",
        },
        {
            offset => 0x16a8,
            length => 48,
            tag => "",
            allocated => 0,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x16d8,
            length => 16,
            tag => "ri",
            allocated => 1,
            as_string => "(subkey list entry)",
        },
        {
            offset => 0x16e8,
            length => 48,
            tag => "",
            allocated => 0,
            as_string => "(unidentified entry)",
        },
        {
            offset => 0x1718,
            length => 2280,
            tag => "",
            allocated => 0,
            as_string => "(unidentified entry)",
        },
    );
    run_entry_tests($registry, @tests);
}
