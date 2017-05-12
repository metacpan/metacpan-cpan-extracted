#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
    require Mouse;
    require Mouse::Util::MetaRole;

    package Foo::Exporter::Class;
    use Mouse::Exporter;
    Mouse::Exporter->setup_import_methods(also => ['Mouse']);

    sub init_meta {
        shift;
        my %options = @_;
        Mouse->init_meta(%options);
        return Mouse::Util::MetaRole::apply_metaclass_roles(
            for_class               => $options{for_class},
            metaclass_roles         => ['MouseX::Foreign::Meta::Role::Class'],
        );
    }

    package Foo::Exporter::ClassAndConstructor;
    use Mouse::Exporter;
    Mouse::Exporter->setup_import_methods(also => ['Mouse']);

    sub init_meta {
        shift;
        my %options = @_;
        Mouse->init_meta(%options);
        return Mouse::Util::MetaRole::apply_metaclass_roles(
            for_class               => $options{for_class},
            metaclass_roles         => ['MouseX::Foreign::Meta::Role::Class'],
            constructor_class_roles =>
                ['MouseX::Foreign::Meta::Role::Method::Constructor'],
        );
    }

}

package Foo;

sub new { bless {}, shift }

package Foo::Mouse;
BEGIN { Foo::Exporter::Class->import }
extends 'Foo';

package Foo::Mouse2;
BEGIN { Foo::Exporter::ClassAndConstructor->import }
extends 'Foo';

package main;
ok(Foo::Mouse->meta->has_method('new'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Mouse->new, 'Mouse::Object');
isa_ok(Foo::Mouse->new, 'Foo');
my $method = Foo::Mouse->meta->get_method('new');
Foo::Mouse->meta->make_immutable;
{ local $TODO = "method objects has a different semantics from Moose's";
is(Foo::Mouse->meta->get_method('new'), $method,
   'inlining doesn\'t happen when the constructor trait isn\'t used');
}
ok(Foo::Mouse2->meta->has_method('new'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Mouse2->new, 'Mouse::Object');
isa_ok(Foo::Mouse2->new, 'Foo');
my $method2 = Foo::Mouse2->meta->get_method('new');
Foo::Mouse2->meta->make_immutable;
isnt(Foo::Mouse2->meta->get_method('new'), $method2,
   'inlining does happen when the constructor trait is used');
