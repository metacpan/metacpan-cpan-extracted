package OWL::DirectSemantics::Writer::Dump;

BEGIN {
	$OWL::DirectSemantics::Writer::Dump::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Writer::Dump::VERSION   = '0.001';
};

use 5.008;

use Moose::Role;

requires qw[element_name];

sub dump
{
	my ($self, $indent) = @_;
	$indent = '' unless defined $indent;
	
	my @keyvalue;
	foreach ($self->meta->get_all_attributes)
	{
		my $attr = $_->name;
		next if $attr eq 'annotations';
		next if $attr eq 'axioms';
		next if $attr eq 'metadata';
		my $val = $self->$attr;
		$val = [$val] unless ref($val) eq 'ARRAY';
		push @keyvalue, sprintf('%s=%s', $attr,
			(join ',',
				map {
					if (blessed($_) and $_->isa('RDF::Trine::Node'))
						{ $_->as_ntriples }
					elsif (!defined $_)
						{ 'null' }
					elsif (ref $_)
						{ ref $_ }
					else
						{ $_ }
					} @$val
				)
			)||'null';
	}
	
	my $keyvalue = join ' ', sort @keyvalue;
	
	my @anns   = $self->annotations;
	my @axioms = $self->axioms if $self->can('axioms');
	my $str = '';
	if (@anns || @axioms)
	{
		$str .= sprintf("%s%s(\n", $indent, $self->element_name);
		$str .= sprintf("%s\t%s\n", $indent, $keyvalue);
		$str .= $_->dump("\t${indent}") foreach @anns; 
		$str .= $_->dump("\t${indent}") foreach @axioms; 
		$str .= sprintf("%s\t)\n", $indent);
	}
	else
	{
		$str .= sprintf("%s%s( %s )\n", $indent, $self->element_name, $keyvalue);
	}
	
	return $str;
}

1;

=head1 NAME

OWL::DirectSemantics::Writer::Dump - Moose::Role providing reasonably readable output

=head1 DESCRIPTION

This Moose::Role provides a C<dump> method to output an element for debugging.

It requires the object or class it is composed with to provide an C<element_name> method.

C<element_name> is essentially the name of the "function" the object represents, e.g.
'ClassAssertion'.

=head1 SEE ALSO

L<OWL::DirectSemantics>,
L<OWL::DirectSemantics::Element>.

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

