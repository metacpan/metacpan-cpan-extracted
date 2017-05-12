use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
    use_ok('MooseX::Getopt');
}

{
    package App;
    use Moose;
    use Moose::Util::TypeConstraints;

    use Scalar::Util 'looks_like_number';

    with 'MooseX::Getopt';

    my $array_of_ints = subtype
        as 'ArrayRef',
        where { scalar (grep { looks_like_number($_) } @$_) };

    has 'nums' => (
        is      => 'ro',
        isa     => $array_of_ints,
        default => sub { [0] }
    );
}

{
    local @ARGV = ();

    my $app = App->new_with_options;
    isa_ok($app, 'App');

    is_deeply($app->nums, [0], '... nums is [0] as expected');
}

{
    local @ARGV = ('--nums', 3, '--nums', 5);

    my $app = App->new_with_options;
    isa_ok($app, 'App');

    is_deeply($app->nums, [3, 5], '... nums is [3, 5] as expected');
}

done_testing;
