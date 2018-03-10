package Testify;
use v5.24;

use Object::Trampoline;
use Test::More;

use Scalar::Util    qw( blessed );

my $expect = 'Foo::Bar';

while( my( $name, $val ) = each %{ $::{ 'UNIVERSAL::' } } )
{
    state $sanity   = $Object::Trampoline::Bounce::is_override;

    if( $sanity->( $name, $val ) )
    {
        note "Checking method: '$name'";

        my $t1  = Object::Trampoline->bim( $expect => qw( a b ) );

        eval { $t1->$name( $expect ) };

        my $found   = blessed $t1;

        ok $found eq $expect,  "Object is '$found' ($expect)";
    }
    else
    {
        note "Skipping non-method: '$name'.";
    }
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
