#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use constant Shortcuts => 'MooseX::AttributeShortcuts::Trait::Attribute';

sub test_class {
    my $classname      = shift @_;
    my $writer_prefix  = shift @_ || '_set_';
    my $builder_prefix = shift @_ || '_build_';

    test_class_sanity_checks($classname, qw{ foo bar baz });

    my $meta = $classname->meta;
    my ($foo, $bar, $baz) = map { $meta->get_attribute($_) } qw{ foo bar baz };

    is($_->reader, $_->name, $_->name . ': reader => correct') for $foo, $bar, $baz;
    is($_->writer, $writer_prefix . $_->name, $_->name . ': writer => correct') for $foo, $baz;
    is($_->writer, undef, $_->name . ': writer => correct (undef)') for $bar;
    is($_->builder, undef, $_->name . ': builder => correct (undef)') for $foo;
    is($_->accessor, undef, $_->name . ': accessor => correct (undef)') for $foo, $bar, $baz;
    is($_->builder, $builder_prefix . $_->name, $_->name . ': builder => correct') for $bar, $baz;
}

sub test_class_sanity_checks {
    my ($classname, @attributes) = @_;

    # sanity checks
    meta_ok($classname);
    does_ok(
        $classname->meta->attribute_metaclass,
        'MooseX::AttributeShortcuts::Trait::Attribute',
    );
    has_attribute_ok($classname, $_) for @attributes;
    ok($classname->meta->get_attribute($_)->does(Shortcuts), "does role: $_")
        for @attributes;

    return;
}

sub check_attribute {
    my ($class, $name, %accessors) = @_;

    has_attribute_ok($class, $name);
    my $att = $class->meta->get_attribute($name);

    my $check = sub {
        my $property = $_;
        my $value    = $accessors{$property};
        my $has      = "has_$property";

        defined $value
            ? ok($att->$has,  "$name has $property")
            : ok(!$att->$has, "$name does not have $property")
            ;
        is($att->$property, $value, "$name: $property correct")
    };

    $check->() for grep { ! /(init_arg|lazy)/ } keys %accessors;

    if (exists $accessors{init_arg}) {

        if ($accessors{init_arg}) {
            local $_ = 'init_arg';
            $check->();
        }
        else {

            ok(!$att->has_init_arg, "$name has no init_arg");
        }
    }

    if (exists $accessors{lazy} && $accessors{lazy}) {

        ok($att->is_lazy, "$name is lazy");
    }
    elsif (exists $accessors{lazy} && !$accessors{lazy}) {

        is(!$att->is_lazy, "$name is not lazy");
    }

    return;
}

1;
