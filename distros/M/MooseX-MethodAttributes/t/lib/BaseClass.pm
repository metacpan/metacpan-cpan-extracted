use strict;
use warnings;

package BaseClass::Meta::Role;
use Moose::Role;

package BaseClass;

use Moose;
use Moose::Util::MetaRole;
BEGIN {
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => {
            class => [qw/ BaseClass::Meta::Role /],
        },
    );

    with 'MooseX::MethodAttributes::Role::AttrContainer::Inheritable';
}

sub moo : Moo {}

{
    my $affe_was_run = 0;

    sub affe : Birne { $affe_was_run++; }

    sub no_calls_to_affe { $affe_was_run }

}

sub foo : Foo {}

sub bar : Baz {}

{
    no warnings 'redefine';
    sub moo : Moo {}
}

1;
