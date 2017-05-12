# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML/ContextNode.pm 68052 2008-08-08T06:27:52.258779Z daisuke  $

package MooseX::DOM::LibXML::ContextNode;
use Moose;
use Class::Inspector;
use XML::LibXML;
use XML::LibXML::XPathContext;

has 'node' => (
    is       => 'rw',
    isa      => 'XML::LibXML::Element',
    required => 1,
    handles  => [ 
        grep { 
            !/^[0-9A-Z_]+$/ && !/^(?:findnodes|findvalue)$/ } (
            @{ Class::Inspector->methods( 'XML::LibXML::Element', 'public' ) },
        )
    ]
);

has 'context' => (
    is => 'rw',
    isa => 'XML::LibXML::XPathContext',
    required => 1,
    handles => [ qw(findnodes findvalue) ],
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILDARGS {
    my ($self, %args) = @_;

    my $xc = XML::LibXML::XPathContext->new($args{node});
    while (my ($prefix, $uri) = each %{ $args{namespaces} || {} }) {
        next if defined $xc->lookupNs($uri);

        $xc->registerNs($prefix, $uri);
    }

    return { %args, context => $xc };
}

1;
