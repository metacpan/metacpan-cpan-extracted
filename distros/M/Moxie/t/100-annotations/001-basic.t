#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

=pod

This just shows that we can apply our
traits and add others in if we want

=cut

{
    package Bar::Traits::Provider;
    use strict;
    use warnings;

    our $TRAIT_USED = 0;

    sub Bar { $TRAIT_USED++; return }

    package Foo;
    use Moxie
        traits => ['Bar::Traits::Provider'];

    extends 'Moxie::Object';

    has foo => sub { 'FOO' };

    sub foo : ro Bar;
}

BEGIN {
    is($Bar::Traits::Provider::TRAIT_USED, 1, '...the trait was used in BEGIN');
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');
    can_ok($foo, 'foo');

    is($foo->foo, 'FOO', '... the generated accessor worked as expected');
}

{
    my $method = MOP::Class->new( 'Foo' )->get_method('foo');
    isa_ok($method, 'MOP::Method');
    is_deeply(
        [ $method->get_code_attributes ],
        [qw[ ro Bar ]],
        '... got the expected attributes'
    );
}

done_testing;

