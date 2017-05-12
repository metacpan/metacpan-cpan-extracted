use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;
use Parse::Win32Registry 0.60 qw(:REG_);

Parse::Win32Registry::disable_warnings;

$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

sub run_value_tests
{
    my $key = shift;
    my @tests = @_;

    my ($os) = ref($key) =~ /Win(NT|95)/;

    foreach my $test (@tests) {
        my $name = $test->{name};
        my $type = $test->{type};
        my $type_as_string = $test->{type_as_string};
        my $data = $test->{data};
        my $list_data = $test->{list_data};
        my $raw_data = $test->{raw_data};
        my $data_as_string = $test->{data_as_string};
        my $as_regedit_export = $test->{as_regedit_export};

        my $desc = "$os " . Dumper($name);

        my $value = $key->get_value($name);
        ok(defined($value), "$desc value defined (valid value)");
        is($value->get_name, $name, "$desc get_name");
        is($value->get_type, $type, "$desc get_type");
        is($value->get_type_as_string, $type_as_string,
            "$desc get_type_as_string");
        if (defined($data)) {
            if ($type == REG_DWORD) {
                cmp_ok($value->get_data, '==', $data,
                    "$desc get_data");
                cmp_ok($key->get_value_data($name), '==', $data,
                    "$desc get_value_data");
            }
            else {
                is($value->get_data, $data,
                    "$desc get_data");
                is($key->get_value_data($name), $data,
                    "$desc get_value_data");
            }
        }
        else {
            ok(!defined($value->get_data),
                "$desc get_data undefined (invalid data)");
            ok(!defined($key->get_value_data($name)),
                "$desc get_value_data undefined (invalid data)");
        }
        if (defined($raw_data)) {
            is($value->get_raw_data, $raw_data,
                "$desc get_raw_data")
                or diag Dumper($value->get_raw_data);
        }
        else {
            ok(!defined($value->get_raw_data),
                "$desc get_raw_data undefined (invalid data)")
                or diag Dumper($value->get_raw_data);
        }
        if (defined($list_data)) {
            is_deeply([$value->get_data], $list_data,
                "$desc (list) get_data")
                or diag Dumper([$value->get_data]);
        }
        is($value->get_data_as_string, $data_as_string,
            "$desc get_data_as_string");
        my $name_or_default = $name eq '' ? '(Default)' : $name;
        my $value_as_string
            = "$name_or_default ($type_as_string) = $data_as_string";
        is($value->as_string, $value_as_string,
            "$desc as_string");
        is($value->as_regedit_export, $as_regedit_export,
            "$desc as_regedit_export");
    }
}

{
    my $filename = find_file('win95_value_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::Win95::File');

    my $root_key = $registry->get_root_key;
    ok(defined($registry), 'root key defined');
    isa_ok($root_key, 'Parse::Win32Registry::Win95::Key');
    is($root_key->get_name, '', 'root key name');

    my $key1 = $root_key->get_subkey('key1');
    ok(defined($key1), 'key1 defined');
    is($key1->get_name, 'key1', 'key1 name');

    my @tests = (
        {
            name => 'sz1',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'www.perl.org',
            data_as_string => 'www.perl.org',
            as_regedit_export => qq{"sz1"="www.perl.org"\n},
            raw_data => "www.perl.org",
        },
        {
            name => 'sz2',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'www.perl.org',
            data_as_string => 'www.perl.org',
            as_regedit_export => qq{"sz2"="www.perl.org"\n},
            raw_data => "www.perl.org\0",
        },
        {
            name => 'sz3',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz3"=""\n},
            raw_data => "",
        },
        {
            name => 'sz4',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz4"=""\n},
            raw_data => "\0",
        },
        {
            name => 'binary1',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => "\x01\x02\x03\x04\x05\x06\x07\x08",
            data_as_string => '01 02 03 04 05 06 07 08',
            as_regedit_export => qq{"binary1"=hex:01,02,03,04,05,06,07,08\n},
            raw_data => "\x01\x02\x03\x04\x05\x06\x07\x08",
        },
        {
            name => 'binary2',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"binary2"=hex:\n},
            raw_data => "",
        },
        {
            name => 'dword1',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 67305985,
            data_as_string => '0x04030201 (67305985)',
            as_regedit_export => qq{"dword1"=dword:04030201\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword2',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword2"=dword:\n},
            raw_data => "\x01\x02\x03\x04\x05\x06",
        },
        {
            name => 'dword3',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword3"=dword:\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword4',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword4"=dword:\n},
            raw_data => "",
        },
        {
            name => 'dword5',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"dword5"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => 'dword6',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0x7fffffff,
            data_as_string => '0x7fffffff (2147483647)',
            as_regedit_export => qq{"dword6"=dword:7fffffff\n},
            raw_data => "\xff\xff\xff\x7f",
        },
        {
            name => 'dword7',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0x80000000,
            data_as_string => '0x80000000 (2147483648)',
            as_regedit_export => qq{"dword7"=dword:80000000\n},
            raw_data => "\x00\x00\x00\x80",
        },
        {
            name => 'dword8',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0xffffffff,
            data_as_string => '0xffffffff (4294967295)',
            as_regedit_export => qq{"dword8"=dword:ffffffff\n},
            raw_data => "\xff\xff\xff\xff",
        },
        {
            name => 'dword_big_endian1',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 16909060,
            data_as_string => '0x01020304 (16909060)',
            as_regedit_export => qq{"dword_big_endian1"=hex(5):01,02,03,04\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword_big_endian2',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian2"=hex(5):01,02,03,04,05,06\n},
            raw_data => "\x01\x02\x03\x04\x05\x06",
        },
        {
            name => 'dword_big_endian3',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian3"=hex(5):01,02\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword_big_endian4',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian4"=hex(5):\n},
            raw_data => "",
        },
        {
            name => 'dword_big_endian5',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"dword_big_endian5"=hex(5):00,00,00,00\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => 'dword_big_endian6',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0x7fffffff,
            data_as_string => '0x7fffffff (2147483647)',
            as_regedit_export => qq{"dword_big_endian6"=hex(5):7f,ff,ff,ff\n},
            raw_data => "\x7f\xff\xff\xff",
        },
        {
            name => 'dword_big_endian7',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0x80000000,
            data_as_string => '0x80000000 (2147483648)',
            as_regedit_export => qq{"dword_big_endian7"=hex(5):80,00,00,00\n},
            raw_data => "\x80\x00\x00\x00",
        },
        {
            name => 'dword_big_endian8',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0xffffffff,
            data_as_string => '0xffffffff (4294967295)',
            as_regedit_export => qq{"dword_big_endian8"=hex(5):ff,ff,ff,ff\n},
            raw_data => "\xff\xff\xff\xff",
        },
        {
            name => 'multi_sz1',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz1"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00,00,00,00,00\n},
            raw_data => "abcde\0fghij\0klmno\0\0",
        },
        {
            name => 'multi_sz2',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz2"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00,00,00\n},
            raw_data => "abcde\0fghij\0klmno\0",
        },
        {
            name => 'multi_sz3',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz3"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00\n},
            raw_data => "abcde\0fghij\0klmno",
        },
        {
            name => 'multi_sz4',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz4"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00,00,00,00,00\n},
            raw_data => "abcde\0\0klmno\0\0",
        },
        {
            name => 'multi_sz5',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz5"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00,00,00\n},
            raw_data => "abcde\0\0klmno\0",
        },
        {
            name => 'multi_sz6',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz6"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00\n},
            raw_data => "abcde\0\0klmno",
        },
        {
            name => 'multi_sz7',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz7"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00\n},
            raw_data => "abcde\0\0",
        },
        {
            name => 'multi_sz8',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz8"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00\n},
            raw_data => "abcde\0",
        },
        {
            name => 'multi_sz9',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz9"=hex(7):61,00,62,00,63,00,64,00,65,00\n},
            raw_data => "abcde",
        },
        {
            name => 'multi_sz10',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz10"=hex(7):00,00,00,00\n},
            raw_data => "\0\0",
        },
        {
            name => 'multi_sz11',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz11"=hex(7):00,00\n},
            raw_data => "\0",
        },
        {
            name => 'multi_sz12',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz12"=hex(7):\n},
            raw_data => "",
        },
        {
            name => 'type500',
            type => 500,
            type_as_string => 'REG_500',
            data => "\x01\x02\x03\x04\x05\x06\x07\x08",
            data_as_string => '01 02 03 04 05 06 07 08',
            as_regedit_export => qq{"type500"=hex(1f4):01,02,03,04,05,06,07,08\n},
            raw_data => "\x01\x02\x03\x04\x05\x06\x07\x08",
        },
        {
            name => '',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{@=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => '0',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"0"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => "\0",
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"\0"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => "\0name",
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"\0name"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
    );

    run_value_tests($key1, @tests);
}

{
    my $filename = find_file('winnt_value_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    isa_ok($registry, 'Parse::Win32Registry::WinNT::File');

    my $root_key = $registry->get_root_key;
    isa_ok($root_key, 'Parse::Win32Registry::WinNT::Key');
    is($root_key->get_name, '$$$PROTO.HIV', 'Root Key name');

    my $key1 = $root_key->get_subkey('key1');
    ok(defined($key1), 'key1 defined');
    is($key1->get_name, 'key1', 'key1 name');

    my @tests = (
        {
            name => 'sz1',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'www.perl.org',
            data_as_string => 'www.perl.org',
            as_regedit_export => qq{"sz1"="www.perl.org"\n},
            raw_data => "w\0w\0w\0.\0p\0e\0r\0l\0.\0o\0r\0g\0",
        },
        {
            name => 'sz2',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'www.perl.org',
            data_as_string => 'www.perl.org',
            as_regedit_export => qq{"sz2"="www.perl.org"\n},
            raw_data => "w\0w\0w\0.\0p\0e\0r\0l\0.\0o\0r\0g\0\0\0",
        },
        {
            name => 'sz3',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz3"=""\n},
            raw_data => "",
        },
        {
            name => 'sz4',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz4"=""\n},
            raw_data => "\0\0",
        },
        {
            name => 'sz5',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'ab',
            data_as_string => 'ab',
            as_regedit_export => qq{"sz5"="ab"\n},
            raw_data => "a\0b\0",
        },
        {
            name => 'sz6',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => 'a',
            data_as_string => 'a',
            as_regedit_export => qq{"sz6"="a"\n},
            raw_data => "a\0\0\0",
        },
        {
            name => 'sz7',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz7"=""\n},
            raw_data => "",
        },
        {
            name => 'sz8',
            type => REG_SZ,
            type_as_string => 'REG_SZ',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"sz8"=""\n},
            raw_data => "\0\0",
        },
        {
            name => 'binary1',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => "\x01\x02\x03\x04\x05\x06\x07\x08",
            data_as_string => '01 02 03 04 05 06 07 08',
            as_regedit_export => qq{"binary1"=hex:01,02,03,04,05,06,07,08\n},
            raw_data => "\x01\x02\x03\x04\x05\x06\x07\x08",
        },
        {
            name => 'binary2',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"binary2"=hex:\n},
            raw_data => "",
        },
        {
            name => 'binary3',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => "\x01\x02\x03\x04",
            data_as_string => '01 02 03 04',
            as_regedit_export => qq{"binary3"=hex:01,02,03,04\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'binary4',
            type => REG_BINARY,
            type_as_string => 'REG_BINARY',
            data => '',
            data_as_string => '(no data)',
            as_regedit_export => qq{"binary4"=hex:\n},
            raw_data => "",
        },
        {
            name => 'dword1',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 67305985,
            data_as_string => '0x04030201 (67305985)',
            as_regedit_export => qq{"dword1"=dword:04030201\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword2',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword2"=dword:\n},
            raw_data => "\x01\x02\x03\x04\x05\x06",
        },
        {
            name => 'dword3',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword3"=dword:\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword4',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword4"=dword:\n},
            raw_data => "",
        },
        {
            name => 'dword5',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 67305985,
            data_as_string => '0x04030201 (67305985)',
            as_regedit_export => qq{"dword5"=dword:04030201\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword6',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword6"=dword:\n},
            raw_data => undef,
        },
        {
            name => 'dword7',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword7"=dword:\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword8',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword8"=dword:\n},
            raw_data => "",
        },
        {
            name => 'dword9',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"dword9"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => 'dword10',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0x7fffffff,
            data_as_string => '0x7fffffff (2147483647)',
            as_regedit_export => qq{"dword10"=dword:7fffffff\n},
            raw_data => "\xff\xff\xff\x7f",
        },
        {
            name => 'dword11',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0x80000000,
            data_as_string => '0x80000000 (2147483648)',
            as_regedit_export => qq{"dword11"=dword:80000000\n},
            raw_data => "\x00\x00\x00\x80",
        },
        {
            name => 'dword12',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0xffffffff,
            data_as_string => '0xffffffff (4294967295)',
            as_regedit_export => qq{"dword12"=dword:ffffffff\n},
            raw_data => "\xff\xff\xff\xff",
        },
        {
            name => 'dword_big_endian1',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 16909060,
            data_as_string => '0x01020304 (16909060)',
            as_regedit_export => qq{"dword_big_endian1"=hex(5):01,02,03,04\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword_big_endian2',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian2"=hex(5):01,02,03,04,05,06\n},
            raw_data => "\x01\x02\x03\x04\x05\x06",
        },
        {
            name => 'dword_big_endian3',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian3"=hex(5):01,02\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword_big_endian4',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian4"=hex(5):\n},
            raw_data => "",
        },
        {
            name => 'dword_big_endian5',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 16909060,
            data_as_string => '0x01020304 (16909060)',
            as_regedit_export => qq{"dword_big_endian5"=hex(5):01,02,03,04\n},
            raw_data => "\x01\x02\x03\x04",
        },
        {
            name => 'dword_big_endian6',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian6"=hex(5):\n},
            raw_data => undef,
        },
        {
            name => 'dword_big_endian7',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian7"=hex(5):01,02\n},
            raw_data => "\x01\x02",
        },
        {
            name => 'dword_big_endian8',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => undef,
            data_as_string => '(invalid data)',
            as_regedit_export => qq{"dword_big_endian8"=hex(5):\n},
            raw_data => "",
        },
        {
            name => 'dword_big_endian9',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"dword_big_endian9"=hex(5):00,00,00,00\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => 'dword_big_endian10',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0x7fffffff,
            data_as_string => '0x7fffffff (2147483647)',
            as_regedit_export => qq{"dword_big_endian10"=hex(5):7f,ff,ff,ff\n},
            raw_data => "\x7f\xff\xff\xff",
        },
        {
            name => 'dword_big_endian11',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0x80000000,
            data_as_string => '0x80000000 (2147483648)',
            as_regedit_export => qq{"dword_big_endian11"=hex(5):80,00,00,00\n},
            raw_data => "\x80\x00\x00\x00",
        },
        {
            name => 'dword_big_endian12',
            type => REG_DWORD_BIG_ENDIAN,
            type_as_string => 'REG_DWORD_BIG_ENDIAN',
            data => 0xffffffff,
            data_as_string => '0xffffffff (4294967295)',
            as_regedit_export => qq{"dword_big_endian12"=hex(5):ff,ff,ff,ff\n},
            raw_data => "\xff\xff\xff\xff",
        },
        {
            name => 'multi_sz1',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz1"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00,00,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0f\0g\0h\0i\0j\0\0\0k\0l\0m\0n\0o\0\0\0\0\0",
        },
        {
            name => 'multi_sz2',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz2"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0f\0g\0h\0i\0j\0\0\0k\0l\0m\0n\0o\0\0\0",
        },
        {
            name => 'multi_sz3',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde fghij klmno",
            list_data => ['abcde', 'fghij', 'klmno'],
            data_as_string => '[0] abcde [1] fghij [2] klmno',
            as_regedit_export => qq{"multi_sz3"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,66,00,67,00,68,00,69,00,\\\n  6a,00,00,00,6b,00,6c,00,6d,00,6e,00,6f,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0f\0g\0h\0i\0j\0\0\0k\0l\0m\0n\0o\0",
        },
        {
            name => 'multi_sz4',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz4"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00,00,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0\0\0k\0l\0m\0n\0o\0\0\0\0\0",
        },
        {
            name => 'multi_sz5',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz5"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0\0\0k\0l\0m\0n\0o\0\0\0",
        },
        {
            name => 'multi_sz6',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde  klmno",
            list_data => ['abcde', '', 'klmno'],
            data_as_string => '[0] abcde [1]  [2] klmno',
            as_regedit_export => qq{"multi_sz6"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00,6b,00,6c,00,6d,00,\\\n  6e,00,6f,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0\0\0k\0l\0m\0n\0o\0",
        },
        {
            name => 'multi_sz7',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz7"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0\0\0",
        },
        {
            name => 'multi_sz8',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz8"=hex(7):61,00,62,00,63,00,64,00,65,00,00,00\n},
            raw_data => "a\0b\0c\0d\0e\0\0\0",
        },
        {
            name => 'multi_sz9',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "abcde",
            list_data => ['abcde'],
            data_as_string => '[0] abcde',
            as_regedit_export => qq{"multi_sz9"=hex(7):61,00,62,00,63,00,64,00,65,00\n},
            raw_data => "a\0b\0c\0d\0e\0",
        },
        {
            name => 'multi_sz10',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz10"=hex(7):00,00,00,00\n},
            raw_data => "\0\0\0\0",
        },
        {
            name => 'multi_sz11',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz11"=hex(7):00,00\n},
            raw_data => "\0\0",
        },
        {
            name => 'multi_sz12',
            type => REG_MULTI_SZ,
            type_as_string => 'REG_MULTI_SZ',
            data => "",
            list_data => [''],
            data_as_string => '(no data)',
            as_regedit_export => qq{"multi_sz12"=hex(7):\n},
            raw_data => "",
        },
        {
            name => 'type500',
            type => 500,
            type_as_string => 'REG_500',
            data => "\x01\x02\x03\x04\x05\x06\x07\x08",
            data_as_string => '01 02 03 04 05 06 07 08',
            as_regedit_export => qq{"type500"=hex(1f4):01,02,03,04,05,06,07,08\n},
            raw_data => "\x01\x02\x03\x04\x05\x06\x07\x08",
        },
        {
            name => '',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{@=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => '0',
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"0"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => "\0",
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"\0"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
        {
            name => "\0name",
            type => REG_DWORD,
            type_as_string => 'REG_DWORD',
            data => 0,
            data_as_string => '0x00000000 (0)',
            as_regedit_export => qq{"\0name"=dword:00000000\n},
            raw_data => "\x00\x00\x00\x00",
        },
    );

    run_value_tests($key1, @tests);
}
