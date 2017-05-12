use strict;
use warnings;
use utf8;
use Text::Xslate;
use Data::Section::Simple qw/get_data_section/;;
use PlantUML::ClassDiagram::Parse;

my $pu_string = get_data_section('synopsis.pu');
my $parse = PlantUML::ClassDiagram::Parse->parse($pu_string);
my $classes = $parse->get_classes;

my $tx = Text::Xslate->new(syntax => 'Kolon');
my $template = get_data_section('template.tx');

for my $klass (@$classes){
    my $parents = (scalar @{$klass->get_parents})
        ? $klass->get_parents
        : +['Class::Accessor::Fast'];

    print $tx->render_string($template, +{
            klass => $klass,
            parents => $parents,
        }
    );
}

1;

__DATA__
@@ template.tx
package <: $klass.get_name :>;

use strict;
use warnings;
use utf8;
use parent qw/
: for $parents -> $parent {
    <: $parent :>
: }
/;

my @ATTRIBUTES = qw/
: for $klass.get_variables -> $variable {
    <: $variable.get_name :>
:}
/;
__PACKAGE__->mk_ro_accessors(@ATTRIBUTES);

sub new {
    my $class = shift;
    my (%args) = @_;
    my %attrs;

    @attrs{@ATTRIBUTES} = @args{@ATTRIBUTES};
    return $class->SUPER::new(\%attrs);
}

: for $klass.get_methods -> $method {
sub <: $method.get_name :> {
    : if $method.is_static {
    my $class = shift;
    : } else {
    my $self = shift;
    : }
    my ($arg) = @_;

    : if $method.is_abstract {
    die ('<: $method.get_name :> must be override');
    : }
    return;
}

: }
1;

@@ synopsis.pu
@startuml

class Base {
  foo

  {abstract} bar()
}
class Foo {
  foo

  bar()
  hogehoge()
}
Foo --|> Base

@enduml
