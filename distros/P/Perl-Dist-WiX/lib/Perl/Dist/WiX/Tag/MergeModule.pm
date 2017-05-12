package Perl::Dist::WiX::Tag::MergeModule;

=pod

=head1 NAME

Perl::Dist::WiX::Tag::MergeModule - <Merge> tag that makes its own <MergeRef> when requested.

=head1 VERSION

This document describes Perl::Dist::WiX::Tag::MergeModule version 1.500.

=head1 SYNOPSIS

  my $tag = Perl::Dist::WiX::Tag::MergeModule->new(
			id          => 'Perl',
			disk_id     => 1,
			language    => 1033,
			source_file => catfile(
				$dist->output_dir(), $dist->output_base_filename() . '.msm'
			),
			primary_reference => 1,
  );

=head1 DESCRIPTION

This object defines an XML tag that links a Merge Module into a 
L<Perl::Dist::WiX|Perl::Dist::WiX> based distribution.

=cut

use 5.010;
use Moose;
require WiX3::XML::MergeRef;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Merge';

=head1 METHODS

This class is a L<WiX3::XML::Merge|WiX3::XML::Merge> and inherits its API, so 
only additional API is documented here.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Tag::MergeModule|Perl::Dist::WiX::Tag::MergeModule> 
object.

If an error occurs, it throws an exception.

It inherits all the parameters described in the 
L<WiX3::XML::Merge|WiX3::XML::Merge> C<new> method documentation, and adds 
one additional parameter.

=head3 primary_reference

The optional boolean C<primary_reference> param specifies whether the merge 
module's reference requested with L<get_merge_reference|/get_merge_reference>
is the "primary reference" (whether the C<Primary> attribute to the 
reference is set to "yes") to the contents of the merge module.

=cut



has primary_reference => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
	reader  => '_is_primary_reference',
);



=head2 get_merge_reference

The C<get_merge_reference> method returns the L<WiX3::XML::MergeRef|WiX3::XML::MergeRef>
defined by the L<new|/new> method's id and primary_reference parameters.

=cut



sub get_merge_reference {
	my $self = shift;

	my $primary = $self->_is_primary_reference() ? 'yes' : 'no';
	my $merge_ref =
	  WiX3::XML::MergeRef->new( $self, 'primary' => $primary );

	return $merge_ref;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_merge.htm>,
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_mergeref.htm>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
