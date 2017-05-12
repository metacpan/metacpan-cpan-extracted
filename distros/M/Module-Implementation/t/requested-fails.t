use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal 0.006;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'ImplFails1', 'Impl1' ],
        symbols         => [qw( return_42 )],
    );

    $ENV{T_IMPLEMENTATION} = 'ImplFails1';

    ::like(
        ::exception{ $loader->() },
        qr/Could not load T::ImplFails1/,
        'Got an exception when implementation requested in env value fails to load'
    );
}

done_testing();
