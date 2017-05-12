package OWL::DirectSemantics::Element::Declaration;

BEGIN {
	$OWL::DirectSemantics::Element::Declaration::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Element::Declaration::VERSION   = '0.001';
};

use 5.008;





use Moose;

extends 'OWL::DirectSemantics::Element';
with 'OWL::DirectSemantics::Writer::Dump';
with 'OWL::DirectSemantics::Writer::FunctionalSyntax';

has 'declare' => (is => 'rw', isa => 'OWL::DirectSemantics::Element', required=>1);

sub fs_arguments
{
	my ($self) = @_;
	return ($self->declare);
}

sub dump
{
	my ($self, $indent) = @_;
	chomp(my $child = $self->declare->dump);
	my @anns = $self->annotations;
	
	if (@anns)
	{
		my $str = sprintf("%sDeclaration( %s\n", $indent, $child);
		$str .= $_->dump("\t${indent}") foreach @anns;
		$str .= "\t${indent})\n";
		return $str;
	}

	return sprintf("%sDeclaration( %s )\n", $indent, $child);
}

1;

__END__

=head1 NAME

OWL::DirectSemantics::Element::Declaration - represents an OWL Declaration

=head1 DESCRIPTION

This class represents the Declaration element in OWL Direct Semantics.

This class inherits from OWL::DirectSemantics::Element.

It does the OWL::DirectSemantics::Writer::FunctionalSyntax and
OWL::DirectSemantics::Writer::Dump roles.

=head2 Attributes

=over

=item C<< annotations >>

A list of annotations associated with this object.
The value is a ArrayRef.

=item C<< declare >>

The thing that was declared.
The value is a OWL::DirectSemantics::Element.
This is a required attribute.



=back

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


