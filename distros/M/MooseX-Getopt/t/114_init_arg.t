use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package Test1;
    use Moose;
    with 'MooseX::Getopt';

    has _private => ( is => 'ro', isa => 'Str', init_arg => 'public' );
    has name_after => ( is => 'ro', isa => 'Str', init_arg => 'name_before' );
    has bar => ( is => 'ro', isa => 'Str', );
    has undefined_init_arg => ( is => 'ro', isa => 'Str', init_arg => undef );
};


{
    my $obj = Test1->new_with_options(
        argv => [ '--name_before', 'something', '--bar', 'baz', '--public',
                  1 ] );
    is( $obj->name_after, 'something', 'init_arg is respected' );

    is( $obj->_private, 1, 'works with "public" init_arg and private attribute');
}

{
    package Test::Dashes;
    use Moose;
    with 'MooseX::Getopt::Dashes';

    has name_after => ( is => 'ro', isa => 'Str', init_arg => 'name-before' );
    has bar => ( is => 'ro', isa => 'Str', );
};

{
    my $obj = Test::Dashes->new_with_options(
        argv => [ '--name-before', 'something', '--bar', 'baz', ] );
    is( $obj->name_after, 'something', 'init_arg is respected with dashes' );
}

done_testing;
