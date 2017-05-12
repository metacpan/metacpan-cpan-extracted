use strict;
use warnings;

use Test::More 0.88;

use Test::Requires {
    'Test::CleanNamespaces' => 0,
};

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'Impl1', 'Impl2' ],
        symbols         => ['return_42'],
    );
    $loader->();
}

$INC{'T.pm'} = 1;

{
    local $TODO = q{Without Sub::Name there's no good way to avoid dirtiness};
    namespaces_clean('T');
}

done_testing();
