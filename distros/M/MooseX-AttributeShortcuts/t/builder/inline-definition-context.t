use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.049 ':all';

use aliased 'MooseX::AttributeShortcuts::Trait::Method::Builder'
    => 'BuilderTrait';
use aliased 'MooseX::AttributeShortcuts::Trait::Role::Method::Builder'
    => 'RoleBuilderTrait';

{
    package BBB;
    use Moose::Role;
    use MooseX::AttributeShortcuts;

    has bar => (is => 'lazy', builder => sub { });
}
{
    package AAA;
    use Moose;
    use MooseX::AttributeShortcuts;
    with 'BBB';

    has foo => (is => 'lazy', builder => sub { });
}


my %data = (
    _build_foo => [
        {
            context     => 'has declaration',
            description => 'builder AAA::_build_foo of attribute foo',
            file        => __FILE__,
            line        => 25,
            package     => 'AAA',
            type        => 'class',
        },
        BuilderTrait,
    ],
    _build_bar => [
        {
            context     => 'has declaration',
            description => 'builder BBB::_build_bar of attribute bar',
            file        => __FILE__,
            line        => 17,
            package     => 'BBB',
            type        => 'role'
        },
        RoleBuilderTrait,
    ],
);

# until TMM properly allows method metaclass testing via the validate_*()'s,
# we'll do it the hard way

_method($_ => @{$data{$_}})
    for sort keys %data;

sub _method {
    my ($name, $dc, $trait) = @_;

    my $method = AAA->meta->get_method($name);
    does_ok $method, $trait;
    definition_context_ok($method, $dc);
}

done_testing;
