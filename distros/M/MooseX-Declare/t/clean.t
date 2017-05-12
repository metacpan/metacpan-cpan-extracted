use MooseX::Declare;
use Test::More tests => 4;
use Test::Fatal;

class Foo is dirty {
    use Carp qw/croak/;
    use MooseX::Types::Moose qw/Str/;
    use MooseX::Types::Structured qw/Tuple/;

    clean;

    method fail ($class:) { croak 'korv' }
    method Tuple ($class:) { return Tuple[Str, Str] }
}

ok(!Foo->can('croak'));
ok( Foo->can('Tuple'));

is(Foo->Tuple->name, 'MooseX::Types::Structured::Tuple[Str,Str]');

like( exception {
    Foo->fail;
}, qr/\bkorv\b/);
