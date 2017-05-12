use Moonshine::Test qw/:all/;

use Moonshine::Util qw/assert_valid_html5_tag/;

moon_test_one(
    meth      => \&Moonshine::Util::assert_valid_html5_tag,
    args      => [ 'span' ],
    args_list => 1,
    test      => 'true',
);

moon_test_one(
    meth      => \&Moonshine::Util::assert_valid_html5_tag,
    args      => [ 'div' ],
    args_list => 1,
    test      => 'true',
);

moon_test_one(
    meth      => \&Moonshine::Util::assert_valid_html5_tag,
    args      => [ 'moonshine' ],
    args_list => 1,
    test      => 'false',
);

sunrise(3, '*\o/*');

1;
