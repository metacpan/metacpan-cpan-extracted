use strict;
use warnings;

use Test::More 0.88;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'Impl1', 'Impl2' ],
        symbols => [qw( return_42 &return_package $SCALAR @ARRAY %HASH )],
    );

    $loader->();
}

{
    ok( T->can('return_42'),      'T package has a return_42 sub' );
    ok( T->can('return_package'), 'T package has a return_package sub' );
    is( T::return_42(), 42, 'T::return_42 work as expected' );
    is(
        T::return_package(),
        'T::Impl1',
        'T::return_package returns implementation package'
    );

    no warnings 'once';
    is( $T::SCALAR, 42, '$T::SCALAR was copied from implementation' );
    is_deeply(
        \@T::ARRAY,
        [ 1, 2, 3 ],
        '@T::ARRAY was copied from implementation'
    );
    is_deeply(
        \%T::HASH,
        { key => 'val' },
        '%T::HASH was copied from implementation'
    );
}

done_testing();
