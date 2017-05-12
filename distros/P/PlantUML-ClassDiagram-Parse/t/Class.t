use strict;
use warnings;
use utf8;
use Test::More;
use PlantUML::ClassDiagram::Relation;
use PlantUML::ClassDiagram::Class::Variable;
use PlantUML::ClassDiagram::Class::Method;
use t::Util qw/load_fixture/;

my $CLASS = 'PlantUML::ClassDiagram::Class';
BEGIN { use_ok 'PlantUML::ClassDiagram::Class' };

subtest "private_methods" => sub {
    subtest "_get_class_name" => sub {
        my $string = 'class PlantUML::ClassDiagram::Class {';
        my $expect = 'PlantUML::ClassDiagram::Class';
        is ($CLASS->_get_class_name($string), $expect, 'short class name');

        $string = 'class PlantUML::ClassDiagram::Class::Foo::Long::Long {';
        $expect = 'PlantUML::ClassDiagram::Class::Foo::Long::Long';
        is ($CLASS->_get_class_name($string), $expect, 'Long class name');

        $string = 'class PlantUML::ClassDiagram::Class << D >> {';
        $expect = 'PlantUML::ClassDiagram::Class';
        is ($CLASS->_get_class_name($string), $expect, 'class name with specific spot');
    };

    subtest "_get_class_attribute" => sub {
        my $class_line = 'class PlantUML::ClassDiagram::Class {';
        is ($CLASS->_get_class_attribute($class_line), '', 'normal class');

        my $abstract_class_line = 'abstract class PlantUML::ClassDiagram::Class {';
        is ($CLASS->_get_class_attribute($abstract_class_line), 'abstract', 'abstract class');
    };

    subtest "_get_relations" => sub {
        my $class_name = 'Foo';
        my $relative_relation = PlantUML::ClassDiagram::Relation->new('generalization', $class_name, 'Bar'); # Bar <|-- Foo
        my $not_relative_relation = PlantUML::ClassDiagram::Relation->new('composite', 'Hoge', 'Baz'); # Baz *-- Hoge
        my $relations = +[
            $relative_relation,
            $not_relative_relation,
        ];
        my $expect = +[$relative_relation];
        is_deeply ($CLASS->_get_relations($class_name, $relations), $expect);
    };
};

subtest "public methods" => sub {
    my $fixture = load_fixture('class.pu');
    my $class_name = 'PlantUML::ClassDiagram::Class'; # should be same as fixture class name
    my $generalization_relations = PlantUML::ClassDiagram::Relation->new('generalization', $class_name, 'PlantUML::ClassDiagram');
    my $composite_relations = PlantUML::ClassDiagram::Relation->new('composite', 'Hoge', $class_name);
    my $relations = +[
        $generalization_relations,
        $composite_relations,
    ];

    my $class_instance = $CLASS->build($fixture, $relations);

    subtest "build" => sub {
        is ($class_instance->get_name, $class_name, 'class name');
        is ($class_instance->get_attribute, 'abstract', 'class attribute');
        is_deeply ($class_instance->get_variables, +[
            PlantUML::ClassDiagram::Class::Variable->new('name'),
            PlantUML::ClassDiagram::Class::Variable->new('attribute'),
            PlantUML::ClassDiagram::Class::Variable->new('variables'),
            PlantUML::ClassDiagram::Class::Variable->new('methods'),
            PlantUML::ClassDiagram::Class::Variable->new('relations'),
        ], 'class variables');
        is_deeply ($class_instance->get_methods, +[
            PlantUML::ClassDiagram::Class::Method->new('build', 'static'),
            PlantUML::ClassDiagram::Class::Method->new('get_parents'),
        ], 'class metdhos');
        is_deeply ($class_instance->get_relations, $relations, 'class relations');
    };

    subtest "get_parents" => sub {
        is_deeply ($class_instance->get_parents(), +['PlantUML::ClassDiagram'], 'get_parents');
    };
};

done_testing;
