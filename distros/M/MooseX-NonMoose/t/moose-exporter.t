#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    require Moose;

    package Foo::Exporter::Class;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaroles(
            for             => $options{for_class},
            class_metaroles => {
                class => ['MooseX::NonMoose::Meta::Role::Class'],
            },
        );
        return Moose::Util::find_meta($options{for_class});
    }

    package Foo::Exporter::ClassAndConstructor;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaroles(
            for             => $options{for_class},
            class_metaroles => {
                class => ['MooseX::NonMoose::Meta::Role::Class'],
                constructor =>
                    ['MooseX::NonMoose::Meta::Role::Constructor'],
            },
        );
        return Moose::Util::find_meta($options{for_class});
    }

}

package Foo;

sub new { bless {}, shift }

package Foo::Moose;
BEGIN { Foo::Exporter::Class->import }
extends 'Foo';

package Foo::Moose2;
BEGIN { Foo::Exporter::ClassAndConstructor->import }
extends 'Foo';

package main;
ok(Foo::Moose->meta->has_method('new'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Moose->new, 'Moose::Object');
isa_ok(Foo::Moose->new, 'Foo');
my $method = Foo::Moose->meta->get_method('new');
Foo::Moose->meta->make_immutable;
is(Foo::Moose->meta->get_method('new'), $method,
   'inlining doesn\'t happen when the constructor trait isn\'t used');
ok(Foo::Moose2->meta->has_method('new'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Moose2->new, 'Moose::Object');
isa_ok(Foo::Moose2->new, 'Foo');
my $method2 = Foo::Moose2->meta->get_method('new');
Foo::Moose2->meta->make_immutable;
isnt(Foo::Moose2->meta->get_method('new'), $method2,
   'inlining does happen when the constructor trait is used');

done_testing;
