package Perl::Dist::WiX::PropertyList;

=pod

=head1 NAME

Perl::Dist::WiX::PropertyList - A list of <Property> and <WixVariable> tags.

=head1 VERSION

This document describes Perl::Dist::WiX::PropertyList version 1.500.

=head1 SYNOPSIS

	# Create an icon array
	my $list = Perl::Dist::WiX::PropertyList->new();

	# Add an property to the list, then go looking for it.
	my $property_tag = $list->add_simple_property('ARPNOMODIFY', '1');
	
	# Print out all the icons in XML format.
	my $xml = $list->as_string();

=head1 DESCRIPTION

TODO

The object is not a singleton - maybe it should be?

=cut

use 5.010;
use Moose 0.90;
use Params::Util qw( _STRING _INSTANCE );
use WiX3::XML::Property qw();
use WiX3::XML::WixVariable qw();

with 'WiX3::Role::Traceable', 'WiX3::XML::Role::TagAllowsChildTags';

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

=head1 INTERFACE

=head2 new

	my $list = Perl::Dist::WiX::PropertyList->new();

Creates a new C<Perl::Dist::WiX::PropertyList> object.

Takes no parameters.

=head2 add_simple_property

	my $property_tag = $list->add_simple_property('ARPNOMODIFY', '1');

The C<add_simple_property> routine adds a property to the list 
identified by the first parameter, with its value being the second 
parameter.

L<URI|URI> values are stringified.

=cut

sub add_simple_property {
	my ( $self, $id, $value ) = @_;

	if ( defined _INSTANCE( $value, 'URI' ) ) {
		$value = $value->as_string();
	}
	if ( defined _INSTANCE( $value, 'Path::Class::File' ) ) {
		$value = $value->stringify();
	}
	if ( defined _INSTANCE( $value, 'Path::Class::Dir' ) ) {
		$value = $value->stringify();
	}
	if ( not defined _STRING($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::PropertyList->add_simple_property'
		);
	}
	if ( not defined _STRING($value) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '::PropertyList->add_simple_property'
		);
	}

	my $property = WiX3::XML::Property->new(
		id         => $id,
		inner_text => $value,
	);

	$self->add_child_tag($property);

	return $property;
} ## end sub add_simple_property


=head2 add_wixvariable

TODO

=cut



sub add_wixvariable {
	my ( $self, $id, $value ) = @_;

	if ( defined _INSTANCE( $value, 'URI' ) ) {
		$value = $value->as_string();
	}
	if ( defined _INSTANCE( $value, 'Path::Class::File' ) ) {
		$value = $value->stringify();
	}
	if ( defined _INSTANCE( $value, 'Path::Class::Dir' ) ) {
		$value = $value->stringify();
	}
	if ( not defined _STRING($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::PropertyList->add_wixvariable'
		);
	}
	if ( not defined _STRING($value) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '::PropertyList->add_wixvariable'
		);
	}

	my $var = WiX3::XML::WixVariable->new(
		id    => $id,
		value => $value,
	);

	$self->add_child_tag($var);

	return $var;
} ## end sub add_wixvariable


=head2 as_string

	my $xml = $list->as_string();

The C<as_string> method returns XML code for all properties 
included in this object.

=cut



sub as_string {
	my $self = shift;

	# Short-circuit
	if ( 0 == $self->count_child_tags() ) { return q{}; }

	return $self->indent( 2, $self->as_string_children() );
}


=head2 get_namespace

TODO

=cut



sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}



no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
