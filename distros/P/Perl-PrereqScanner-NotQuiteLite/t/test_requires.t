use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('with a hashref', <<'END', {'Test::Requires' => 0}, {}, {'HTTP::MobileAttribute' => '0.01'});
use Test::Requires {
    'HTTP::MobileAttribute' => 0.01, # skip all if HTTP::MobileAttribute doesn't installed
};
END

test('qw', <<'END', {'Test::More' => 0, 'Test::Requires' => 0}, {}, {'HTTP::MobileAttribute' => 0});
use Test::More tests => 10;
use Test::Requires qw( 
    HTTP::MobileAttribute
);
END

test('function', <<'END', {'Test::More' => 0, 'Test::Requires' => 0}, {}, {'Some::Optional::Test::Required::Modules' => 0});
use Test::More tests => 10;
use Test::Requires;
test_requires 'Some::Optional::Test::Required::Modules';
END

done_testing;
