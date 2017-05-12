
# $Id: Attribs.pm,v 1.3 2009/04/11 15:37:22 Martin Exp $

package RDF::Simple::Parser::Attribs;

use Carp;
use Data::Dumper;

# Use a hash to implement objects of this type:
use Class::MakeMethods::Standard::Hash (
                                        scalar => [ qw( qnames x ) ],
                                       );

our
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

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
