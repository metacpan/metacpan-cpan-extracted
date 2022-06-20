## no critic (Modules::ProhibitMultiplePackages)
use strict;
use warnings;

use Test::More 0.96;

use Specio::Library::Builtins;

# This test is about a bug where a parent class with a t() sub causes the t()
# sub to not be added in a child class that uses a type-exporter.
{
    package Parent;

    use Specio::Library::Builtins;

    sub type {
        t('Int');
    }
}

{
    package Child;

    use parent -norequire => 'Parent';

    use Specio::Library::Builtins;

    sub type {
        t('Str');
    }
}

is( Child::type(), t('Str'), 'Child class has a t() sub' );

done_testing();
