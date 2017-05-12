package PlantUML::ClassDiagram::Class::Factory;

use strict;
use warnings;
use utf8;
use PlantUML::ClassDiagram::Class::Method;
use PlantUML::ClassDiagram::Class::Variable;

my $METHOD = 'PlantUML::ClassDiagram::Class::Method';
my $VARIABLE = 'PlantUML::ClassDiagram::Class::Variable';

sub create {
    my ($class, $string) = @_;

    return undef if $class->_check_is_separator($string);
    return undef if $class->_check_is_comment($string);

    return $METHOD->build($string)   if $class->_check_is_method($string);
    return $VARIABLE->build($string) if $class->_check_is_variable($string);

    return undef;
}

sub _check_is_separator {
    my ($class, $string) = @_;

    return 1 if ($string =~ /(--|__|==|\.\.)/);
    return 0;
}

sub _check_is_comment {
    my ($class, $string) = @_;

    return 1 if ($string =~ /'.*'/);
    return 0;
}

sub _check_is_method {
    my ($class, $string) = @_;

    return 1 if ($string =~ /\w+\(.*\)/);
    return 0;
}

sub _check_is_variable {
    my ($class, $string) = @_;

    return 1 if ($string =~ /\w+/);
    return 0;
}

1;
