use strict;
use warnings;
package RDF::Lazy::Blank;
{
  $RDF::Lazy::Blank::VERSION = '0.081';
}
#ABSTRACT: Blank node in a RDF::Lazy graph

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

1;


__END__
=pod

=head1 NAME

RDF::Lazy::Blank - Blank node in a RDF::Lazy graph

=head1 VERSION

version 0.081

=head1 DESCRIPTION

You should not directly create instances of this class.
See L<RDF::Lazy::Node> for general node properties.

=head1 METHODS

=head2 id

Return the local identifier of this node.

=head2 str

Return the local identifier, prepended by "C<_:>".

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

