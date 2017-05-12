use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use TypeLibrary qw/EvenInt/;
use MooseX::Lexical::Types qw/EvenInt/;

isa_ok(EvenInt, 'Moose::Meta::TypeConstraint');

my EvenInt $foo = 2;
is($foo, 2);

lives_ok {
    $foo = 4;
};
is($foo, 4);

throws_ok {
    $foo = 3;
} qr/Validation failed/;
