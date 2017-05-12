package MooseX::GlobRef::ObjectTest;

use parent 'MooseX::GlobRefTestBase';

use constant test_class => (__PACKAGE__ . '::TestClass');

{
    package MooseX::GlobRef::ObjectTest::TestClass;

    use Moose;

    extends 'MooseX::GlobRef::Object';

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

        # if not a globref then will fail later on assertion
        if (Scalar::Util::reftype($self) eq 'GLOB') {
            # fill some other slots in globref
            my $scalarref = ${*$self};
            $$scalarref = 'SCALAR';
            my $arrayref = \@{*$self};
            @$arrayref = ('ARRAY');
        };

        return $self;
    };
};

1;
