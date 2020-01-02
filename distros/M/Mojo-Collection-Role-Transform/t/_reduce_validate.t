use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::Collection 'c';

my @methods_and_args = (
    {
        method => 'hashify',
        args => [],
    },
    {
        method => 'hashify_collect',
        args => [{}],
    },
    {
        method => 'collect_by',
        args => [{}],
    },
);
for my $method_and_args (@methods_and_args) {
    my $method = $method_and_args->{method};
    my @args = @{ $method_and_args->{args} };

    throws_ok
        { c()->with_roles('+Transform')->$method(@args) }
        qr/must provide get_keys sub/,
        'no get_keys sub throws'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method(@args, undef) }
        qr/get_keys sub must be a subroutine, but was 'scalar value'/,
        'undef get_keys throws'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method(@args, {}) }
        qr/get_keys sub must be a subroutine, but was 'HASH'/,
        'hash get_keys throws'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method(@args, '') }
        qr/get_keys sub must be a subroutine, but was 'scalar value'/,
        'empty string get_keys throws'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method(@args, sub {}) }
        'sub get_keys lives'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method(@args, sub {}, undef) }
        qr/get_value must be a subroutine if provided, but was 'scalar value'/,
        'undef get_value throws'
        ;
    throws_ok
        { c()->with_roles('+Transform')->$method(@args, sub {}, {}) }
        qr/get_value must be a subroutine if provided, but was 'HASH'/,
        'hash get_value throws'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method(@args, sub {}, '') }
        qr/get_value must be a subroutine if provided, but was 'scalar value'/,
        'empty string get_value throws'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method(@args, sub {}, sub {}) }
        'sub get_value lives'
        ;
}

done_testing;
