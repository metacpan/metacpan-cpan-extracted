use strict;
use warnings;

use Test::More 'no_plan';
use Parse::Win32Registry 0.60 qw(:functions);

Parse::Win32Registry::enable_warnings;

my @tests = (
    ### WIN32REGISTRY ERROR MESSAGES
    {
        class => 'Parse::Win32Registry',
        fatal_error => 'No filename specified',
    },
    {
        filename => 'invalid_creg_header.rf',
        class => 'Parse::Win32Registry',
        warning => 'Invalid registry file header',
    },
    {
        filename => 'invalid_regf_header.rf',
        class => 'Parse::Win32Registry',
        warning => 'Invalid registry file header',
    },
    ### SUPPORT FUNCTION ERROR MESSAGES
    {
        method => 'make_multiple_subkey_iterator()',
        fatal_error => 'Usage: make_multiple_subkey_iterator',
    },
    {
        method => 'make_multiple_subtree_iterator()',
        fatal_error => 'Usage: make_multiple_subtree_iterator',
    },
    {
        method => 'make_multiple_value_iterator()',
        fatal_error => 'Usage: make_multiple_value_iterator',
    },
    {
        method => 'compare_multiple_keys()',
        fatal_error => 'Usage: compare_multiple_keys',
    },
    {
        method => 'compare_multiple_values()',
        fatal_error => 'Usage: compare_multiple_values',
    },
    ### WIN95::FILE ERROR MESSAGES
    {
        class => 'Parse::Win32Registry::Win95::File',
        fatal_error => 'No filename specified',
    },
    {
        filename => 'nonexistent_file',
        class => 'Parse::Win32Registry::Win95::File',
        fatal_error => 'Unable to open',
    },
    {
        filename => 'empty_file.rf',
        class => 'Parse::Win32Registry::Win95::File',
        warning => 'Could not read registry file header',
    },
    {
        filename => 'invalid_creg_header.rf',
        class => 'Parse::Win32Registry::Win95::File',
        warning => 'Invalid registry file signature',
    },
    {
        filename => 'missing_rgkn_header.rf',
        class => 'Parse::Win32Registry::Win95::File',
        warning => 'Could not read RGKN header at 0x',
    },
    {
        filename => 'invalid_rgkn_header.rf',
        class => 'Parse::Win32Registry::Win95::File',
        warning => 'Invalid RGKN block signature at 0x',
    },
    ### WIN95::KEY ERROR MESSAGES
    {
        filename => 'win95_error_tests.rf',
        class => 'Parse::Win32Registry::Win95::Key',
        offset => 0xeeeeeeee,
        warning => 'Could not read RGKN key at 0x',
    },
    {
        filename => 'win95_error_tests.rf',
        class => 'Parse::Win32Registry::Win95::Key',
        offset => 0x5c,
        warning => 'Could not find RGDB entry for RGKN key at 0x',
        further_tests => [
            ['defined($object)'],
            ['$object->get_name', ''],
            ['$object->get_path', ''],
            ['$object->get_list_of_values', '==', 0],
        ],
    },
    ### WIN95::VALUE ERROR MESSAGES
    {
        filename => 'win95_error_tests.rf',
        class => 'Parse::Win32Registry::Win95::Value',
        offset => 0x1fe,
        warning => 'Could not read RGDB value at 0x',
    },
    {
        filename => 'win95_error_tests.rf',
        class => 'Parse::Win32Registry::Win95::Value',
        offset => 0x1aa,
        warning => 'Could not read name for RGDB value at 0x',
    },
    {
        filename => 'win95_error_tests.rf',
        class => 'Parse::Win32Registry::Win95::Value',
        offset => 0x156,
        warning => 'Could not read data for RGDB value at 0x',
    },
    ### WINNT::FILE ERROR MESSAGES
    {
        class => 'Parse::Win32Registry::WinNT::File',
        fatal_error => 'No filename specified',
    },
    {
        filename => 'nonexistent_file',
        class => 'Parse::Win32Registry::WinNT::File',
        fatal_error => 'Unable to open',
    },
    {
        filename => 'empty_file.rf',
        class => 'Parse::Win32Registry::WinNT::File',
        warning => 'Could not read registry file header',
    },
    {
        filename => 'invalid_regf_header.rf',
        class => 'Parse::Win32Registry::WinNT::File',
        warning => 'Invalid registry file signature',
    },
    {
        filename => 'invalid_regf_checksum.rf',
        class => 'Parse::Win32Registry::WinNT::File',
        warning => 'Invalid checksum for registry file header',
        further_tests => [
            ['defined($object)'],
            ['$object->get_embedded_filename', 'ttings\\Administrator\\ntuser.dat'],
        ],
    },
    ### WINNT::KEY ERROR MESSAGES
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0xeeeeeeee,
        warning => 'Could not read key at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1080,
        warning => 'Invalid signature for key at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x10d8,
        warning => 'Could not read name for key at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1130,
        warning => 'Could not read class name at 0x',
        further_tests => [
            ['defined($object)'],
            ['$object->get_name', 'key4'],
            ['!defined($object->get_class_name)'],
        ],
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1198,
        method => '@result = $object->get_list_of_subkeys',
        warning => 'Could not read subkey list header at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x11f0,
        method => '@result = $object->get_list_of_subkeys',
        warning => 'Invalid signature for subkey list at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1248,
        method => '@result = $object->get_list_of_subkeys',
        warning => 'Could not read subkey list at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x12a0,
        method => '@result = $object->get_list_of_values',
        warning => 'Could not read value list at 0x',
    },
    ### USAGE ERRORS
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1020,
        method => '$result = $object->get_subkey(undef)',
        fatal_error => q{Usage: get_subkey\('key name'\)},
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Key',
        offset => 0x1020,
        method => '$result = $object->get_value(undef)',
        fatal_error => q{Usage: get_value\('value name'\)},
    },
    ### WINNT::SECURITY ERROR MESSAGES
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Security',
        offset => 0xeeeeeeee,
        warning => 'Could not read security at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Security',
        offset => 0x1828,
        warning => 'Invalid signature for security at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Security',
        offset => 0x1890,
        warning => 'Could not read security descriptor for security at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Security',
        offset => 0x18f8,
        warning => 'Invalid security descriptor for security at 0x',
    },
    ### WINNT::VALUE ERROR MESSAGES
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Value',
        offset => 0xeeeeeeee,
        warning => 'Could not read value at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Value',
        offset => 0x1960,
        warning => 'Invalid signature for value at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Value',
        offset => 0x1980,
        warning => 'Could not read name for value at 0x',
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Value',
        offset => 0x19a0,
        warning => 'Invalid inline data length for value \'.*\' at 0x',
        further_tests => [
            ['defined($object)'],
            ['$object->get_name', 'value4'],
            ['!defined($object->get_data)'],
        ],
    },
    {
        filename => 'winnt_error_tests.rf',
        class => 'Parse::Win32Registry::WinNT::Value',
        offset => 0x19c0,
        warning => 'Invalid offset to data for value \'.*\' at 0x',
        further_tests => [
            ['defined($object)'],
            ['$object->get_name', 'value5'],
            ['!defined($object->get_data)'],
        ],
    },
);

foreach my $test (@tests) {
    my $filename = $test->{filename};
    my $class = $test->{class};
    my $offset = $test->{offset};
    my $method_test = $test->{method};
    my $fatal_error = $test->{fatal_error};
    my $warning = $test->{warning};
    my $list_of_warnings = $test->{list_of_warnings};
    my $further_tests = $test->{further_tests};

    if (defined $filename) {
        $filename = -d 't' ? 't/'.$filename : $filename;
        die "Missing test data file '$filename'"
            if !-f $filename && $filename !~ m/nonexistent/;
    }

    # declare variables used in tests
    my $regfile;
    my $object;
    my $result;
    my @result;

    my $setup = "";
    my $setup_desc = "";
    if (defined $class) {
        if (defined $filename) {
            if (defined $offset) {
                $regfile = Parse::Win32Registry->new($filename);

                $setup = "\$object = $class->new(\$regfile, \$offset)";
                $setup_desc = sprintf("\$object = $class->new(<$filename>, 0x%x)", $offset);
            }
            else {
                $setup = "\$object = $class->new(\$filename)";
                $setup_desc = "\$object = $class->new(<$filename>)";
            }
        }
        else {
            $setup = "\$object = $class->new";
            $setup_desc = $setup;
        }
    }

    # If a method test is not specified,
    # then the setup becomes the test
    my $eval;
    my $eval_desc;
    if (defined $method_test) {
        if ($setup) {
            # eval $setup
            # ok defined $object or diag $@
            ok(eval $setup, "$setup_desc should succeed")
                or diag $@;
        }
        $eval = $method_test;
        $eval_desc = $method_test;
    }
    else {
        $eval = $setup;
        $eval_desc = $setup_desc;
    }

    my @caught_warnings = ();
    local $SIG{__WARN__} = sub { push @caught_warnings, shift; };

    if ($further_tests) {
        ok(eval $eval, "$eval_desc should succeed");
    }
    else {
        ok(!eval $eval, "$eval_desc should fail");
    }

    if ($fatal_error) {
        like($@, qr/$fatal_error/, qq{...with fatal error "$fatal_error..."});
    }
    elsif ($warning) {
        my $num_caught = @caught_warnings;
        cmp_ok($num_caught, '==', 1, "...with only one warning");
        my $caught_warning = $caught_warnings[0];
        $caught_warning = '' if !defined $caught_warning;
        like($caught_warning, qr/$warning/, qq{...warning "$warning"});
    }

    if (defined $further_tests) {
        die if ref $further_tests ne 'ARRAY';
        foreach my $further_test (@$further_tests) {
            my @params = @$further_test;
            if (@params == 1) {
                my $test_desc = "...and $params[0]";
                ok(eval $params[0], $test_desc);
            }
            elsif (@params == 2) {
                my $test_desc = "...and $params[0] eq '$params[1]'";
                is(eval $params[0], $params[1], $test_desc);
            }
            elsif (@params == 3) {
                my $test_desc = $params[1] eq '=='
                  ? "...and $params[0] $params[1] $params[2]"
                  : "...and $params[0] $params[1] '$params[2]'";
                cmp_ok(eval $params[0], $params[1], $params[2],
                    $test_desc);
            }
        }
    }
}
