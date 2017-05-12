package TAEB::OO;
use Moose ();
use MooseX::ClassAttribute ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use TAEB::Meta::Trait::Persistent;
use TAEB::Meta::Trait::GoodStatus;
use TAEB::Meta::Types;
use TAEB::Meta::Overload;

Moose::Exporter->setup_import_methods(
    also        => ['Moose', 'MooseX::ClassAttribute'],
    with_caller => ['extends'],
);

# make sure using extends doesn't wipe out our base class roles
sub extends {
    my ($caller, @superclasses) = @_;
    Class::MOP::load_class($_) for @superclasses;
    for my $parent (@superclasses) {
        goto \&Moose::extends if $parent->can('does')
                              && $parent->does('TAEB::Role::Initialize');
    }
    # i'm assuming that after apply_base_class_roles, we'll have a single
    # base class...
    my ($superclass_from_metarole) = $caller->meta->superclasses;
    push @_, $superclass_from_metarole;
    goto \&Moose::extends;
}

sub init_meta {
    shift;
    my %options = @_;
    Moose->init_meta(%options);
    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $options{for_class},
        roles     => ['TAEB::Role::Initialize', 'TAEB::Role::Subscription'],
    );
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => $options{for_class},
        attribute_metaclass_roles => ['TAEB::Meta::Trait::Provided'],
    ) if $options{for_class} =~ /^TAEB::Action/;
    return $options{for_class}->meta;
}

1;

