#!/usr/bin/env perl

package MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt::Test;

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use English qw< -no_match_vars >;
use Readonly;


use parent 'Test::Class';


use Carp qw< confess >;
use File::Spec::Functions qw< catdir >;


use MooseX::Getopt::Defanged::OptionTypeMetadata;
use MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt qw< >;


use Test::Deep;
use Test::Moose;
use Test::More;


use lib catdir( qw< t meta-attribute-trait-_getopt.d lib > );

use StringWrapper qw< >;


Readonly::Scalar my $ROLE_NAME => 'MooseX::Getopt::Defanged::Meta::Attribute::Trait::_Getopt';

Readonly::Hash my %ATTRIBUTE_TYPE_DEFAULT_METADATA => (
    'Bool'              => {
        specification   => q<>
    },
    'Str'               => {
        specification   => '=s',
    },
    'Int'               => {
        specification   => '=i',
    },
    'Num'               => {
        specification   => '=f',
    },
    'RegexpRef'         => {
        specification   => '=s',
    },
    'ArrayRef'          => {
        specification   => '=s{1,}',
    },
    'ArrayRef[Str]'     => {
        specification   => '=s{1,}',
    },
    'ArrayRef[Int]'     => {
        specification   => '=i{1,}',
    },
    'ArrayRef[Num]'     => {
        specification   => '=f{1,}',
    },
    'HashRef'           => {
        specification   => '=s%',
    },
    'HashRef[Str]'      => {
        specification   => '=s%',
    },
    'HashRef[Int]'      => {
        specification   => '=i%',
    },
    'HashRef[Num]'      => {
        specification   => '=f%',
    },
);


__PACKAGE__->runtests();


sub test_1_mooseness : Tests(1) {
    meta_ok($ROLE_NAME, "$ROLE_NAME has a meta class.");

    return;
} # end test_1_mooseness()


sub test_2_can_construct_minimal_consumer : Tests(18) {
    my $class_name = "${ROLE_NAME}::MinimalConsumer";
    use_ok($class_name);
    my $minimal_consumer = new_ok($class_name);

    meta_ok($minimal_consumer, "$class_name has a meta class.");
    does_ok($minimal_consumer, $ROLE_NAME, "$class_name does $ROLE_NAME.");

    foreach my $partial_name (
        qw< name aliases type specification >
    ) {
        my $attribute = "getopt_$partial_name";
        has_attribute_ok(
            $minimal_consumer,
            $attribute,
            "Minimal consumer has a $attribute attribute.",
        );
        can_ok($minimal_consumer, "set_$attribute");
    } # end foreach

    foreach my $partial_name (
        qw< name aliases type specification >
    ) {
        my $attribute = "getopt_$partial_name";
        can_ok($minimal_consumer, "get_$attribute");
    } # end foreach

    foreach my $partial_name (
        qw< required >
    ) {
        my $attribute = "getopt_$partial_name";
        has_attribute_ok(
            $minimal_consumer,
            $attribute,
            "Minimal consumer has a $attribute attribute.",
        );
        can_ok($minimal_consumer, "is_$attribute");
    } # end foreach

    return;
} # end test_2_can_construct_minimal_consumer()


sub test_3_consumer_of_all_types_with_defaults : Tests(238) {
    my $consumer_of_all_types =
        _test_instance_creation(
            "${ROLE_NAME}::ConsumerOfAllTypesWithDefaults"
        );

    # The sort is only to have the keys in deterministic order.  The logic
    # doesn't depend upon it.
    foreach my $type ( sort keys %ATTRIBUTE_TYPE_DEFAULT_METADATA ) {
        _test_defaults_for_type($consumer_of_all_types, $type);
    } # end foreach

    return;
} # end test_3_consumer_of_all_types_with_defaults()


sub _test_instance_creation {
    my ($class_name) = @_;

    use_ok($class_name);
    my $consumer = new_ok($class_name);

    meta_ok($consumer, "$class_name has a meta class.");
    does_ok($consumer, 'MooseX::Getopt::Defanged', "$class_name does MooseX::Getopt::Defanged.");

    return $consumer;
} # end _test_instance_creation()


sub _test_defaults_for_type {
    my ($consumer_of_all_types, $type) = @_;

    my $attribute_name = lc $type;
    $attribute_name =~ s/ \[ /_/xms;
    $attribute_name =~ s/ \] //xms;

    _test_defaults_for_individual_attribute(
        $consumer_of_all_types, $type, $attribute_name,
    );
    _test_defaults_for_individual_attribute(
        $consumer_of_all_types, $type, "maybe_$attribute_name",
    );

    return;
} # end _test_defaults_for_type()


sub _get_and_check_attribute {
    my ($consumer, $attribute_name) = @_;

    my $attribute =
        $consumer->meta()->get_attribute($attribute_name)
            or confess "There's no $attribute_name attribute.";

    does_ok(
        $attribute,
        $ROLE_NAME,
        "$attribute_name attribute does $ROLE_NAME.",
    );

    return $attribute;
} # end _get_and_check_attribute()


sub _test_defaults_for_individual_attribute {
    my ($consumer_of_all_types, $type, $attribute_name) = @_;

    my $attribute =
        _get_and_check_attribute($consumer_of_all_types, $attribute_name);

    foreach my $base_option_name ( qw< name aliases type specification > ) {
        my $method = "get_getopt_$base_option_name";
        is(
            $attribute->$method(),
            undef,
            "getopt_$base_option_name is not defined on $attribute_name.",
        );
    } # end foreach

    (my $expected_option_name = $attribute_name) =~ s/ _ /-/xmsg;
    is(
        $attribute->get_actual_option_name(),
        $expected_option_name,
        "The actual name of the option for the $attribute_name attribute is the same as the attribute name, but with underscores replaced by hyphens.",
    );
    is(
        $attribute->get_option_name_plus_aliases(),
        $expected_option_name,
        "The option name plus aliases for the $attribute_name attribute is the same as the option name because there are no aliases.",
    );

    my $expected_specification =
        $ATTRIBUTE_TYPE_DEFAULT_METADATA{$type}{specification};
    my $type_metadata = MooseX::Getopt::Defanged::OptionTypeMetadata->new();
    is(
        $attribute->get_type_specification($type_metadata),
        $expected_specification,
        qq<The specification for the $attribute_name attribute matches the expected value for the "$type" type.>,
    );
    is(
        $attribute->get_full_specification($type_metadata),
        $expected_option_name . $expected_specification,
        qq<The full specification for the $attribute_name attribute matches the concatenation of the option name and the type specification.>,
    );

    return;
} # end _test_defaults_for_individual_attribute()


sub test_4_consumer_with_alternate_option_names_and_with_aliases : Tests(22) {
    my $consumer =
        _test_instance_creation(
            "${ROLE_NAME}::ConsumerWithOptionNameOverridesAndAliases"
        );

    _test_name_and_aliases_for_attribute(
        $consumer, 'option_with_name_override', 'foo', undef,
    );
    _test_name_and_aliases_for_attribute(
        $consumer, 'option_with_aliases', undef, [ qw< eat a car > ],
    );
    _test_name_and_aliases_for_attribute(
        $consumer,
        'option_with_name_override_and_aliases',
        'foo',
        [ qw< eat a car > ],
    );

    return;
} # end test_4_consumer_with_alternate_option_names_and_with_aliases()


sub _test_name_and_aliases_for_attribute {
    my ($consumer, $attribute_name, $name_override, $aliases) = @_;

    my $attribute = _get_and_check_attribute($consumer, $attribute_name);

    is(
        $attribute->get_getopt_name(),
        $name_override,
        "Name override for the $attribute_name attribute.",
    );
    cmp_deeply(
        $attribute->get_getopt_aliases(),
        $aliases,
        "Aliases for the $attribute_name attribute.",
    );

    my $expected_option_name;
    if ($name_override) {
        $expected_option_name = $name_override;
    } else {
        ($expected_option_name = $attribute_name) =~ s/ _ /-/xmsg;
    } # end if

    is(
        $attribute->get_actual_option_name(),
        $expected_option_name,
        "Got expected option name for the $attribute_name attribute.",
    );

    my @expected_name_plus_aliases = ($expected_option_name);
    if ($aliases) {
        push @expected_name_plus_aliases, @{$aliases};
    } # end if

    my $expected_name_plus_aliases = join q<|>, @expected_name_plus_aliases;
    is(
        $attribute->get_option_name_plus_aliases(),
        $expected_name_plus_aliases,
        "Got expected name/aliases concatentation for the $attribute_name attribute.",
    );

    my $type_metadata = MooseX::Getopt::Defanged::OptionTypeMetadata->new();
    my $expected_specification =
        $ATTRIBUTE_TYPE_DEFAULT_METADATA{Str}{specification};
    is(
        $attribute->get_full_specification($type_metadata),
        $expected_name_plus_aliases . $expected_specification,
        "Got expected full specification for the $attribute_name attribute.",
    );

    return;
} # end _test_name_and_aliases_for_attribute()


sub test_5_consumer_with_type_overrides_and_with_specifications : Tests(19) {
    my $consumer =
        _test_instance_creation(
            "${ROLE_NAME}::ConsumerWithTypeAndSpecificationOverrides"
        );

    _test_type_and_specification_for_attribute(
        $consumer, 'option_with_type_override', 'Int', undef,
    );
    _test_type_and_specification_for_attribute(
        $consumer, 'option_with_specification', undef, q<:+>,
    );
    _test_type_and_specification_for_attribute(
        $consumer,
        'option_with_type_override_and_specification',
        'Int',
        q<:+>,
    );

    return;
} # end test_5_consumer_with_type_overrides_and_with_specifications()


sub _test_type_and_specification_for_attribute {
    my ($consumer, $attribute_name, $type_override, $specification) = @_;

    my $attribute = _get_and_check_attribute($consumer, $attribute_name);

    is(
        $attribute->get_getopt_type(),
        $type_override,
        "Type override for the $attribute_name attribute.",
    );
    is(
        $attribute->get_getopt_specification(),
        $specification,
        "Specification for the $attribute_name attribute.",
    );

    my $type_metadata = MooseX::Getopt::Defanged::OptionTypeMetadata->new();
    my $expected_option_type = $type_override // 'Num';
    my $expected_specification =
            $specification
        //  $ATTRIBUTE_TYPE_DEFAULT_METADATA{$expected_option_type}{specification};
    is(
        $attribute->get_type_specification($type_metadata),
        $expected_specification,
        "Got expected type specification for the $attribute_name attribute.",
    );

    is(
        $attribute->get_full_specification($type_metadata),
        $attribute->get_actual_option_name() . $expected_specification,
        "Got expected full specification for the $attribute_name attribute.",
    );

    return;
} # end _test_type_and_specification_for_attribute()


sub test_6_consumer_with_object_attributes : Tests(7) {
    my $consumer =
        _test_instance_creation(
            "${ROLE_NAME}::ConsumerWithObjects"
        );

    $consumer->parse_command_line([qw<
            --option-with-object-and-stringify-string http://www.example.net
            --option-with-object-and-stringify-coderef http://www.example.net
    >]);

    cmp_deeply(
        $consumer,
        methods( option_with_object_and_stringify_string => StringWrapper->new('http://www.example.net') ),
        'Stringify an option object using method name',
    );
    cmp_deeply(
        $consumer,
        methods( option_with_object_and_stringify_coderef => StringWrapper->new('http://www.example.net') ),
        'Stringify an option object using code ref',
    );
    cmp_deeply(
        $consumer,
        methods( option_with_arrayref_of_objects => [
            StringWrapper->new('http://www.example.com'),
            StringWrapper->new('http://www.example.net') ]
        ),
        'Stringify an option with an array of objects',
    );

    return;
} # end test_6_consumer_with_object_attributes()


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
