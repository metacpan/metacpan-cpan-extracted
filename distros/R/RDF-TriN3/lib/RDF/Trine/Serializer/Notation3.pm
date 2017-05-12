package RDF::Trine::Serializer::Notation3;

use 5.010;
use strict;
use warnings;
use parent qw(RDF::Trine::Serializer::NTriples);

######################################################################

our ($VERSION);
BEGIN {
	$VERSION	= '0.206';
	$RDF::Trine::Serializer::serializer_names{ 'notation3' } = __PACKAGE__;
	$RDF::Trine::Serializer::serializer_names{ 'notation 3' } = __PACKAGE__;
	foreach my $type (qw(text/n3)) {
		$RDF::Trine::Serializer::media_types{ $type }	= __PACKAGE__;
	}
}

######################################################################

# these are inherited from RDF::Trine::Serializer::NTriples.

sub _node_as_string {
	my $self = shift;
	my $node = shift;
	
	return $self->_formula_as_string($node)
		if $node->isa('RDF::Trine::Node::Formula');

	return $node->as_string
		if $node->is_variable;
	
	return $node->as_ntriples;
}

sub _statement_as_string {
	my $self = shift;
	my $st   = shift;
	return join(' ', map { $self->_node_as_string($_) } @{[$st->nodes]}[0..2]) . " .\n";
}

sub _formula_as_string {
	my $self = shift;
	my $node = shift;	
	my $rv   = '';
	
	if ($node->forAll) {
		$rv .=  "\t";
		$rv .= '@forAll ' . join ', ', map {$self->_node_as_string($_) } $node->forAll;
		$rv .= " .\n";
	}

	if ($node->forSome) {
		$rv .=  "\t";
		$rv .= '@forSome ' . join ', ', map {$self->_node_as_string($_) } $node->forSome;
		$rv .= " .\n";
	}

	foreach my $st ($node->pattern->triples) {
		my $x = $self->_statement_as_string($st);
		$x =~ s/^/\t/mg; # pretty
		$rv .= $x;
	}
	
	return "{\n$rv}";
}

1;

__END__

=head1 NAME

RDF::Trine::Serializer::Notation3 - Notation 3 Serializer

=head1 SYNOPSIS

 use RDF::Trine::Serializer::Notation3;
 my $serializer	= RDF::Trine::Serializer::Notation3->new();

=head1 DESCRIPTION

The RDF::Trine::Serializer::Notation3 class provides an API for serializing RDF
graphs to the Notation 3 syntax.

The output of this class is not optimised for human-readability; it's a data dump.
The only minor concession it makes to human readers is that it will nicely indent
formulae. I do have plans to port cwm's Notation 3 output to Perl, but this is likely
to be distributed separately due to licensing concerns.

I<Caveat scriptor:> while RDF::Trine::Node::Formula understands quantification
(@forAll, @forSome), RDF::Trine::Model does not. This means that @forAll and
@forSome defined in the top-level graph are not-round-tripped between the
Notation 3 parser and serialiser (the parser will give you warnings about this).
@forAll and @forSome within formulae will work fine.

=head2 Constructor

=over

=item C<< new >>

Returns a new Notation 3 serializer object.

=back

=head2 Methods

=over

=item C<< serialize_model_to_file ( $fh, $model ) >>

Serializes the C<$model> to Notation 3, printing the results to the supplied
filehandle C<<$fh>>.

=item C<< serialize_model_to_string ( $model ) >>

Serializes the C<$model> to Notation 3, returning the result as a string.

=item C<< serialize_iterator_to_file ( $file, $iter ) >>

Serializes the iterator to Notation 3, printing the results to the supplied
filehandle C<<$fh>>.

=item C<< serialize_iterator_to_string ( $iter ) >>

Serializes the iterator to Notation 3, returning the result as a string.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-TriN3>.

=head1 SEE ALSO

L<RDF::Trine::Serializer::NTriples>,
L<RDF::Trine::Serializer::Turtle>.

=head1 AUTHOR

Toby Inkster  C<< <tobyink@cpan.org> >>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2010-2012 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
