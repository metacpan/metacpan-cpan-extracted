package PlantUML::ClassDiagram::Parse;

use strict;
use warnings;
use utf8;
use PlantUML::ClassDiagram::Class;
use PlantUML::ClassDiagram::Relation;

our $VERSION = "0.1";

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->follow_best_practice;

my @self_valiables = qw/
classes
relations
class_strings
relation_strings
/;
__PACKAGE__->mk_ro_accessors(@self_valiables);

sub new {
    my ($class, $class_strings, $relation_strings) = @_;

    my $relations = +[ map { PlantUML::ClassDiagram::Relation->build($_) } @{$relation_strings} ];
    my $classes   = +[ map { PlantUML::ClassDiagram::Class->build($_, $relations) } @{$class_strings} ];

    my $attr = +{
        class_strings    => $class_strings,
        relation_strings => $relation_strings,
        classes          => $classes,
        relations        => $relations,
    };
    return $class->SUPER::new($attr);
}

sub parse {
    my ($class, $text) = @_;

    my $filtered_text    = $class->_remove_commentout($text);
    my $class_strings    = $class->_extract_class_strings($filtered_text);
    my $relation_strings = $class->_extract_relation_strings($filtered_text);

    return $class->new($class_strings, $relation_strings);
}

sub _remove_commentout {
    my ($class, $string) = @_;

    $string =~ s/\/'.*?'\///sg;
    return $string;
}

sub _extract_class_strings {
    my ($class, $string) = @_;

    my @class_strings = $string =~ /(?:abstract\s+)*class.*?{.*?\n}/sg; # '\n}' for capture nest bracket
    return \@class_strings;
}

sub _extract_relation_strings {
    my ($class, $string) = @_;

    my $relation_strings = +[];
    my @lines = split('\n', $string);
    for my $line (@lines){
        # *- , <- , <|- , <|.
        if ($line =~ /(\*|<)\|?(-|\.)/) {
            push(@$relation_strings, $line);
        # -* , -> , -|> , .|>
        } elsif ($line =~ /(-|\.)\|?(\*|>)/) {
            push(@$relation_strings, $line);
        }
    }

    chomp $_ for @$relation_strings;
    return $relation_strings;
}


1;

=encoding utf-8

=head1 NAME

PlantUML::ClassDiagram::Parse - PlantUML class diagram syntax parser

=head1 SYNOPSIS

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

=head1 DESCRIPTION

PlantUML::ClassDiagram::Parse is parser for PlantUML class diagram syntax
It generate objects that represent class structure written in class diagram.

=head2 WAY TO USE

Generate perl module using PlantUML::ClassDiagram::Class objects.
In fact you will also use template engine (ex: Text::Xslate) together.

Sample script:
    See examples/generate_pm_sample.pl

=head2 class

PlantUML::ClassDiagram::Class - represent each class

=over

=item get_name()

own class name

=item get_attribute()

'' or 'abstract'

=item get_variables()

PlantUML::ClassDiagram::Class::Variable objects

=item get_methods()

PlantUML::ClassDiagram::Class::Method objects

=item get_relations()

PlantUML::ClassDiagram::Relation objects related in own class

=item get_parents()

parent class names it guessed from 'generalization' relation

=back

=head2 method

PlantUML::ClassDiagram::Class::Method - represent each method

=over

=item get_name()

own method name

=item get_attribute()

'' or 'abstract' or 'static'

=back

=head2 variable

PlantUML::ClassDiagram::Class::Variable - represent each member variable

=over

=item get_name()

own method name

=item get_attribute()

'' or 'abstract' or 'static'

=back

=head2 relations

PlantUML::ClassDiagram::Relation - represent class to class relation

=over

=item get_name()

own relation name

=item get_from()

from class name

=item get_to()

to class name

=back

Only support follow relation syntax

=over

=item association

=item generalization

=item realization

=item aggregation

=item composite

=back


=head1 LICENSE

Copyright (C) Kenta Kase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta Kase E<lt>kesin1202000@gmail.comE<gt>

=cut
