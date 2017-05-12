use Moonshine::Test qw/:all/;

use Moonshine::Util;

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15 ],
    args_list => 1,
    expected  => 'this is your ..',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15, {truncate=>"left"}],
    args_list => 1,
    expected  => '..is your brain',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15, {truncate=>"right"}],
    args_list => 1,
    expected  => 'this is your ..',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15, {truncate=>"middle"}],
    args_list => 1,
    expected  => 'this i..r brain',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15, {truncate=>"ends"}],
    args_list => 1,
    expected  => '..s is your b..',
    test      => 'scalar',
);

moon_test_one(
    meth      => \&Moonshine::Util::elide,
    args      => [ 'this is your brain', 15, {truncate=>"middle", marker=>'....'}],
    args_list => 1,
    expected  => 'this .... brain',
    test      => 'scalar',
);

sunrise(6, '*\o/*');

1;
