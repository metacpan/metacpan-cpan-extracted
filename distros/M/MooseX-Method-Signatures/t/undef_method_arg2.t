use strict;
use warnings;

# Can we distinguish between explicitly passing undef as an argument,
# vs. not passing it at all? (in a plain hash, we would use defined vs. exists
# on %args = @_.)


# assigned to by each 'foo' method
my $captured_args;

{
    package Named;

    use Moose;
    use MooseX::Method::Signatures;

    method foo (
        Str :$foo_a!,
        Maybe[Str] :$foo_b?) {
        $captured_args = \@_;
    }
}


{
    package Positional;
    use Moose;
    use MooseX::Method::Signatures;

    method foo (
        Str $foo_a!,
        Maybe[Str] $foo_b?) {
        $captured_args = \@_;
    }
}

use Test::More;
use Test::Deep;

my $positional = Positional->new;
$positional->foo('str', undef);

cmp_deeply(
    $captured_args,
    [
        noclass({}),
        'str',
        undef,
    ],
    'positional: explicit undef shows up in @_ correctly',
);

$positional->foo('str');

cmp_deeply(
    $captured_args,
    [
        noclass({}),
        'str',
    ],
    'positional: omitting an argument results in no entry in @_',
);

my $named = Named->new;
$named->foo(foo_a => 'str', foo_b => undef);

cmp_deeply(
    $captured_args,
    [
        noclass({}),
        'str',
        undef,
    ],
    'named: explicit undef shows up in @_ correctly',
);

$named->foo(foo_a => 'str');

TODO: {
    local $TODO = 'this fails... should work the same as for positional args.';
cmp_deeply(
    $captured_args,
    [
        noclass({}),
        'str',
    ],
    'named: omitting an argument results in no entry in @_',
);

}


done_testing;


