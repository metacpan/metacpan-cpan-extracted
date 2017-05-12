use Moonshine::Test qw/:all/;

use Moonshine::Util;

moon_test_one(
    meth      => \&Moonshine::Util::join_class, 
    args      => [ 'component-', 'first' ],
    args_list => 1,
    expected  => 'component-first',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::join_class,
    args      => [ 'component-' ],
    args_list => 1,
    expected  => undef,
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::join_class,
    args      => [ ],
    args_list => 1,
    expected  => undef,
    test      => 'scalar',
);

sunrise(3, '\_o_/');

1;
