use Moonshine::Test qw/:all/;

use Moonshine::Util;

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::left_trim_ws,
    args => [
        '     basic test     ',
    ],
    args_list => 1,
    expected => 'basic test     ',
);

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::right_trim_ws,
    args => [
        '     basic test     ',
    ],
    args_list => 1,
    expected => '     basic test',
);

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::trim_ws,
    args => [
        '     basic test     ',
    ],
    args_list => 1,
    expected => 'basic test',
);

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::trim_ws_lines,
    args => [
        '     
            basic test     
            multi lines
        ',
    ],
    args_list => 1,
    expected => '
basic test
multi lines
',
);

=head2 brokens

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::trim_blank_ws_lines,
    args => [
        '     
            basic test     
            multi lines
        ',
    ],
    args_list => 1,
    expected => '
        basic test
        multi lines
',
);

=cut

moon_test_one(
    test => 'scalar',
    meth => \&Moonshine::Util::ellipsis,
    args => [
        'basic test',
        8,
        '***',
    ],
    args_list => 1,
    expected => 'basic***',
);

sunrise(5, '\_o_');
