use strict;
use warnings;
use utf8;
use Test::More;
use List::Util qw/first/;
use PlantUML::ClassDiagram::Parse;
use t::Util qw/load_fixture/;

my $CLASS = 'PlantUML::ClassDiagram::Parse';
BEGIN { use_ok 'PlantUML::ClassDiagram::Parse' };

my $fixture = load_fixture('all.pu');

subtest "parse()" => sub {
    my $parser = $CLASS->parse($fixture);

    subtest "parsed class_strings" => sub {
        my $expects = +[
'class Base {
}',
'class Main {
  run()
}',
'class PlantUML::ClassDiagram::Parse {
  classes
  relations
  {static} parse()
  _extract_class_strings()
  _extract_relation_strings()
}',
'class PlantUML::ClassDiagram::Class::Factory {
  {static} create()
  _check_is_method()
  _check_is_variable()
}',
'class PlantUML::ClassDiagram::Class {
  attribute
  parents
  variables
  methods
  build()
}',
'abstract class PlantUML::ClassDiagram::Class::Base {
  name
  attribute
  build()
}',
'class PlantUML::ClassDiagram::Class::Variable {
  name
  attribute
  build()
}',
'class PlantUML::ClassDiagram::Class::Method {
  name
  attribute
  build()
}',
'class PlantUML::ClassDiagram::Relation {
  from
  to
  name
  build()
}',
        ];
        is_deeply($parser->get_class_strings, $expects);
    };

    subtest "parsed relation_strings" => sub {
        my $expect = +[
            'PlantUML::ClassDiagram::Class *-- PlantUML::ClassDiagram::Class::Variable',
            'PlantUML::ClassDiagram::Class *-- PlantUML::ClassDiagram::Class::Method',
            'PlantUML::ClassDiagram::Class <-- PlantUML::ClassDiagram::Relation',
            'PlantUML::ClassDiagram::Class::Factory <-- PlantUML::ClassDiagram::Class',
            'PlantUML::ClassDiagram::Class::Factory ..|> PlantUML::ClassDiagram::Class::Variable',
            'PlantUML::ClassDiagram::Class::Factory ..|> PlantUML::ClassDiagram::Class::Method',
            'PlantUML::ClassDiagram::Class::Variable -down-|> PlantUML::ClassDiagram::Class::Base',
            'PlantUML::ClassDiagram::Class::Method -down-|> PlantUML::ClassDiagram::Class::Base',
        ];
        is_deeply($parser->get_relation_strings, $expect);
    };

    subtest "parsed classes" => sub {
        my $expect_class_names = +[
            'Base',
            'Main',
            'PlantUML::ClassDiagram::Parse',
            'PlantUML::ClassDiagram::Class::Factory',
            'PlantUML::ClassDiagram::Class',
            'PlantUML::ClassDiagram::Class::Base',
            'PlantUML::ClassDiagram::Class::Variable',
            'PlantUML::ClassDiagram::Class::Method',
            'PlantUML::ClassDiagram::Relation',
        ];
        my $got_class_names = +[ map { $_->get_name } @{$parser->get_classes} ];
        is_deeply($got_class_names, $expect_class_names, 'class names');
    };

    subtest "parsed relations" => sub {
        subtest "class names" => sub {
            my $expect_from_names = +[
                'PlantUML::ClassDiagram::Class::Variable',
                'PlantUML::ClassDiagram::Class::Method',
                'PlantUML::ClassDiagram::Relation',
                'PlantUML::ClassDiagram::Class',
                'PlantUML::ClassDiagram::Class::Factory',
                'PlantUML::ClassDiagram::Class::Factory',
                'PlantUML::ClassDiagram::Class::Variable',
                'PlantUML::ClassDiagram::Class::Method',
            ];
            my $got_from_names = +[ map { $_->get_from } @{$parser->get_relations} ];
            is_deeply($got_from_names, $expect_from_names, 'relation from names');
        };

        subtest "parents" => sub {
            my $has_parent_relation = first { $_->get_name eq 'generalization' } @{$parser->get_relations};
            my $parent_name = $has_parent_relation->get_to;
            my $child_name = $has_parent_relation->get_from;

            my $child_class = first { $_->get_name eq $child_name } @{$parser->get_classes};
            my $parent_class = first { $_ eq $parent_name } @{$child_class->get_parents};
            ok (defined $parent_class, 'has parent');
        };
    };
};


done_testing;
