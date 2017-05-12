[![Build Status](https://travis-ci.org/Kesin11/plantuml_class_digram_parse.svg?branch=master)](https://travis-ci.org/Kesin11/plantuml_class_digram_parse)
# NAME

PlantUML::ClassDiagram::Parse - PlantUML class diagram syntax parser

# SYNOPSIS

    use List::Util qw/first/;
    use Data::Section::Simple qw/get_data_section/;

    my $pu_string = get_data_section('synopsis.pu');
    my $parse = PlantUML::ClassDiagram::Parse->parse($pu_string);

    my $classes = $parse->get_classes;

    # bless( {
    #    'relations' => [
    #         bless( {
    #              'from' => 'Foo',
    #              'to' => 'Base',
    #              'name' => 'generalization'
    #            }, 'PlantUML::ClassDiagram::Relation' )
    #     ],
    #    'variables' => [
    #         bless( {
    #              'attribute' => '',
    #              'name' => 'foo'
    #            }, 'PlantUML::ClassDiagram::Class::Variable' )
    #    ],
    #    'attribute' => '',
    #    'name' => 'Base',
    #    'methods' => [
    #         bless( {
    #                'name' => 'new',
    #                'attribute' => 'static'
    #              }, 'PlantUML::ClassDiagram::Class::Method' ),
    #         bless( {
    #                'name' => 'bar',
    #                'attribute' => 'abstract'
    #              }, 'PlantUML::ClassDiagram::Class::Method' )
    #     ]
    #  }, 'PlantUML::ClassDiagram::Class' ),
    # bless( {
    #    'methods' => [
    #           bless( {
    #                'name' => 'new',
    #                'attribute' => 'static'
    #              }, 'PlantUML::ClassDiagram::Class::Method' ),
    #           bless( {
    #                'name' => 'bar',
    #                'attribute' => ''
    #              }, 'PlantUML::ClassDiagram::Class::Method' )
    #         ],
    #    'name' => 'Foo',
    #    'relations' => [
    #                     $VAR1->[0]{'relations'}[0]
    #                   ],
    #    'variables' => [
    #             bless( {
    #                  'name' => 'foo',
    #                  'attribute' => ''
    #                }, 'PlantUML::ClassDiagram::Class::Variable' )
    #       ],
    #    'attribute' => ''
    #  }, 'PlantUML::ClassDiagram::Class' )

    my $foo = first { $_->get_name eq 'Foo' } @$classes;
    $foo->get_parents;

    # [ 'Base' ];

    __DATA__
    @@ synopsis.pu
    @startuml

    class Base {
      foo

      {static} new()
      {abstract} bar()
    }
    class Foo {
      foo

      {static} new()
      bar()
    }
    Foo --|> Base

    @enduml

# DESCRIPTION

PlantUML::ClassDiagram::Parse is parser for PlantUML class diagram syntax
It generate objects that represent class structure written in class diagram.

## WAY TO USE

Generate perl module using PlantUML::ClassDiagram::Class objects.
In fact you will also use template engine (ex: Text::Xslate) together.

Sample script:
    See examples/generate\_pm\_sample.pl

## class

PlantUML::ClassDiagram::Class - represent each class

- get\_name()

    own class name

- get\_attribute()

    '' or 'abstract'

- get\_variables()

    PlantUML::ClassDiagram::Class::Variable objects

- get\_methods()

    PlantUML::ClassDiagram::Class::Method objects

- get\_relations()

    PlantUML::ClassDiagram::Relation objects related in own class

- get\_parents()

    parent class names it guessed from 'generalization' relation

## method

PlantUML::ClassDiagram::Class::Method - represent each method

- get\_name()

    own method name

- get\_attribute()

    '' or 'abstract' or 'static'

## variable

PlantUML::ClassDiagram::Class::Variable - represent each member variable

- get\_name()

    own method name

- get\_attribute()

    '' or 'abstract' or 'static'

## relations

PlantUML::ClassDiagram::Relation - represent class to class relation

- get\_name()

    own relation name

- get\_from()

    from class name

- get\_to()

    to class name

Only support follow relation syntax

- association
- generalization
- realization
- aggregation
- composite

# LICENSE

Copyright (C) Kenta Kase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta Kase &lt;kesin1202000@gmail.com>
