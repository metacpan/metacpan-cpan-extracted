package OWL::DirectSemantics::Writer::FunctionalSyntax;

BEGIN {
	$OWL::DirectSemantics::Writer::FunctionalSyntax::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Writer::FunctionalSyntax::VERSION   = '0.001';
};

use 5.008;

use Moose::Role;

requires qw[fs_arguments element_name];

sub fs
{
	my ($self, $indent) = @_;
	$indent = '' unless defined $indent;
	
	my $arguments = join ' ',
		map { $self->fs_fmt_argument($_); } $self->fs_arguments;
	
	my @anns   = $self->annotations;
	my @axioms = $self->axioms if $self->can('axioms');
	my $str = '';
	if (@anns || @axioms)
	{
		$str .= sprintf("%s%s(\n", $indent, $self->element_name);
		$str .= sprintf("%s\t%s\n", $indent, $arguments);
		$str .= $_->fs("\t${indent}") foreach @anns; 
		$str .= $_->fs("\t${indent}") foreach @axioms; 
		$str .= sprintf("%s\t)\n", $indent);
	}
	else
	{
		$str .= sprintf("%s%s( %s )\n", $indent, $self->element_name, $arguments);
	}
	
	return $str;
}

sub fs_fmt_argument
{
	my ($self, $node) = @_;
	
	if (blessed($node) and $node->isa('RDF::Trine::Node::Blank') and $self->can('metadata'))
	{
		my $sse  = "$node";
		foreach my $r (qw[CE DR OPE DPE AP])
		{
			if (ref($self->metadata) eq 'HASH'
			and ref($self->metadata->{$r}) eq 'HASH'
			and ref($self->metadata->{$r}{$sse}) eq 'ARRAY')
			{
				my $rv = $self->fs_fmt_argument($self->metadata->{$r}{$sse}[-1]);
				return $rv;
			}
		}
	}
	
	if (blessed($node) and $node->DOES(__PACKAGE__))
	{
		chomp(my $fs = $node->fs);
		return $fs;
	}
	
	if (blessed($node) and $node->can('as_ntriples'))
	{
		return $node->as_ntriples;
	}

	return "$node";
}

1;

=head1 NAME

OWL::DirectSemantics::Writer::FunctionalSyntax - Moose::Role providing functional syntax output

=head1 DESCRIPTION

This Moose::Role provides an C<fs> method to output OWL Functional Syntax.

It requires the object or class it is composed with to provide C<element_name> and
C<fs_arguments> methods.

C<element_name> is essentially the name of the "function" the object represents, e.g.
'ClassAssertion'. C<fs_arguments> returns a list of arguments included within the
parentheses in the output - these may be literal strings, RDF::Trine::Node objects or
may be other objects that have a C<OWL::DirectSemantics::Writer::FunctionalSyntax> role.

=head1 SEE ALSO

L<OWL::DirectSemantics>,
L<OWL::DirectSemantics::Element>,
L<RDF::Trine::Serializer::OwlFn>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

