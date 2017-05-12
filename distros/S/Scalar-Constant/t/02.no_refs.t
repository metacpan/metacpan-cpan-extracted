use Test::More tests => 2;
use strict;
use warnings;

eval {
    use_ok('Scalar::Constant');
    Scalar::Constant->import(AREF => [1]);
};
like($@, qr"References are not supported", "no references");

