package OWL::DirectSemantics::Element::SubObjectPropertyOf;

BEGIN {
	$OWL::DirectSemantics::Element::SubObjectPropertyOf::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Element::SubObjectPropertyOf::VERSION   = '0.001';
};

use 5.008;





use Moose;

extends 'OWL::DirectSemantics::Element';
with 'OWL::DirectSemantics::Writer::Dump';
with 'OWL::DirectSemantics::Writer::FunctionalSyntax';

has 'subprop'   => (is => 'rw', isa => 'RDF::Trine::Node', required=>1);
has 'superprop' => (is => 'rw', isa => 'RDF::Trine::Node', required=>1);

sub fs_arguments { return ($_[0]->subprop, $_[0]->superprop); }

1;

__END__

=head1 NAME

OWL::DirectSemantics::Element::SubObjectPropertyOf - represents an OWL SubObjectPropertyOf

=head1 DESCRIPTION

This class represents the SubObjectPropertyOf element in OWL Direct Semantics.

This class inherits from OWL::DirectSemantics::Element.

It does the OWL::DirectSemantics::Writer::FunctionalSyntax and
OWL::DirectSemantics::Writer::Dump roles.

=head2 Attributes

=over

=item C<< annotations >>

A list of annotations associated with this object.
The value is a ArrayRef.

=item C<< subprop >>

The subproperty in the relationship.
The value is a RDF::Trine::Node.
This is a required attribute.

=item C<< superprop >>

The superproperty in the relationship.
The value is a RDF::Trine::Node.
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


