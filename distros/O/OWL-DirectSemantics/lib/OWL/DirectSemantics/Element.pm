package OWL::DirectSemantics::Element;

BEGIN {
	$OWL::DirectSemantics::Element::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Element::VERSION   = '0.001';
};




use Moose;

has 'annotations' => (
	is         => 'rw',
	isa        => 'ArrayRef',
	auto_deref => 1,
	default    => sub{[]},
	traits     => ['Array'],
	handles    => { add_annotation => 'push' },
	);

has 'metadata' => (
	is         => 'rw',
	isa        => 'HashRef',
	);

sub element_name
{
	my ($proto) = @_;
	$proto = ref($proto) if ref($proto);
	return $1 if $proto =~ /^OWL::DirectSemantics::Element::(.+)$/;
	return;
}

1;

__END__

=head1 NAME

OWL::DirectSemantics::Element - base class for OWL elements.

=head1 DESCRIPTION

This could porssibly be refactored into a Moose::Role - not sure yet.

=head2 Constructor

=over

=item C<< new(%attributes) >>

Don't construct this base class directly. Constract a subclass instead.

=back

=head2 Attributes

=over

=item C<< annotations >>

A list of annotations associated with this object.
The value is a ArrayRef.

=item C<< metadata >>

This metadata may be used by Writers, etc if available.

=back

=head2 Method

=over

=item C<< element_name >>

Returns undef on the base class or any abstract subclasses. Returns the
element name (e.g. 'ClassAssertion' or 'Declaration') on other subclasses.

=back

=head1 SEE ALSO

L<OWL::DirectSemantics>.

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


