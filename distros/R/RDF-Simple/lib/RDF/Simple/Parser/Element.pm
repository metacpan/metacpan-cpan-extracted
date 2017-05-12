
# $Id: Element.pm,v 1.3 2009/04/11 15:37:34 Martin Exp $

package RDF::Simple::Parser::Element;

use Data::Dumper;

# Use a hash to implement objects of this type:
use Class::MakeMethods::Standard::Hash (
                                        scalar => [ qw( base subject language URI qname attrs parent children xtext text )],
                                       );

our
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

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
