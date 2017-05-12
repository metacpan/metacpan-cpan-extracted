#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

my $inner = Object::Lazy->new( sub { TestInner->new } );
my $outer = Object::Lazy->new( sub { TestOuter->new( $inner->inner ) } );
is(
    $outer->outer,
    'inner output',
    'other AUTOLOAD during BUILD_OBJECT',
);

#-----------------------------------------------------------------------------

package TestInner;

sub new {
    return bless {}, shift;
}

sub inner {
    return 'inner output';
}

#-----------------------------------------------------------------------------

package TestOuter;

sub new {
    my ( $class, $text ) = @_;
    return bless \$text, $class;
}

sub outer {
    return ${ +shift };
}
