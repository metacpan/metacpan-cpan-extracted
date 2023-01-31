
package PRANG::Graph::Node;
$PRANG::Graph::Node::VERSION = '0.21';
use Moose::Role;

sub accept_many {0}

#method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx )
#  returns ($key, $value, $nodeNameIfAmbiguous)
requires 'accept';

#method complete( PRANG::Graph::Context $ctx )
#  returns Bool
requires 'complete';

#method expected( PRANG::Graph::Context $ctx )
#  returns (@Str)
requires 'expected';

# method output ( Object $item, XML::LibXML::Element $node, HashRef $xsi )
requires 'output';

sub createTextNode {
    my $self = shift;
    my $doc = shift;
    my $text = shift;
    
    my $method = $PRANG::EMIT_CDATA ? 'createCDATASection' : 'createTextNode';
    
    my $tn = $doc->$method($text);
}

1;

__END__

=head1 NAME

PRANG::Graph::Node - role for nodes in XML Graph machinery

=head1 SYNOPSIS

 package PRANG::Graph::Foo;
 with 'PRANG::Graph::Node';

=head1 DESCRIPTION

This role is essentially an interface which different types of
acceptors/emitted in the marshalling machinery must implement.

You should hopefully not have to implement or poke into this class,
but if you do end up there while debugging then this documentation is
for you.

=head1 REQUIRED METHODS

Currently there are four methods required;

=head2 B<accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) returns ($key, $value, $nodeNameIfAmbiguous)>

Given an XML node, completely and recursively parse that node,
construct an object and return that object along with the name of the
node if the schema requires it.

Updates C<$ctx> with any parse state affected by the operation.

=head2 B<complete( PRANG::Graph::Context $ctx ) returns Bool>

Returns true if the acceptor could be happy with the amount of parsing
that has been recorded in C<$ctx> or not.

=head2 B<expected( PRANG::Graph::Context $ctx ) returns (@Str)>

If there has not been enough accepted, then this function returns
something useful for building a helpful exception message.

=head2 B<output( Object $item, XML::LibXML::Element $node, HashRef $xsi)>

Given the item C<$item>, marshall to XML by constructing new LibXML nodes and attaching to C<$node>; C<$xsi> is the current XML namespaces mapping.

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Attr>,
L<PRANG::Graph::Meta::Element>, L<PRANG::Marshaller>,
L<PRANG::Graph::Context>

Implementations:

L<PRANG::Graph::Seq>, L<PRANG::Graph::Quant>, L<PRANG::Graph::Choice>,
L<PRANG::Graph::Element>, L<PRANG::Graph::Text>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

