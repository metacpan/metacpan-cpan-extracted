#line 1

package Class::MOP;
BEGIN {
  $Class::MOP::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::VERSION = '2.0401';
}

use strict;
use warnings;

use 5.008;

use MRO::Compat;

use Carp          'confess';
use Class::Load   ();
use Scalar::Util  'weaken', 'isweak', 'reftype', 'blessed';
use Data::OptList;
use Try::Tiny;

use Class::MOP::Mixin::AttributeCore;
use Class::MOP::Mixin::HasAttributes;
use Class::MOP::Mixin::HasMethods;
use Class::MOP::Class;
use Class::MOP::Attribute;
use Class::MOP::Method;

BEGIN {
    *IS_RUNNING_ON_5_10 = ($] < 5.009_005)
        ? sub () { 0 }
        : sub () { 1 };

    # this is either part of core or set up appropriately by MRO::Compat
    *check_package_cache_flag = \&mro::get_pkg_gen;
}

XSLoader::load(
    'Moose',
    $Class::MOP::{VERSION} ? ${ $Class::MOP::{VERSION} } : ()
);

{
    # Metaclasses are singletons, so we cache them here.
    # there is no need to worry about destruction though
    # because they should die only when the program dies.
    # After all, do package definitions even get reaped?
    # Anonymous classes manage their own destruction.
    my %METAS;

    sub get_all_metaclasses         {        %METAS         }
    sub get_all_metaclass_instances { values %METAS         }
    sub get_all_metaclass_names     { keys   %METAS         }
    sub get_metaclass_by_name       { $METAS{$_[0]}         }
    sub store_metaclass_by_name     { $METAS{$_[0]} = $_[1] }
    sub weaken_metaclass            { weaken($METAS{$_[0]}) }
    sub metaclass_is_weak           { isweak($METAS{$_[0]}) }
    sub does_metaclass_exist        { exists $METAS{$_[0]} && defined $METAS{$_[0]} }
    sub remove_metaclass_by_name    { delete $METAS{$_[0]}; return }

    # This handles instances as well as class names
    sub class_of {
        return unless defined $_[0];
        my $class = blessed($_[0]) || $_[0];
        return $METAS{$class};
    }

    # NOTE:
    # We only cache metaclasses, meaning instances of
    # Class::MOP::Class. We do not cache instance of
    # Class::MOP::Package or Class::MOP::Module. Mostly
    # because I don't yet see a good reason to do so.
}

sub load_class {
    goto &Class::Load::load_class;
}

sub load_first_existing_class {
    goto &Class::Load::load_first_existing_class;
}

sub is_class_loaded {
    goto &Class::Load::is_class_loaded;
}

sub _definition_context {
    my %context;
    @context{qw(package file line)} = caller(1);

    return (
        definition_context => \%context,
    );
}

## ----------------------------------------------------------------------------
## Setting up our environment ...
## ----------------------------------------------------------------------------
## Class::MOP needs to have a few things in the global perl environment so
## that it can operate effectively. Those things are done here.
## ----------------------------------------------------------------------------

# ... nothing yet actually ;)

## ----------------------------------------------------------------------------
## Bootstrapping
## ----------------------------------------------------------------------------
## The code below here is to bootstrap our MOP with itself. This is also
## sometimes called "tying the knot". By doing this, we make it much easier
## to extend the MOP through subclassing and such since now you can use the
## MOP itself to extend itself.
##
## Yes, I know, thats weird and insane, but it's a good thing, trust me :)
## ----------------------------------------------------------------------------

# We need to add in the meta-attributes here so that
# any subclass of Class::MOP::* will be able to
# inherit them using _construct_instance

## --------------------------------------------------------
## Class::MOP::Mixin::HasMethods

Class::MOP::Mixin::HasMethods->meta->add_attribute(
    Class::MOP::Attribute->new('_methods' => (
        reader   => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            '_method_map' => \&Class::MOP::Mixin::HasMethods::_method_map
        },
        default => sub { {} },
        _definition_context(),
    ))
);

Class::MOP::Mixin::HasMethods->meta->add_attribute(
    Class::MOP::Attribute->new('method_metaclass' => (
        reader   => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'method_metaclass' => \&Class::MOP::Mixin::HasMethods::method_metaclass
        },
        default  => 'Class::MOP::Method',
        _definition_context(),
    ))
);

Class::MOP::Mixin::HasMethods->meta->add_attribute(
    Class::MOP::Attribute->new('wrapped_method_metaclass' => (
        reader   => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'wrapped_method_metaclass' => \&Class::MOP::Mixin::HasMethods::wrapped_method_metaclass
        },
        default  => 'Class::MOP::Method::Wrapped',
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Mixin::HasMethods

Class::MOP::Mixin::HasAttributes->meta->add_attribute(
    Class::MOP::Attribute->new('attributes' => (
        reader   => {
            # NOTE: we need to do this in order
            # for the instance meta-object to
            # not fall into meta-circular death
            #
            # we just alias the original method
            # rather than re-produce it here
            '_attribute_map' => \&Class::MOP::Mixin::HasAttributes::_attribute_map
        },
        default  => sub { {} },
        _definition_context(),
    ))
);

Class::MOP::Mixin::HasAttributes->meta->add_attribute(
    Class::MOP::Attribute->new('attribute_metaclass' => (
        reader   => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'attribute_metaclass' => \&Class::MOP::Mixin::HasAttributes::attribute_metaclass
        },
        default  => 'Class::MOP::Attribute',
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Package

Class::MOP::Package->meta->add_attribute(
    Class::MOP::Attribute->new('package' => (
        reader   => {
            # NOTE: we need to do this in order
            # for the instance meta-object to
            # not fall into meta-circular death
            #
            # we just alias the original method
            # rather than re-produce it here
            'name' => \&Class::MOP::Package::name
        },
        _definition_context(),
    ))
);

Class::MOP::Package->meta->add_attribute(
    Class::MOP::Attribute->new('namespace' => (
        reader => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'namespace' => \&Class::MOP::Package::namespace
        },
        init_arg => undef,
        default  => sub { \undef },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Module

# NOTE:
# yeah this is kind of stretching things a bit,
# but truthfully the version should be an attribute
# of the Module, the weirdness comes from having to
# stick to Perl 5 convention and store it in the
# $VERSION package variable. Basically if you just
# squint at it, it will look how you want it to look.
# Either as a package variable, or as a attribute of
# the metaclass, isn't abstraction great :)

Class::MOP::Module->meta->add_attribute(
    Class::MOP::Attribute->new('version' => (
        reader => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'version' => \&Class::MOP::Module::version
        },
        init_arg => undef,
        default  => sub { \undef },
        _definition_context(),
    ))
);

# NOTE:
# By following the same conventions as version here,
# we are opening up the possibility that people can
# use the $AUTHORITY in non-Class::MOP modules as
# well.

Class::MOP::Module->meta->add_attribute(
    Class::MOP::Attribute->new('authority' => (
        reader => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'authority' => \&Class::MOP::Module::authority
        },
        init_arg => undef,
        default  => sub { \undef },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Class

Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('superclasses' => (
        accessor => {
            # NOTE:
            # we just alias the original method
            # rather than re-produce it here
            'superclasses' => \&Class::MOP::Class::superclasses
        },
        init_arg => undef,
        default  => sub { \undef },
        _definition_context(),
    ))
);

Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('instance_metaclass' => (
        reader   => {
            # NOTE: we need to do this in order
            # for the instance meta-object to
            # not fall into meta-circular death
            #
            # we just alias the original method
            # rather than re-produce it here
            'instance_metaclass' => \&Class::MOP::Class::instance_metaclass
        },
        default  => 'Class::MOP::Instance',
        _definition_context(),
    ))
);

Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('immutable_trait' => (
        reader   => {
            'immutable_trait' => \&Class::MOP::Class::immutable_trait
        },
        default => "Class::MOP::Class::Immutable::Trait",
        _definition_context(),
    ))
);

Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('constructor_name' => (
        reader   => {
            'constructor_name' => \&Class::MOP::Class::constructor_name,
        },
        default => "new",
        _definition_context(),
    ))
);

Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('constructor_class' => (
        reader   => {
            'constructor_class' => \&Class::MOP::Class::constructor_class,
        },
        default => "Class::MOP::Method::Constructor",
        _definition_context(),
    ))
);


Class::MOP::Class->meta->add_attribute(
    Class::MOP::Attribute->new('destructor_class' => (
        reader   => {
            'destructor_class' => \&Class::MOP::Class::destructor_class,
        },
        _definition_context(),
    ))
);

# NOTE:
# we don't actually need to tie the knot with
# Class::MOP::Class here, it is actually handled
# within Class::MOP::Class itself in the
# _construct_class_instance method.

## --------------------------------------------------------
## Class::MOP::Mixin::AttributeCore
Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('name' => (
        reader   => {
            # NOTE: we need to do this in order
            # for the instance meta-object to
            # not fall into meta-circular death
            #
            # we just alias the original method
            # rather than re-produce it here
            'name' => \&Class::MOP::Mixin::AttributeCore::name
        },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('accessor' => (
        reader    => { 'accessor'     => \&Class::MOP::Mixin::AttributeCore::accessor     },
        predicate => { 'has_accessor' => \&Class::MOP::Mixin::AttributeCore::has_accessor },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('reader' => (
        reader    => { 'reader'     => \&Class::MOP::Mixin::AttributeCore::reader     },
        predicate => { 'has_reader' => \&Class::MOP::Mixin::AttributeCore::has_reader },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('initializer' => (
        reader    => { 'initializer'     => \&Class::MOP::Mixin::AttributeCore::initializer     },
        predicate => { 'has_initializer' => \&Class::MOP::Mixin::AttributeCore::has_initializer },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('definition_context' => (
        reader    => { 'definition_context'     => \&Class::MOP::Mixin::AttributeCore::definition_context     },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('writer' => (
        reader    => { 'writer'     => \&Class::MOP::Mixin::AttributeCore::writer     },
        predicate => { 'has_writer' => \&Class::MOP::Mixin::AttributeCore::has_writer },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('predicate' => (
        reader    => { 'predicate'     => \&Class::MOP::Mixin::AttributeCore::predicate     },
        predicate => { 'has_predicate' => \&Class::MOP::Mixin::AttributeCore::has_predicate },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('clearer' => (
        reader    => { 'clearer'     => \&Class::MOP::Mixin::AttributeCore::clearer     },
        predicate => { 'has_clearer' => \&Class::MOP::Mixin::AttributeCore::has_clearer },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('builder' => (
        reader    => { 'builder'     => \&Class::MOP::Mixin::AttributeCore::builder     },
        predicate => { 'has_builder' => \&Class::MOP::Mixin::AttributeCore::has_builder },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('init_arg' => (
        reader    => { 'init_arg'     => \&Class::MOP::Mixin::AttributeCore::init_arg     },
        predicate => { 'has_init_arg' => \&Class::MOP::Mixin::AttributeCore::has_init_arg },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('default' => (
        # default has a custom 'reader' method ...
        predicate => { 'has_default' => \&Class::MOP::Mixin::AttributeCore::has_default },
        _definition_context(),
    ))
);

Class::MOP::Mixin::AttributeCore->meta->add_attribute(
    Class::MOP::Attribute->new('insertion_order' => (
        reader      => { 'insertion_order' => \&Class::MOP::Mixin::AttributeCore::insertion_order },
        writer      => { '_set_insertion_order' => \&Class::MOP::Mixin::AttributeCore::_set_insertion_order },
        predicate   => { 'has_insertion_order' => \&Class::MOP::Mixin::AttributeCore::has_insertion_order },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Attribute
Class::MOP::Attribute->meta->add_attribute(
    Class::MOP::Attribute->new('associated_class' => (
        reader   => {
            # NOTE: we need to do this in order
            # for the instance meta-object to
            # not fall into meta-circular death
            #
            # we just alias the original method
            # rather than re-produce it here
            'associated_class' => \&Class::MOP::Attribute::associated_class
        },
        _definition_context(),
    ))
);

Class::MOP::Attribute->meta->add_attribute(
    Class::MOP::Attribute->new('associated_methods' => (
        reader   => { 'associated_methods' => \&Class::MOP::Attribute::associated_methods },
        default  => sub { [] },
        _definition_context(),
    ))
);

Class::MOP::Attribute->meta->add_method('clone' => sub {
    my $self  = shift;
    $self->meta->clone_object($self, @_);
});

## --------------------------------------------------------
## Class::MOP::Method
Class::MOP::Method->meta->add_attribute(
    Class::MOP::Attribute->new('body' => (
        reader   => { 'body' => \&Class::MOP::Method::body },
        _definition_context(),
    ))
);

Class::MOP::Method->meta->add_attribute(
    Class::MOP::Attribute->new('associated_metaclass' => (
        reader   => { 'associated_metaclass' => \&Class::MOP::Method::associated_metaclass },
        _definition_context(),
    ))
);

Class::MOP::Method->meta->add_attribute(
    Class::MOP::Attribute->new('package_name' => (
        reader   => { 'package_name' => \&Class::MOP::Method::package_name },
        _definition_context(),
    ))
);

Class::MOP::Method->meta->add_attribute(
    Class::MOP::Attribute->new('name' => (
        reader   => { 'name' => \&Class::MOP::Method::name },
        _definition_context(),
    ))
);

Class::MOP::Method->meta->add_attribute(
    Class::MOP::Attribute->new('original_method' => (
        reader   => { 'original_method'      => \&Class::MOP::Method::original_method },
        writer   => { '_set_original_method' => \&Class::MOP::Method::_set_original_method },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Method::Wrapped

# NOTE:
# the way this item is initialized, this
# really does not follow the standard
# practices of attributes, but we put
# it here for completeness
Class::MOP::Method::Wrapped->meta->add_attribute(
    Class::MOP::Attribute->new('modifier_table' => (
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Method::Generated

Class::MOP::Method::Generated->meta->add_attribute(
    Class::MOP::Attribute->new('is_inline' => (
        reader   => { 'is_inline' => \&Class::MOP::Method::Generated::is_inline },
        default  => 0,
        _definition_context(),
    ))
);

Class::MOP::Method::Generated->meta->add_attribute(
    Class::MOP::Attribute->new('definition_context' => (
        reader   => { 'definition_context' => \&Class::MOP::Method::Generated::definition_context },
        _definition_context(),
    ))
);


## --------------------------------------------------------
## Class::MOP::Method::Inlined

Class::MOP::Method::Inlined->meta->add_attribute(
    Class::MOP::Attribute->new('_expected_method_class' => (
        reader   => { '_expected_method_class' => \&Class::MOP::Method::Inlined::_expected_method_class },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Method::Accessor

Class::MOP::Method::Accessor->meta->add_attribute(
    Class::MOP::Attribute->new('attribute' => (
        reader   => {
            'associated_attribute' => \&Class::MOP::Method::Accessor::associated_attribute
        },
        _definition_context(),
    ))
);

Class::MOP::Method::Accessor->meta->add_attribute(
    Class::MOP::Attribute->new('accessor_type' => (
        reader   => { 'accessor_type' => \&Class::MOP::Method::Accessor::accessor_type },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Method::Constructor

Class::MOP::Method::Constructor->meta->add_attribute(
    Class::MOP::Attribute->new('options' => (
        reader   => {
            'options' => \&Class::MOP::Method::Constructor::options
        },
        default  => sub { +{} },
        _definition_context(),
    ))
);

Class::MOP::Method::Constructor->meta->add_attribute(
    Class::MOP::Attribute->new('associated_metaclass' => (
        init_arg => "metaclass", # FIXME alias and rename
        reader   => {
            'associated_metaclass' => \&Class::MOP::Method::Constructor::associated_metaclass
        },
        _definition_context(),
    ))
);

## --------------------------------------------------------
## Class::MOP::Instance

# NOTE:
# these don't yet do much of anything, but are just
# included for completeness

Class::MOP::Instance->meta->add_attribute(
    Class::MOP::Attribute->new('associated_metaclass',
        reader   => { associated_metaclass => \&Class::MOP::Instance::associated_metaclass },
        _definition_context(),
    ),
);

Class::MOP::Instance->meta->add_attribute(
    Class::MOP::Attribute->new('_class_name',
        init_arg => undef,
        reader   => { _class_name => \&Class::MOP::Instance::_class_name },
        #lazy     => 1, # not yet supported by Class::MOP but out our version does it anyway
        #default  => sub { $_[0]->associated_metaclass->name },
        _definition_context(),
    ),
);

Class::MOP::Instance->meta->add_attribute(
    Class::MOP::Attribute->new('attributes',
        reader   => { attributes => \&Class::MOP::Instance::get_all_attributes },
        _definition_context(),
    ),
);

Class::MOP::Instance->meta->add_attribute(
    Class::MOP::Attribute->new('slots',
        reader   => { slots => \&Class::MOP::Instance::slots },
        _definition_context(),
    ),
);

Class::MOP::Instance->meta->add_attribute(
    Class::MOP::Attribute->new('slot_hash',
        reader   => { slot_hash => \&Class::MOP::Instance::slot_hash },
        _definition_context(),
    ),
);

## --------------------------------------------------------
## Class::MOP::Object

# need to replace the meta method there with a real meta method object
Class::MOP::Object->meta->_add_meta_method('meta');

## --------------------------------------------------------
## Class::MOP::Mixin

# need to replace the meta method there with a real meta method object
Class::MOP::Mixin->meta->_add_meta_method('meta');

require Class::MOP::Deprecated unless our $no_deprecated;

# we need the meta instance of the meta instance to be created now, in order
# for the constructor to be able to use it
Class::MOP::Instance->meta->get_meta_instance;

# pretend the add_method never happenned. it hasn't yet affected anything
undef Class::MOP::Instance->meta->{_package_cache_flag};

## --------------------------------------------------------
## Now close all the Class::MOP::* classes

# NOTE: we don't need to inline the the accessors this only lengthens
# the compile time of the MOP, and gives us no actual benefits.

$_->meta->make_immutable(
    inline_constructor  => 0,
    constructor_name    => "_new",
    inline_accessors => 0,
) for qw/
    Class::MOP::Package
    Class::MOP::Module
    Class::MOP::Class

    Class::MOP::Attribute
    Class::MOP::Method
    Class::MOP::Instance

    Class::MOP::Object

    Class::MOP::Method::Generated
    Class::MOP::Method::Inlined

    Class::MOP::Method::Accessor
    Class::MOP::Method::Constructor
    Class::MOP::Method::Wrapped

    Class::MOP::Method::Meta
/;

$_->meta->make_immutable(
    inline_constructor  => 0,
    constructor_name    => undef,
    inline_accessors => 0,
) for qw/
    Class::MOP::Mixin
    Class::MOP::Mixin::AttributeCore
    Class::MOP::Mixin::HasAttributes
    Class::MOP::Mixin::HasMethods
/;

1;

# ABSTRACT: A Meta Object Protocol for Perl 5



#line 1121


__END__

