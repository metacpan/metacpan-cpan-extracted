package Testify;
use v5.12;

use Object::Trampoline;
use Test::More;

use Scalar::Util    qw( blessed );

my $expect = 'Foo::Bar';

for my $name ( keys %{ $::{ 'UNIVERSAL::' } } )
{
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
