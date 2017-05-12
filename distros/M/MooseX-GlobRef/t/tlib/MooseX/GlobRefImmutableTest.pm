package MooseX::GlobRefImmutableTest;

use parent 'MooseX::GlobRefTestBase';

use constant test_class => (__PACKAGE__ . '::TestClass');

{
    package MooseX::GlobRefImmutableTest::TestClass;

    use Moose;

    use MooseX::GlobRef;

    has field => (
        is      => 'rw',
        clearer => 'clear_field',
        default => 'default',
        lazy    => 1,
    );

    has weak_field => (
        is      => 'rw',
    );

    sub BUILD {
        my $self = shift;

        # fill some other slots in globref
        my $scalarref = ${*$self};
        $$scalarref = 'SCALAR';
        my $arrayref = \@{*$self};
        @$arrayref = ('ARRAY');

        return $self;
    };

    __PACKAGE__->meta->make_immutable;
};

1;
