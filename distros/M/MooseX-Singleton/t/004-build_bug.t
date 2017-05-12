use strict;
use warnings;

use Test::More 0.88;

{
    package MySingleton;
    use MooseX::Singleton;

    has 'attrib' =>
        is      => 'rw',
        isa     => 'Str',
        default => 'foo';

    sub hello {'world'}

    sub BUILDARGS {
        my ( $class, %opts ) = @_;

        { attrib => 'bar', %opts };
    }
}

is(
    MySingleton->attrib, 'bar',
    'BUILDARGS changed value of attrib when instance was auto-instantiated'
);

MySingleton->meta->remove_package_glob('singleton');

MySingleton->instance;

is(
    MySingleton->attrib, 'bar',
    'BUILDARGS changed value of attrib when instance was explicitly instantiated'
);

done_testing;
