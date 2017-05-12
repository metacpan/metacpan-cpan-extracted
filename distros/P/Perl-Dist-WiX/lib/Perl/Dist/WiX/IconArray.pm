package Perl::Dist::WiX::IconArray;

=pod

=head1 NAME

Perl::Dist::WiX::IconArray - A list of <Icon> tags.

=head1 VERSION

This document describes Perl::Dist::WiX::IconArray version 1.500.

=head1 SYNOPSIS

	# Create an icon array
	my $array = Perl::Dist::WiX::IconArray->new();

	# Add an icon to the array, then go looking for it.
	my $icon_id = $array->add_icon('C:\strawberry\win32\cpan.ico', 'C:\strawberry\perl\bin\cpan.bat');
	$icon_id = $array->search_icon('C:\strawberry\win32\cpan.ico', 'bat');
	
	# The second parameters are optional IF you're referring to the msi's icon.
	my $icon_id_2 = $array->add_icon('C:\strawberry\win32\strawberry.ico');
	$icon_id_2 = $array->search_icon('C:\strawberry\win32\strawberry.ico');

	# Print out all the icons in XML format.
	my $xml = $array->as_string();

=head1 DESCRIPTION

This stores all the icons that are used in a 
L<Perl::Dist::WiX|Perl::Dist::WiX>-based installer for Start Menu shortcuts
or for the Add/Remove Programs entry, so that they can all be defined in
one place when linking the installer together.

The object is not a singleton - maybe it should be?

=cut

use 5.010;
use Moose 0.90;
use Params::Util qw( _STRING _INSTANCE  );
use File::Spec::Functions qw( splitpath );
require Perl::Dist::WiX::Tag::Icon;

with 'WiX3::Role::Traceable';

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

# Private storage for the icons added.
has _icon => (
	traits   => ['Array'],
	is       => 'rw',
	isa      => 'ArrayRef[Perl::Dist::WiX::Tag::Icon]',
	default  => sub { [] },
	init_arg => undef,
	handles  => {
		'_push_icon'      => 'push',
		'_count_icons'    => 'count',
		'_get_icon_array' => 'elements',
	},
);



=head1 INTERFACE

=head2 new

	my $array = Perl::Dist::WiX::IconArray->new();

Creates a new C<Perl::Dist::WiX::IconArray> object.

Takes no parameters.

=head2 add_icon

	my $icon_id = $array->add_icon('C:\strawberry\win32\cpan.ico', 'C:\strawberry\perl\bin\cpan.bat');

The C<add_icon> routine adds an icon to the array for the icon file 
referred to in the first parameter, and that targets the file in the 
second parameter.

The second parameter defaults to 'Perl.msi' (which is a shortcut for 
the icon that should be linked to in Add/Remove Programs for your
software.)

Either parameter can be a L<Path::Class::File|Path::Class::File>.

=cut

sub add_icon {
	my ( $self, $pathname_icon, $pathname_target ) = @_;

	# Check parameters
	if ( not defined $pathname_target ) {
		$pathname_target = 'Perl.msi';
	}
	if ( defined _INSTANCE( $pathname_icon, 'Path::Class::File' ) ) {
		$pathname_icon = $pathname_icon->stringify();
	}
	if ( defined _INSTANCE( $pathname_target, 'Path::Class::File' ) ) {
		$pathname_target = $pathname_target->stringify();
	}
	if ( not defined _STRING($pathname_target) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_target',
			where     => '::IconArray->add_icon'
		);
	}
	if ( not defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::IconArray->add_icon'
		);
	}

	# Find the type of target.
	my ($target_type) = $pathname_target =~ m{\A.*[.](.+)\z}msx;

	$self->trace_line( 2,
		"Adding icon $pathname_icon with target type $target_type.\n" );

	# If we have an icon already, return it.
	my $icon = $self->search_icon( $pathname_icon, $target_type );
	if ( defined $icon ) { return $icon; }

	# Get Id made.
	my ( undef, undef, $filename_icon ) = splitpath($pathname_icon);
	my $id = substr $filename_icon, 0, -4;
	$id =~ s/[[:^alnum:]]/_/gmxs;      # Substitute _ for anything
	                                   # non-alphanumeric.
	$id .= ".$target_type.ico";

	# Add icon to our list.
	$self->_push_icon(
		Perl::Dist::WiX::Tag::Icon->new(
			sourcefile  => $pathname_icon,
			target_type => $target_type,
			id          => $id
		) );

	return $id;
} ## end sub add_icon



=head2 search_icon

	my $icon_id = $array->search_icon('C:\strawberry\win32\cpan.ico', 'bat');

The C<search_icon> routine searches the array for the ID of the icon object
that refers to the icon file in the first parameter, and targets a file
with the extension in the second parameter.

The second parameter defaults to 'msi'.

=cut



sub search_icon {
	## no critic (ProhibitExplicitReturnUndef)
	my ( $self, $pathname_icon, $target_type ) = @_;

	# Check parameters
	if ( not defined $target_type ) {
		$target_type = 'msi';
	}
	if ( not defined _STRING($target_type) ) {
		PDWiX::Parameter->throw(
			parameter => 'target_type',
			where     => '::IconArray->search_icon'
		);
	}
	if ( not defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::IconArray->search_icon'
		);
	}

	if ( 0 == $self->_count_icons() ) { return undef; }

	# Print each icon
	foreach my $icon ( $self->_get_icon_array() ) {
		if (    ( $icon->get_sourcefile eq $pathname_icon )
			and ( $icon->get_target_type eq $target_type ) )
		{
			return $icon->get_id;
		}
	}

	return undef;
} ## end sub search_icon



=head2 as_string

	my $xml = $array->as_string();

The C<as_string> method returns XML code for all icon objects 
included in this object.
	
=cut



sub as_string {
	my $self = shift;
	my $answer;

	# Short-circuit
	if ( 0 == $self->_count_icons ) { return q{}; }

	# Print each icon
	foreach my $icon ( $self->_get_icon_array() ) {
		my $id   = $icon->get_id();
		my $file = $icon->get_sourcefile();
		$answer .= "    <Icon Id='I_$id' SourceFile='$file' />\n";
	}

	return $answer;
} ## end sub as_string

no Moose;
__PACKAGE__->meta->make_immutable;

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

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
