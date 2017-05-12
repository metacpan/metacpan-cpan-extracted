use Moonshine::Test qw/:all/;

use Moonshine::Util;

moon_test_one(
    meth      => \&Moonshine::Util::append_str,
    args      => [ 'okay', 'first' ],
    args_list => 1,
    expected  => 'okay first',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::append_str,
    args      => [ 'okay' ],
    args_list => 1,
    expected  => 'okay',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::append_str,
    args      => [ ],
    args_list => 1,
    expected  => undef,
    test      => 'scalar',
);

sunrise(3, '/_o/*');

1;
