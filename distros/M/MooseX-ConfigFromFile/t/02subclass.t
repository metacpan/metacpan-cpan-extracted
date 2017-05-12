use strict;
use warnings;

use Test::More;
use Test::Fatal;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package A;
    use Moose;
    with qw(MooseX::ConfigFromFile);

    sub get_config_from_file { }
}

{
    package B;
    use Moose;
    extends qw(A);
}

ok(B->does('MooseX::ConfigFromFile'), 'B does ConfigFromFile');
is(exception { B->new_with_config() }, undef, 'B->new_with_config lives');

done_testing;
