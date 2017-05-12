
package PRANG::Graph::Seq;
$PRANG::Graph::Seq::VERSION = '0.18';
use Moose;
use MooseX::Params::Validate;

has 'members' =>
	is => "ro",
	isa => "ArrayRef[PRANG::Graph::Node]",
	default => sub { [] },
	;

sub accept {
    my $self = shift;
    my ( $node, $ctx, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Bool' },
    );     
    
	my $pos = $ctx->seq_pos;
	my ($key, $val, $x, $ns, $member);
	do {	    
	    $member = $self->members->[$pos-1];
		
		if (! $member) {
			$ctx->exception("unexpected element", $node)
			 unless $lax;
			return;
		}
		
		($key, $val, $x, $ns) = $member->accept($node, $ctx, $lax);
		
		if (!$key or !$member->accept_many ) {
			$ctx->seq_pos(++$pos);
		}
	} until ($key);
	($key, $val, $x, $ns);
}

sub complete {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );
    
	my $pos = $ctx->seq_pos;
	my $member;
	my $done;
	while ( !$done ) {
		$member = $self->members->[$pos-1];
		if ( $member and $member->complete($ctx) ) {
			$ctx->seq_pos(++$pos);
		}
		else {
			$done = 1;
		}
	}
	my $cmp = $pos-1 <=> @{$self->members};
	if ( $cmp == 1 ) {
		warn "Accepted too much!!";
	}
	return ( $cmp != -1 );
}

sub expected {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	my $pos = $ctx->seq_pos;
	my $member = $self->members->[$pos-1];
	if ($member) {
		return $member->expected($ctx);
	}
	else {
		return "er... nothing?";
	}
}

sub output {
    my $self = shift;
    my ( $item, $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'Item' },
        { isa => 'XML::LibXML::Element' },
        { isa => 'PRANG::Graph::Context' },
    );      
    
	for my $member ( @{ $self->members } ) {
		$member->output($item,$node,$ctx);
	}
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Seq - a sequence of graph nodes

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point has a
sequence of text nodes, elements, element choices or quantities
thereof, depending on the type of entries in the B<members> property.

Classes with only one element defined do not have one of these objects
in their graph.  Typically there is one members entry per element
defined in the class.

=head1 ATTRIBUTES

=over

=item B<ArrayRef[PRANG::Graph::Node] members>

The B<members> property provides the next portion of the XML Graph.
Depending on the type of entry, it will accept and emit nodes in a
particular way.

Entries must be one of L<PRANG::Graph::Quant>, L<PRANG::Graph::Choice>,
L<PRANG::Graph::Element>, or L<PRANG::Graph::Text>.

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Context>, L<PRANG::Graph::Node>

Lower order L<PRANG::Graph::Node> types:

L<PRANG::Graph::Quant>, L<PRANG::Graph::Choice>,
L<PRANG::Graph::Element>, L<PRANG::Graph::Text>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

