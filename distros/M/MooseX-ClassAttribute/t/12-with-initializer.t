use strict;
use warnings;
use Test::More;

{
    package ClassFoo;

    use Moose;
    use MooseX::ClassAttribute;

    class_has 'chas' => (
        isa         => 'Int',
        is          => 'ro',
        default     => 1,
        initializer => sub { $_[2]->( $_[1] + 1 ) }
    );
}

{
    package ClassBar;
    use Moose;

    has 'chas' => (
        isa         => 'Int',
        is          => 'ro',
        default     => 1,
        initializer => sub { $_[2]->( $_[1] + 1 ) }
    );
}

{
    package ClassBaz;
    use Moose;
    use MooseX::ClassAttribute;

    class_has 'chas' => (
        isa     => 'Str',
        is      => 'rw',
        default => 'Foobar',
        trigger => sub { die __PACKAGE__ }
    );
}

{
    package ClassQuz;
    use Moose;

    has 'chas' => (
        isa     => 'Str',
        is      => 'rw',
        default => 'Foobar',
        trigger => sub { die __PACKAGE__ }
    );
}

{
    local $TODO
        = 'Class attributes with an initializer are not initialized properly';

    is(
        ClassFoo->chas, 2,
        "ClassFoo's class_has (ClassAttribute) initializer fires"
    );
}

is(
    ClassBar->new->chas, 2,
    "ClassBar's has (non-ClassAttribute) initializer fires"
);

eval { ClassBaz->new->chas('foobar') };
like(
    $@, qr/ClassBaz/,
    "ClassBaz's class_has (ClassAttribute) trigger fires"
);

eval { ClassQuz->new->chas('foobar') };
like( $@, qr/ClassQuz/, "ClassQuz's has (non-ClassAttribute) trigger fires" );

done_testing();
