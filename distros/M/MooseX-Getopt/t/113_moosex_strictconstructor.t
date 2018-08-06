use strict;
use warnings;

use Test::Needs 'MooseX::StrictConstructor';
use Test::More 0.88;
use Test::Fatal;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package Test1;
    use Moose;
    with 'MooseX::Getopt';
    use MooseX::StrictConstructor;

    has att1 => (is => 'ro', isa => 'Str');
};

{
    my $o1;
    is(
        exception { $o1 = Test1->new_with_options(argv => [ '--att1', 'value1' ]); },
        undef,
        'new_with_options + argv on a MooseX::StrictConstructor enabled class',
    );
    cmp_ok($o1->att1, 'eq', 'value1', 'att1 gets initialized correctly');
}


{
    package Test2;
    use Moose;
    with 'MooseX::Getopt';
    use MooseX::StrictConstructor;

    has argv => (is => 'ro');
    has att1 => (is => 'ro', isa => 'Str');
};

{
    my $o2;
    is(
        exception { $o2 = Test2->new_with_options(argv => [ '--att1', 'value1' ]); },
        undef,
        'new_with_options + argv on a MooseX::StrictConstructor enabled class',
    );

    cmp_ok($o2->att1, 'eq', 'value1', 'att1 gets initialized correctly');
    is_deeply($o2->argv, ['--att1', 'value1'], 'attribute argv is correct too');
}

done_testing;
