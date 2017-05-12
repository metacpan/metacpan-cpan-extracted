#!perl -T

use strict;
use warnings;
use overload
    q{+}  => sub { 0 }, 
    q{""} => sub { 'A' };

use Test::More tests => 4;
use Test::NoWarnings;

BEGIN {
    use_ok(
        'Scalar::In',
        string_in  => { -as => 'in' },
        numeric_in => { -as => 'num_in' },
    );
}

my $object = bless {}, __PACKAGE__;

note 'in';
ok
    in( $object, 'A' ),
    'eq';

note 'num_in';
ok
    num_in( $object, 0 ),
    '==';
