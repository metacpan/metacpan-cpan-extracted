use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../";
use Test::More;
use t::scan::Util;

test(<<'END');
use MooseX::Declare;

class UnderTest {
    method pass_through (:$param?) {
        $param;
    }

    method pass_through2 (:name($value)?) {
        $value;
    }

    method pass_through3 ($value?) {
        $value || 'default';
    }
}
END

done_testing;
