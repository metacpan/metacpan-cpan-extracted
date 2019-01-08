
package RDF::Simple::Parser::Attribs;

use Carp;
use Data::Dumper;

# Use a hash to implement objects of this type:
use Class::MethodMaker [
                        scalar => [ qw( qnames x ) ],
                       ];

our
$VERSION = 1.31;

sub new {
    my ($class, $attrs) = @_;

    my $self = bless {}, ref $class || $class;
    while (my ($k,$v) = each %{$attrs}) {

        my ($p,$n) = ($v->{NamespaceURI},$v->{LocalName});
        $self->{$p.$n} = $v->{Value};
    }
    return $self;
}

1;
