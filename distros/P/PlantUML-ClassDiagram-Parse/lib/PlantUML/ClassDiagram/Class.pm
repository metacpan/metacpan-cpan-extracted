package PlantUML::ClassDiagram::Class;

use strict;
use warnings;
use utf8;

use PlantUML::ClassDiagram::Class::Factory;
use parent qw/Class::Accessor::Fast/;
__PACKAGE__->follow_best_practice;

my @self_valiables = qw/
name
attribute
variables
methods
relations
/;
__PACKAGE__->mk_ro_accessors(@self_valiables);

sub new {
    my ($class, $name, $attribute, $variables, $methods, $relations) = @_;
    my $attr = +{
        name      => $name      || '',
        attribute => $attribute || '',
        variables => ( $variables && scalar @$variables ) ? $variables : +[],
        methods   => ( $methods   && scalar @$methods )   ? $methods   : +[],
        relations => ( $relations && scalar @$relations ) ? $relations : +[],
    };
    return $class->SUPER::new($attr);
}

sub build {
    my ($class, $class_string, $relations) = @_;

    my @lines = split(/\n/, $class_string);
    my $class_name_string = shift @lines;

    my $class_name      = $class->_get_class_name($class_name_string);
    my $class_attribute = $class->_get_class_attribute($class_name_string);
    my $class_relations = $class->_get_relations( $class_name, $relations );

    # variables and methods
    my ($class_variables, $class_methods) = (+[], +[]);
    for my $line (@lines) {
        chomp $line;
        my $instance = PlantUML::ClassDiagram::Class::Factory->create($line);
        next unless $instance;

        push( @$class_variables, $instance ) if $instance->is_variable;
        push( @$class_methods,   $instance ) if $instance->is_method;
    }

    return $class->new(
        $class_name,
        $class_attribute,
        $class_variables,
        $class_methods,
        $class_relations
    );
}

sub _get_class_name {
    my ($class, $class_name_string) = @_;

    my ($class_name) = $class_name_string =~ /class\s+([\w|:]+)\s+.*\{/;
    return $class_name;
}

sub _get_class_attribute {
    my ($class, $class_name_string) = @_;

    my ($attribute) = $class_name_string =~ /^(\w+)\s*class/;
    return $attribute || '';
}

sub _get_relations {
    my ($class, $class_name, $relations) = @_;

    return +[ grep {
        $_->get_from eq $class_name ||
        $_->get_to eq $class_name
    } @$relations ];
}

sub get_parents {
    my ($self) = @_;

    my $parent_relations = +[ grep {
            $_->get_name eq 'generalization' &&
            $_->get_from eq $self->get_name
    } @{$self->get_relations} ];

    return +[ map { $_->get_to } @$parent_relations ];
}

sub is_abstract {
    my ($self) = @_;

    return ($self->get_attribute eq 'abstract') ? 1 : 0;
}

1;
