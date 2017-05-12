package PlantUML::ClassDiagram::Class::Variable;

use strict;
use warnings;
use utf8;

use parent qw/PlantUML::ClassDiagram::Class::Base/;
__PACKAGE__->follow_best_practice;

my @self_valiables = qw/
name
attribute
/;
__PACKAGE__->mk_ro_accessors(@self_valiables);

sub build {
    my ($class, $string) = @_;

    my ($name)      = $string =~ /(\w+)/;
    my ($attribute) = $string =~ /\{(\w+)\}/;

    return $class->new($name, $attribute);
}

sub is_variable { 1 }

1;
