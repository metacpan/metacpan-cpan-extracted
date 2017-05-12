use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package My::Stash::Manip;
    use strict;
    use warnings;

    use base 'Stash::Manip';

    use Symbol 'gensym';

    sub namespace {
        $_[0]->{namespace} ||= {}
    }

    sub add_package_symbol {
        my ($self, $variable, $initial_value) = @_;

        my ($name, $sigil, $type) = $self->_deconstruct_variable_name($variable);

        my $glob = gensym();
        *{$glob} = $initial_value if defined $initial_value;
        $self->namespace->{$name} = *{$glob};
    }
}

# No actually package Foo exists :)
my $foo_stash = My::Stash::Manip->new('Foo');

isa_ok($foo_stash, 'My::Stash::Manip');
isa_ok($foo_stash, 'Stash::Manip');

ok(!defined($Foo::{foo}), '... the %foo slot has not been created yet');
ok(!$foo_stash->has_package_symbol('%foo'), '... the foo_stash agrees');

lives_ok {
    $foo_stash->add_package_symbol('%foo' => { one => 1 });
} '... the %foo symbol is created succcessfully';

ok(!defined($Foo::{foo}), '... the %foo slot has not been created in the actual Foo package');
ok($foo_stash->has_package_symbol('%foo'), '... the foo_stash agrees');

my $foo = $foo_stash->get_package_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

$foo->{two} = 2;

is($foo, $foo_stash->get_package_symbol('%foo'), '... our %foo is the same as the foo_stashs');

ok(!defined($Foo::{bar}), '... the @bar slot has not been created yet');

lives_ok {
    $foo_stash->add_package_symbol('@bar' => [ 1, 2, 3 ]);
} '... created @Foo::bar successfully';

ok(!defined($Foo::{bar}), '... the @bar slot has still not been created');

ok(!defined($Foo::{baz}), '... the %baz slot has not been created yet');

lives_ok {
    $foo_stash->add_package_symbol('%baz');
} '... created %Foo::baz successfully';

ok(!defined($Foo::{baz}), '... the %baz slot has still not been created');

done_testing;
