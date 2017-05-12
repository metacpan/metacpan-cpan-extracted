use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose qw( with_immutable );


{
    package SingleUsage;

    use Moose;
    use MooseX::SlurpyConstructor;

    has slurpy => (
        is      => 'ro',
        isa     => 'HashRef[Str]',
        slurpy  => 1,
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

my @classes = qw( SingleUsage );

with_immutable {

    my $no_slurpy = SingleUsage->new({
        non_slurpy  => 32,
        other       => 33,
    });
    ok( defined $no_slurpy,
        "instantiating class with no unknown attributes"
    );
    is_deeply( $no_slurpy->slurpy,
        {},
        "...slurpy attribute is empty hashref"
    );

    my $with_slurpy = SingleUsage->new({
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

    like(
        exception {
            SingleUsage->new({
                unknown     => {},
            });
        },
        qr/^Attribute \(slurpy\) does not pass the type constraint/,
        'slurpy attributes honour type constraints'
    );
}
@classes;

done_testing;
