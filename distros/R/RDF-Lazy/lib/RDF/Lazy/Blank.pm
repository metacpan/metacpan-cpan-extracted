package RDF::Lazy::Blank;
use strict;
use warnings;

use base 'RDF::Lazy::Node';
use Scalar::Util qw(blessed);

use overload '""' => \&str;

sub new {
    my $class = shift;
    my $graph = shift || RDF::Lazy->new;
    my $blank = shift;

    $blank = RDF::Trine::Node::Blank->new( $blank )
        unless blessed($blank) and $blank->isa('RDF::Trine::Node::Blank');
    return unless defined $blank;

    return bless [ $blank, $graph ], $class;
}

sub id {
    shift->trine->blank_identifier
}

sub str {
    '_:'.shift->trine->blank_identifier
}

*qname = *str;

1;
__END__

=head1 NAME

RDF::Lazy::Blank - Blank node in a RDF::Lazy graph

=head1 DESCRIPTION

You should not directly create instances of this class.
See L<RDF::Lazy::Node> for general node properties.

=head1 METHODS

=head2 id

Return the local identifier of this node.

=head2 str

Return the local identifier, prepended by "C<_:>".

=cut
