
package RDF::Simple::Parser::Element;

use Data::Dumper;

use Class::MethodMaker [
                        
                        scalar => [ qw/ base subject language URI qname attrs parent children xtext text / ],
                       ];

our
$VERSION = 1.31;

sub new {
    my ($class,$ns,$prefix,$name,$parent,$attrs,%p) = @_;
    my $self = bless {}, ref $class || $class;
    my $base = $attrs->{base};
    $base ||= $parent->{base};
    $base ||= $p{base};
    $self->base($base);
    $self->URI($ns.$name);
    $self->qname($ns.':'.$name);
    $self->attrs($attrs);
    $self->parent($parent) if $parent;
    $self->xtext([]);
    return $self;
}

1;
