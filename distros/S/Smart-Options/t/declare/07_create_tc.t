use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;


sub foo{
    opts my $x => "ArrayRef";
    return $x;
}

lives_and{
    @ARGV = qw(--x=10);
    is_deeply foo(), [10];

    @ARGV = qw(--x=10 --x=20 --x=30);
    is_deeply foo(), [10,20,30];

    @ARGV = qw(--x=10 --x=hello);
    is_deeply foo(), [10,'hello'];
};

done_testing;
