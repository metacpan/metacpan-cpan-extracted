use strict;
use warnings;

use Test::More tests => 5;

{

    package Foo;
    use Moose;
    with 'MooseX::Clone';

    has 'arr_ref' => (
        isa     => 'ArrayRef',
        is      => 'ro',
        default => sub { [qw/foo bar baz/] },
        traits  => [qw/Clone/]
    );

    package Bar;
    use Moose;
    with 'MooseX::Clone';

    has 'arr_ref' => (
        isa        => 'ArrayRef',
        is         => 'ro',
        auto_deref => 1,
        default    => sub { [qw/foo bar baz/] },
        traits     => [qw/Clone/]
    );

    package Baz;
    use Moose;
    with 'MooseX::Clone';

    has 'arr_ref' => (
        isa        => 'ArrayRef',
        is         => 'ro',
        auto_deref => 1,
        default    => sub { [qw/foo bar/] },
        traits     => [qw/Clone/]
    );
}

eval { Foo->new->clone };
ok( !$@, 'cloning simple obj with a ArrayRef' );

my $clone = eval { Bar->new->clone };
ok( !$@, 'cloning simple obj with a ArrayRef (3 elements) and auto_deref' );
ok( $clone, "got a clone" );
is_deeply( eval { [ $clone->arr_ref ] }, [qw(foo bar baz)], "value cloned properly" );

eval { Bar->new->clone };
ok( !$@, 'cloning simple obj with a ArrayRef (2 elements) and auto_deref' );
