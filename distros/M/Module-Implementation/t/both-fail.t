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
        implementations => [ 'ImplFails1', 'ImplFails2' ],
        symbols         => [qw( return_42 )],
    );

    ::like(
        ::exception{ $loader->() },
        qr/Could not find a suitable T implementation/,
        'Got an exception when all implementations fail to load'
    );
}

done_testing();
