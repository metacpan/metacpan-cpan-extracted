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
        implementations => [ 'Impl1', 'ImplFails1' ],
        symbols         => [qw( return_42 )],
    );

    $loader->();
}

{
    ok( T->can('return_42'),       'T package has a return_42 sub' );
    ok( !T->can('return_package'), 'T package has a return_package sub' );
}

done_testing();
