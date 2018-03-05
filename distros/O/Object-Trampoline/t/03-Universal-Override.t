package Testify;
use v5.24;

use Object::Trampoline;
use Test::More;

use Scalar::Util    qw( blessed );

my $expect = 'Foo::Bar';

while( my( $name, $ref ) = each %{ $::{ 'UNIVERSAL::' } } )
{
    *{ $ref }{ CODE }
    or next;

    note "Checking: '$name'";

    my $t1  = Object::Trampoline->bim( $expect => qw( a b ) );

    eval { $t1->$name( $expect ) };

    my $found   = blessed $t1;

    ok $found eq $expect,  "Object is '$found' ($expect)";
}

done_testing;

package Foo::Bar;

our $VERSION = '0.0';

sub bim
{
    my @argz    = map { "$_" } @_;

    bless \@argz, __PACKAGE__
}

sub blah    { 1 }


__END__
