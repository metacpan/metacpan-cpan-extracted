use strict;
use warnings;
use List::Util qw/first/;
use Data::Dumper;
use Data::Section::Simple qw/get_data_section/;
use PlantUML::ClassDiagram::Parse;

my $pu_string = get_data_section('synopsis.pu');
my $parse = PlantUML::ClassDiagram::Parse->parse($pu_string);
my $classes = $parse->get_classes;

print Dumper $classes;

my $foo = first { $_->get_name eq 'Foo' } @$classes;
print Dumper $foo->get_parents;

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
