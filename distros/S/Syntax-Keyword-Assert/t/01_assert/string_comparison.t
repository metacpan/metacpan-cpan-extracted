use Test2::V0;
use Syntax::Keyword::Assert;

use lib 't/lib';
use TestUtil;

subtest 'STR_EQ' => sub {
    my $message = 'hello';

    ok lives { assert($message eq 'hello') };
    is dies { assert($message eq 'world') }, expected_assert_bin('"hello"', 'eq', '"world"');

    my $x     = 1;
    my $undef = undef;

    is dies { assert($x eq 'world') }, expected_assert_bin(1, 'eq', '"world"');

    my $warnings = warnings {
        is dies { assert($undef eq 'world') }, expected_assert_bin('undef', 'eq', '"world"');
    };

    # suppressed warnings
    is scalar @$warnings, 1;
};

subtest 'STR_NE' => sub {
    my $message = 'hello';
    ok lives { assert($message ne 'world') };
    is dies { assert($message ne 'hello') }, expected_assert_bin('"hello"', 'ne', '"hello"');
};

subtest 'STR_LT' => sub {
    my $message = 'b';
    is dies { assert($message lt 'a') }, expected_assert_bin('"b"', 'lt', '"a"');
    is dies { assert($message lt 'b') }, expected_assert_bin('"b"', 'lt', '"b"');
    ok lives { assert($message lt 'c') };

    my $unicode = "い";
    is dies { assert($unicode lt 'あ') }, expected_assert_bin('"い"', 'lt', '"あ"');
    is dies { assert($unicode lt 'い') }, expected_assert_bin('"い"', 'lt', '"い"');
    ok lives { assert($unicode lt 'う') };
};

subtest 'STR_GT' => sub {
    my $message = 'b';
    ok lives { assert($message gt 'a') };
    is dies { assert($message gt 'b') }, expected_assert_bin('"b"', 'gt', '"b"');
    is dies { assert($message gt 'c') }, expected_assert_bin('"b"', 'gt', '"c"');

    my $unicode = "い";
    ok lives { assert($unicode gt 'あ') };
    is dies { assert($unicode gt 'い') }, expected_assert_bin('"い"', 'gt', '"い"');
    is dies { assert($unicode gt 'う') }, expected_assert_bin('"い"', 'gt', '"う"');
};

subtest 'STR_LE' => sub {
    my $message = 'b';
    is dies { assert($message le 'a') }, expected_assert_bin('"b"', 'le', '"a"');
    ok lives { assert($message le 'b') };
    ok lives { assert($message le 'c') };

    my $unicode = "い";
    is dies { assert($unicode le 'あ') }, expected_assert_bin('"い"', 'le', '"あ"');
    ok lives { assert($unicode le 'い') };
    ok lives { assert($unicode le 'う') };
};

subtest 'STR_GE' => sub {
    my $message = 'b';
    ok lives { assert($message ge 'a') };
    ok lives { assert($message ge 'b') };
    is dies { assert($message ge 'c') }, expected_assert_bin('"b"', 'ge', '"c"');

    my $unicode = "い";
    ok lives { assert($unicode ge 'あ') };
    ok lives { assert($unicode ge 'い') };
    is dies { assert($unicode ge 'う') }, expected_assert_bin('"い"', 'ge', '"う"');
};

done_testing;
