use strict;
use warnings;

use Test::More 'no_plan';
use Parse::Win32Registry 0.60 qw(
    unpack_sid
    unpack_ace
    unpack_acl
    unpack_security_descriptor
);

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

# unpack_sid tests
my @sid_tests = (
    [
        "SID1",
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        "S-1-5-12",
        12,
    ],
    [
        "SID2",
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00",
        "S-1-5-32-544",
        16,
    ],
    [
        "SID3",
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00",
        "S-1-5-21-1000000-2000000-3000000-500",
        28,
    ],
    [
        "SID4", # extra data
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00\xee\xee\xee\xee",
        "S-1-5-21-1000000-2000000-3000000-500",
        28,
    ],
    [
        "SID5", # no data
        "",
        undef,
    ],
    [
        "SID6", # data too short (or num_sub_auths too large)
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00",
        undef,
    ],
    [
        "SID7", # num_sub_auths invalid
        "\x01\x00\x00\x00\x00\x00\x00\x05",
        undef,
    ],
);

sub check_sid {
    my ($actual_sid, $expected_sid, $desc) = @_;

    ok(defined($actual_sid), "$desc defined") or return;
    is($actual_sid->as_string, $expected_sid, "$desc as_string");
}

foreach my $sid_test (@sid_tests) {
    my ($desc, $data, $sid, $len) = @$sid_test;
    my $unpacked_sid1 = unpack_sid($data);
    my ($unpacked_sid2, $len2) = unpack_sid($data);
    if (defined($sid)) {
        check_sid($unpacked_sid1, $sid, "$desc (scalar) unpack_sid");
        check_sid($unpacked_sid2, $sid, "$desc (list) unpack_sid");
        is($len2, $len, "$desc (list) unpack_sid length");
    }
    else {
        ok(!defined($unpacked_sid1),
            "$desc (scalar) unpack_sid undefined (invalid sid)");
        ok(!defined($unpacked_sid2),
            "$desc (list) unpack_sid undefined (invalid sid)");
    }
}

# unpack_ace tests
my @ace_tests = (
    [
        "ACE1",
        "\x00\x00\x14\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        {
            type => 0,
            type_as_string => 'ACCESS_ALLOWED',
            flags => 0x00,
            mask => 0x80000000,
            trustee => "S-1-5-12",
        },
        20,
    ],
    [
        "ACE2",
        "\x01\x00\x18\x00\x00\x00\x00\x80".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00",
        {
            type => 1,
            type_as_string => 'ACCESS_DENIED',
            flags => 0x00,
            mask => 0x80000000,
            trustee => "S-1-5-32-544",
        },
        24,
    ],
    [
        "ACE3",
        "\x02\x00\x14\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        {
            type => 2,
            type_as_string => 'SYSTEM_AUDIT',
            flags => 0x00,
            mask => 0x80000000,
            trustee => "S-1-5-12",
        },
        20,
    ],
    [
        "ACE4", # extra data
        "\x02\x00\x18\x00\x00\x00\x00\x80".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        "\xee\xee\xee\xee",
        {
            type => 2,
            type_as_string => 'SYSTEM_AUDIT',
            flags => 0x00,
            mask => 0x80000000,
            trustee => "S-1-5-32-544",
        },
        24,
    ],
    [
        "ACE5", # invalid length too short
        "\x00\x00\x00\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        undef,
    ],
    [
        "ACE6", # invalid length too long
        "\x00\x00\xff\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        undef,
    ],
    [
        "ACE7", # invalid type
        "\x03\x00\x14\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        undef,
    ],
    [
        "ACE8", # no data
        "",
        undef,
    ],
    [
        "ACE9", # data too short
        "\x00\x0b\x14\x00\x00\x00\x00\x80",
        undef,
    ],
    [
        "ACE10", # invalid sid (number of sub auths > data)
        "\x00\x0b\x14\x00\x00\x00\x00\x80".
        "\x01\xff\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        undef,
    ],
    [
        "ACE11",
        "\x11\x00\x14\x00\x01\x00\x00\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x10\x00\x10\x00\x00",
        {
            type => 17,
            type_as_string => 'SYSTEM_MANDATORY_LABEL',
            flags => 0x00,
            mask => 0x00000001,
            trustee => "S-1-16-4096",
        },
        20,
    ],
);

sub check_ace {
    my ($actual_ace, $expected_ace, $desc) = @_;

    ok(defined($actual_ace), "$desc defined") or return;
    is($actual_ace->get_type, $expected_ace->{type},
        "$desc get_type");
    is($actual_ace->get_type_as_string, $expected_ace->{type_as_string},
        "$desc get_type_as_string");
    is($actual_ace->get_flags, $expected_ace->{flags},
        "$desc get_flags");
    is($actual_ace->get_access_mask, $expected_ace->{mask},
        "$desc get_access_mask");
    check_sid($actual_ace->get_trustee, $expected_ace->{trustee},
        "$desc get_trustee");
}

foreach my $ace_test (@ace_tests) {
    my ($desc, $data, $ace, $len) = @$ace_test;
    my $unpacked_ace1 = unpack_ace($data);
    my ($unpacked_ace2, $len2) = unpack_ace($data);
    if (defined($ace)) {
        check_ace($unpacked_ace1, $ace, "$desc (scalar) unpack_ace");
        check_ace($unpacked_ace2, $ace, "$desc (list) unpack_ace");
        is($len2, $len, "$desc (list) unpack_ace length");
    }
    else {
        ok(!defined($unpacked_ace1),
            "$desc (scalar) unpack_ace undefined (invalid ace)");
        ok(!defined($unpacked_ace2),
            "$desc (list) unpack_ace undefined (invalid ace)");
    }
}

# unpack_acl tests
my @acl_tests = (
    [
        "ACL1", # 0 aces
        "\x02\x00\x08\x00\x00\x00\x00\x00",
        [
        ],
        8,
    ],
    [
        "ACL2", # 1 ace
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        [
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-18",
            },
        ],
        28,
    ],
    [
        "ACL3", # 4 aces
        "\x02\x00\x6c\x00\x04\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace2
        "\x00\x00\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace3
        "\x00\x00\x18\x00\x3f\x00\x0f\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace4
        "\x00\x00\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        [
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-21-1000000-2000000-3000000-500",
            },
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-18",
            },
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-32-544",
            },
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-12",
            },
        ],
        108,
    ],
    [
        "ACL4",
        "",
        undef,
    ],
    [
        "ACL5", # too short
        "\x02\x00\x2c\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00",
        undef,
    ],
    [
        "ACL6", # extra data
        "\x02\x00\x2c\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00\xee\xee\xee\xee",
        [
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-21-1000000-2000000-3000000-500",
            },
        ],
        44,
    ],
    [
        "ACL7", # invalid acl length too short
        "\x02\x00\x28\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00",
        undef,
    ],
    [
        "ACL8", # acl contains unused space
        "\x02\x00\x30\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00\xee\xee\xee\xee",
        [
            {
                type => 0,
                type_as_string => 'ACCESS_ALLOWED',
                flags => 0x00,
                mask => 0x000f003f,
                trustee => "S-1-5-21-1000000-2000000-3000000-500",
            },
        ],
        48,
    ],
    [
        "ACL9", # invalid acl length too long
        "\x02\x00\xff\x00\x01\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00",
        undef,
    ],
    [
        "ACL10", # invalid (ace1 undefined)
        "\x02\x00\x2c\x00\x01\x00\x00\x00".
        # ace1 (invalid type)
        "\x03\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00",
        undef,
    ],
    [
        "ACL11", # invalid (ace2 undefined)
        "\x02\x00\x6c\x00\x04\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace2 (invalid length too long)
        "\x00\x00\x18\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace3
        "\x00\x00\x18\x00\x3f\x00\x0f\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace4
        "\x00\x00\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        undef,
    ],
);

sub check_acl {
    my ($actual_acl, $expected_acl, $desc) = @_;

    ok(defined($actual_acl), "$desc defined") or return;
    my @actual_aces = $actual_acl->get_list_of_aces;
    my @expected_aces = @$expected_acl;
    is(@actual_aces, @expected_aces, "$desc ace count");
    foreach (my $num = 0; $num < @actual_aces; $num++) {
        check_ace($actual_aces[$num], $expected_aces[$num], "$desc ace[$num]");
    }
}

foreach my $acl_test (@acl_tests) {
    my ($desc, $data, $acl, $len) = @$acl_test;
    my $unpacked_acl1 = unpack_acl($data);
    my ($unpacked_acl2, $len2) = unpack_acl($data);
    if (defined($acl)) {
        check_acl($unpacked_acl1, $acl, "$desc (scalar) unpack_acl");
        check_acl($unpacked_acl2, $acl, "$desc (list) unpack_acl");
        is($len2, $len, "$desc (list) unpack_acl length");
    }
    else {
        ok(!defined($unpacked_acl1),
            "$desc (scalar) unpack_acl undefined (invalid acl)");
        ok(!defined($unpacked_acl2),
            "$desc (list) unpack_acl undefined (invalid acl)");
    }
}

# unpack_sd tests
my @sd_tests = (
    [
        "SD1",
        "\x01\x00\x04\x80".
        "\xe4\x00\x00\x00\xf4\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00".
        # dacl
        "\x02\x00\xd0\x00\x08\x00\x00\x00".
        # ace1
        "\x00\x00\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace2
        "\x00\x00\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace3
        "\x00\x00\x18\x00\x3f\x00\x0f\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace4
        "\x00\x00\x14\x00\x19\x00\x02\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # ace5
        "\x00\x0b\x24\x00\x00\x00\x00\x10".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace6
        "\x00\x0b\x14\x00\x00\x00\x00\x10".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace7
        "\x00\x0b\x18\x00\x00\x00\x00\x10".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace8
        "\x00\x0b\x14\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner sid
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group sid
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        {
            owner => "S-1-5-32-544",
            group => "S-1-5-18",
            sacl => undef,
            dacl => [
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x00,
                    mask => 0x000f003f,
                    trustee => "S-1-5-21-1000000-2000000-3000000-500",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x00,
                    mask => 0x000f003f,
                    trustee => "S-1-5-18",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x00,
                    mask => 0x000f003f,
                    trustee => "S-1-5-32-544",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x00,
                    mask => 0x00020019,
                    trustee => "S-1-5-12",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x0b,
                    mask => 0x10000000,
                    trustee => "S-1-5-21-1000000-2000000-3000000-500",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x0b,
                    mask => 0x10000000,
                    trustee => "S-1-5-18",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x0b,
                    mask => 0x10000000,
                    trustee => "S-1-5-32-544",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x0b,
                    mask => 0x80000000,
                    trustee => "S-1-5-12",
                },
            ],
        },
        256,
    ],
    [
        "SD2",
        "\x01\x00\x14\x8c".
        "\x4c\x01\x00\x00\x68\x01\x00\x00\x14\x00\x00\x00\x58\x00\x00\x00".
        # sacl
        "\x02\x00\x44\x00\x02\x00\x00\x00".
        # ace1
        "\x02\x52\x18\x00\x26\x00\x0d\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace2
        "\x02\x52\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xeb\x03\x00\x00".
        # dacl
        "\x02\x00\xf4\x00\x09\x00\x00\x00".
        # ace1
        "\x01\x12\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xeb\x03\x00\x00".
        # ace2
        "\x00\x10\x24\x00\x3f\x00\x0f\x00".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace3
        "\x00\x1b\x24\x00\x00\x00\x00\x10".
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # ace4
        "\x00\x10\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace5
        "\x00\x1b\x14\x00\x00\x00\x00\x10".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        # ace6
        "\x00\x10\x18\x00\x3f\x00\x0f\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace7
        "\x00\x1b\x18\x00\x00\x00\x00\x10".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # ace8
        "\x00\x10\x14\x00\x19\x00\x02\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # ace9
        "\x00\x1b\x14\x00\x00\x00\x00\x80".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\xf4\x01\x00\x00".
        # group
        "\x01\x05\x00\x00\x00\x00\x00\x05\x15\x00\x00\x00\x40\x42\x0f\x00".
        "\x80\x84\x1e\x00\xc0\xc6\x2d\x00\x01\x02\x00\x00",
        {
            owner => "S-1-5-21-1000000-2000000-3000000-500",
            group => "S-1-5-21-1000000-2000000-3000000-513",
            sacl => [
                {
                    type => 2,
                    type_as_string => 'SYSTEM_AUDIT',
                    flags => 0x52,
                    mask => 0x000d0026,
                    trustee => "S-1-5-32-544",
                },
                {
                    type => 2,
                    type_as_string => 'SYSTEM_AUDIT',
                    flags => 0x52,
                    mask => 0x000f003f,
                    trustee => "S-1-5-21-1000000-2000000-3000000-1003",
                },
            ],
            dacl => [
                {
                    type => 1,
                    type_as_string => 'ACCESS_DENIED',
                    flags => 0x12,
                    mask => 0x000f003f,
                    trustee => "S-1-5-21-1000000-2000000-3000000-1003",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x10,
                    mask => 0x000f003f,
                    trustee => "S-1-5-21-1000000-2000000-3000000-500",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x1b,
                    mask => 0x10000000,
                    trustee => "S-1-5-21-1000000-2000000-3000000-500",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x10,
                    mask => 0x000f003f,
                    trustee => "S-1-5-18",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x1b,
                    mask => 0x10000000,
                    trustee => "S-1-5-18",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x10,
                    mask => 0x000f003f,
                    trustee => "S-1-5-32-544",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x1b,
                    mask => 0x10000000,
                    trustee => "S-1-5-32-544",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x10,
                    mask => 0x00020019,
                    trustee => "S-1-5-12",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x1b,
                    mask => 0x80000000,
                    trustee => "S-1-5-12",
                },
            ],
        },
        388,
    ],
    [
        "SD3",
        "\x01\x00\x00\x80".
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
        {
            owner => undef,
            group => undef,
            sacl => undef,
            dacl => undef,
        },
        20,
    ],
    [
        "SD4",
        "\x01\x00\x00\x80".
        "\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00",
        {
            owner => "S-1-5-32-544",
            group => undef,
            sacl => undef,
            dacl => undef,
        },
        36,
    ],
    [
        "SD5",
        "\x01\x00\x00\x80".
        "\x00\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        {
            owner => undef,
            group => "S-1-5-18",
            sacl => undef,
            dacl => undef,
        },
        32,
    ],
    [
        "SD6",
        "\x01\x00\x08\x80".
        "\x00\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00".
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        {
            owner => undef,
            group => undef,
            sacl => [
                {
                    type => 2,
                    type_as_string => 'SYSTEM_AUDIT',
                    flags => 0x52,
                    mask => 0x000f003f,
                    trustee => 'S-1-5-12',
                },
            ],
            dacl => undef,
        },
        48,
    ],
    [
        "SD7",
        "\x01\x00\x04\x80".
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00".
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00",
        {
            owner => undef,
            group => undef,
            sacl => undef,
            dacl => [
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x12,
                    mask => 0x000f003f,
                    trustee => 'S-1-5-12',
                },
            ],
        },
        48,
    ],
    [
        "SD8",
        "",
        undef,
    ],
    [
        "SD9",
        "\x01\x00\x04\x80".
        "\x74\x00\x00\x00\x84\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00".
        # dacl (contains unused space)
        "\x02\x00\x60\x00\x03\x00\x00\x00".
        "\x00\x02\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00".
        "\x00\x02\x14\x00\x19\x00\x02\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00".
        "\x00\x02\x18\x00\x3f\x00\x0f\x00".
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        "\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee\xee".
        "\xee\xee\xee\xee\xee\xee\xee\xee".
        # owner
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        {
            owner => "S-1-5-32-544",
            group => "S-1-5-18",
            dacl => [
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 2,
                    mask => 983103,
                    trustee => "S-1-5-18",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 2,
                    mask => 131097,
                    trustee => "S-1-1-0",
                },
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 2,
                    mask => 983103,
                    trustee => "S-1-5-32-544",
                },
            ],
            sacl => undef,
        },
        144,
    ],
    [
        "SD10",
        "\x01\x00\x0c\x80".
        "\x4c\x00\x00\x00\x5c\x00\x00\x00\x14\x00\x00\x00\x30\x00\x00\x00".
        # sacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # dacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        {
            owner => "S-1-5-32-544",
            group => "S-1-5-18",
            sacl => [
                {
                    type => 2,
                    type_as_string => 'SYSTEM_AUDIT',
                    flags => 0x52,
                    mask => 0x000f003f,
                    trustee => 'S-1-5-12',
                },
            ],
            dacl => [
                {
                    type => 0,
                    type_as_string => 'ACCESS_ALLOWED',
                    flags => 0x12,
                    mask => 0x000f003f,
                    trustee => 'S-1-5-12',
                },
            ],
        },
        104,
    ],
    [
        "SD11",
        "\x01\x00\x0c\x80".
        "\x4c\x00\x00\x00\x5c\x00\x00\x00\x14\x00\x00\x00\x30\x00\x00\x00".
        # sacl (invalid)
        "\x02\x00\x1c\x00\x02\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # dacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        undef,
    ],
    [
        "SD12",
        "\x01\x00\x0c\x80".
        "\x4c\x00\x00\x00\x5c\x00\x00\x00\x14\x00\x00\x00\x30\x00\x00\x00".
        # sacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # dacl (invalid)
        "\x02\x00\x1c\x00\x02\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        undef,
    ],
    [
        "SD13",
        "\x01\x00\x0c\x80".
        "\x4c\x00\x00\x00\x5c\x00\x00\x00\x14\x00\x00\x00\x30\x00\x00\x00".
        # sacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # dacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner (invalid)
        "\x01\xff\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group
        "\x01\x01\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        undef,
    ],
    [
        "SD14",
        "\x01\x00\x0c\x80".
        "\x4c\x00\x00\x00\x5c\x00\x00\x00\x14\x00\x00\x00\x30\x00\x00\x00".
        # sacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x02\x52\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # dacl
        "\x02\x00\x1c\x00\x01\x00\x00\x00".
        "\x00\x12\x14\x00\x3f\x00\x0f\x00".
        "\x01\x01\x00\x00\x00\x00\x00\x05\x0c\x00\x00\x00".
        # owner
        "\x01\x02\x00\x00\x00\x00\x00\x05\x20\x00\x00\x00\x20\x02\x00\x00".
        # group (invalid)
        "\x01\x02\x00\x00\x00\x00\x00\x05\x12\x00\x00\x00",
        undef,
    ],
);

sub check_sd {
    my ($actual_sd, $expected_sd, $desc) = @_;

    ok(defined($actual_sd), "$desc defined") or return;
    if (defined($expected_sd->{owner})) {
        check_sid($actual_sd->get_owner, $expected_sd->{owner},
            "$desc get_owner");
    }
    else {
        ok(!defined($actual_sd->get_owner),
            "$desc get_owner undefined (no owner)");
    }
    if (defined($expected_sd->{group})) {
        check_sid($actual_sd->get_group, $expected_sd->{group},
            "$desc get_group");
    }
    else {
        ok(!defined($actual_sd->get_group),
            "$desc get_owner undefined (no group)");
    }
    if (defined($expected_sd->{sacl})) {
        check_acl($actual_sd->get_sacl, $expected_sd->{sacl},
            "$desc get_sacl");
    }
    else {
        ok(!defined($actual_sd->get_sacl),
            "$desc get_sacl undefined (no sacl)");
    }
    if (defined($expected_sd->{dacl})) {
        check_acl($actual_sd->get_dacl, $expected_sd->{dacl},
            "$desc get_dacl");
    }
    else {
        ok(!defined($actual_sd->get_dacl),
            "$desc get_dacl undefined (no dacl)");
    }
}

foreach my $sd_test (@sd_tests) {
    my ($desc, $data, $sd, $len) = @$sd_test;
    my $unpacked_sd1 = unpack_security_descriptor($data);
    my ($unpacked_sd2, $len2) = unpack_security_descriptor($data);
    if (defined($sd)) {
        check_sd($unpacked_sd1, $sd,
            "$desc (scalar) unpack_security_descriptor");
        check_sd($unpacked_sd2, $sd,
            "$desc (list) unpack_security_descriptor");
        is($len2, $len, "$desc (list) unpack_security_descriptor length");
    }
    else {
        ok(!defined($unpacked_sd1),
            "$desc (scalar) unpack_security_descriptor undefined (invalid sd)");
        ok(!defined($unpacked_sd2),
            "$desc (list) unpack_security_descriptor undefined (invalid sd)");
    }
}

{
    my $filename = find_file('winnt_security_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::WinNT::File');

    my $root_key = $registry->get_root_key;
    ok(defined($registry), 'root key defined');
    isa_ok($root_key, 'Parse::Win32Registry::WinNT::Key');

    my @tests = (
        {
            offset => 0x1080,
            offset_to_previous => 0x1080,
            offset_to_next => 0x10b0,
            security_descriptor => {
                owner => undef,
                group => undef,
                sacl => undef,
                dacl => undef,
            },
        },
        {
            offset => 0x10b0,
            offset_to_previous => 0x10b0,
            offset_to_next => 0x10f0,
            security_descriptor => {
                owner => 'S-1-5-32-544',
                group => undef,
                sacl => undef,
                dacl => undef,
            },
        },
        {
            offset => 0x10f0,
            offset_to_previous => 0x10f0,
            offset_to_next => 0x1128,
            security_descriptor => {
                owner => undef,
                group => 'S-1-5-18',
                sacl => undef,
                dacl => undef,
            },
        },
        {
            offset => 0x1128,
            offset_to_previous => 0x1128,
            offset_to_next => 0x1170,
            security_descriptor => {
                owner => undef,
                group => undef,
                sacl => [
                    {
                        type => 2,
                        type_as_string => 'SYSTEM_AUDIT',
                        flags => 0x52,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-12',
                    },
                ],
                dacl => undef,
            },
        },
        {
            offset => 0x1170,
            offset_to_previous => 0x1170,
            offset_to_next => 0x11b8,
            security_descriptor => {
                owner => undef,
                group => undef,
                sacl => undef,
                dacl => [
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x12,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-12',
                    },
                ],
            },
        },
        {
            offset => 0x11b8,
            offset_to_previous => 0x11b8,
            offset_to_next => 0x12d0,
            security_descriptor => {
                owner => 'S-1-5-32-544',
                group => 'S-1-5-18',
                sacl => undef,
                dacl => [
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x00,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-500',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x00,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-18',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x00,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-32-544',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x00,
                        mask => 0x00020019,
                        trustee => 'S-1-5-12',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x0b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-500',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x0b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-18',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x0b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-32-544',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x0b,
                        mask => 0x80000000,
                        trustee => 'S-1-5-12',
                    },
                ],
            },
        },
        {
            offset => 0x12d0,
            offset_to_previous => 0x12d0,
            offset_to_next => 0x1080,
            security_descriptor => {
                owner => 'S-1-5-21-1000000-2000000-3000000-500',
                group => 'S-1-5-21-1000000-2000000-3000000-513',
                sacl => [
                    {
                        type => 2,
                        type_as_string => 'SYSTEM_AUDIT',
                        flags => 0x52,
                        mask => 0x000d0026,
                        trustee => 'S-1-5-32-544',
                    },
                    {
                        type => 2,
                        type_as_string => 'SYSTEM_AUDIT',
                        flags => 0x52,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-1000',
                    },
                ],
                dacl => [
                    {
                        type => 1,
                        type_as_string => 'ACCESS_DENIED',
                        flags => 0x12,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-1001',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x10,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-500',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x1b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-21-1000000-2000000-3000000-500',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x10,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-18',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x1b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-18',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x10,
                        mask => 0x000f003f,
                        trustee => 'S-1-5-32-544',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x1b,
                        mask => 0x10000000,
                        trustee => 'S-1-5-32-544',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x10,
                        mask => 0x00020019,
                        trustee => 'S-1-5-12',
                    },
                    {
                        type => 0,
                        type_as_string => 'ACCESS_ALLOWED',
                        flags => 0x1b,
                        mask => 0x80000000,
                        trustee => 'S-1-5-12',
                    },
                ],
            },
        },
    );

    my $security = $root_key->get_security;

    foreach my $test (@tests) {
        my $offset = $test->{offset};
        my $offset_to_previous = $test->{offset_to_previous};
        my $offset_to_next = $test->{offset_to_next};
        my $sd = $test->{security_descriptor};

        my $desc = sprintf "security at 0x%x", $offset;

        ok(defined($security), "$desc defined (valid security)");
        is($security->get_offset, $offset, "$desc get_offset");
        check_sd($security->get_security_descriptor, $sd,
            "$desc get_security_descriptor");

        $security = $security->get_next;
    }
}
