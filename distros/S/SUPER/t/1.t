#!perl
use strict;
use warnings;

use Test::More;

package Daddy;

Test::More->import();

sub new { bless {}, shift }

sub foo
{
    my $self = shift;
    isa_ok( $self, "Kid" );
    is( $_[0], 123, "Arguments passed OK" );
}

package Kid;

Test::More->import();
@Kid::ISA = 'Daddy';

use SUPER;

sub foo
{
    my $self = shift;
    if ( $_[0] > 100 )
    {
        super;
    }
    else
    {
        is( $_[0], 50, "Arguments retained OK" )
    }
}

my $a = Kid->new();
$a->foo(123);
$a->foo(50);

is( $a->super( 'new' ), \&Daddy::new, 'Kid inherits new() from Daddy' );
is( $a->super( 'foo' ), \&Daddy::foo,
    '... as it does foo, even though it overrides it' );

done_testing();
