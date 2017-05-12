use strict;
use warnings;
use Test::More 0.88;

BEGIN {
    require Moose;
    if (Moose->VERSION < 1.9900) {
        plan skip_all => q{this test isn't relevant on Moose 1.x};
    }
}

{
    package Foo::Meta::Role::Attribute;
    use Moose::Role;

    has foo => (is => 'ro');
}

{
    package Foo::Exporter;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(
        role_metaroles => {
            applied_attribute => ['Foo::Meta::Role::Attribute'],
        },
    );
}

{
    package Foo::Role1;
    use MooseX::Role::Parameterized;

    role {
        my $p = shift;
        my %args = @_;
        Foo::Exporter->import({into => $args{operating_on}->name});

        has foo => (is => 'ro', foo => 'bar');
    };
}

{
    package Foo1;
    use Moose;
    with 'Foo::Role1';
}

{
    is(
        Foo1->meta->find_attribute_by_name('foo')->foo, 'bar',
        'applied_attribute metaroles work when applied to generated role'
    );
}

{
    package Foo::Role2;
    use MooseX::Role::Parameterized;
    Foo::Exporter->import;

    has foo => (is => 'ro', foo => 'bar');

    role {
        my $p = shift;

        has bar => (is => 'ro');
    };
}

{
    package Foo2;
    use Moose;
    with 'Foo::Role2';
}

{
    is(Foo2->meta->find_attribute_by_name('foo')->foo, 'bar',
       'applied_attribute metaroles work when applied to parameterizable role');
}

{
    package Foo::Role3;
    use MooseX::Role::Parameterized;

    has foo => (is => 'ro', foo => 'bar');

    role {
        my $p = shift;

        has bar => (is => 'ro');
    };

    Foo::Exporter->import;
}

{
    package Foo3;
    use Moose;
    with 'Foo::Role3';
}

{
    is(Foo3->meta->find_attribute_by_name('foo')->foo, 'bar',
       'applied_attribute metaroles work when applied to parameterizable role after the role block has been defined');
}

done_testing;
