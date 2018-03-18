package Testify;
use v5.24;

use Object::Trampoline;
use Test::More;

use Scalar::Util    qw( blessed );

my $expect = 'Foo::Bar';

for my $name ( keys %{ $::{ 'UNIVERSAL::' } } )
{
    state $sanity   = $Object::Trampoline::Bounce::is_override;

    $sanity->( $name )
    or do
    {
        note "Skipping non-method: '$name'.";
        next;
        
    };

    note "Checking method: '$name'";

    my $t1  = Object::Trampoline->bim( $expect => qw( a b ) );

    can_ok $t1, $name;

    note "Prior state:\n", explain $t1;

    eval
    {
        # no telling what the method takes
        # as arguments, all we care about 
        # is that $t1 is replaced with a 
        # new object after calling it.

        $t1->$name;
    };

    note "After state:\n", explain $t1;

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
