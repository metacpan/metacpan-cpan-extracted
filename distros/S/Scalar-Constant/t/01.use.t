use Test::More tests => 5;
use strict;
use warnings;

use Scalar::Constant
    PI => 3.1415926535,
    C  => 299_792_458,
    HI => 'hello "',
    HIJACK => "hello jack o' neill",
    ;

is($PI, 3.1415926535, 'pi was set');
is($C,  299_792_458,  'c was set');
is($HI, 'hello "',  'hi was set');
is($HIJACK, "hello jack o' neill",  'hijack was set');

eval {
    $PI = 0;
};
like($@, qr"Modification of a read-only value attempted at", "pi can't be set again");
