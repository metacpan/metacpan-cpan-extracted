use strict;
use warnings;

use Test::More 0.88;
use Test::Moose qw( with_immutable );

{
    package NoInitArg;

    use Moose;
    use MooseX::SlurpyConstructor;

    has slurpy => (
        is      => 'ro',
        slurpy  => 1,
        init_arg=> undef,
        default => sub { {} },
    );

    has non_slurpy => (
        is      => 'ro',
        slurpy  => 0,
    );

    has other => (
        is      => 'ro',
    );
}

my @classes = qw( NoInitArg );

with_immutable {

    my $no_init_arg = NoInitArg->new({
        non_slurpy  => 32,
        other       => 33,
    });
    ok( defined $no_init_arg,
        "if no init_arg for slurpy attribute, it's not an error to provide in constructor"
    );
    is_deeply( $no_init_arg->slurpy,
        {},
        "...slurpy attribute is empty hashref"
    );

    my $with_slurpy = NoInitArg->new({
        non_slurpy  => 1,
        other       => 2,
        unknown1    => 'a',
        unknown2    => 'b',
        unknown3    => 'c',
    });
    ok( defined $with_slurpy,
        "instantiating class with unknown attributes"
    );
    is_deeply( $with_slurpy->slurpy,
        {
            unknown1    => 'a',
            unknown2    => 'b',
            unknown3    => 'c',
        },
        "...expected value for slurpy attribute"
    );

    my $assigning_slurpy = NoInitArg->new({
        slurpy  => "a"
    });
    is_deeply( $assigning_slurpy->slurpy,
        {
            slurpy  => "a",
        },
        "can assign init_arg with same name as slurpy attribute if it has 'init_arg => undef'"
    );
}
@classes;

done_testing;
