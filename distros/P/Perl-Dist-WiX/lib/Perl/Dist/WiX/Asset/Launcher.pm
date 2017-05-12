package Perl::Dist::WiX::Asset::Launcher;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Launcher - Start menu launcher asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Launcher version 1.500.

=head1 SYNOPSIS

  my $batlauncher = Perl::Dist::WiX::Asset::Launcher->new(
    parent => $dist,
    name   => 'CPAN Client',
    bin    => 'cpan',
  );
  
  $batlauncher->install();

  my $exelauncher = Perl::Dist::WiX::Asset::Launcher->new(
    parent => $dist,
    name   => 'Padre Development Environment',
    bin    => 'padre',
    exe    => 1,
  );
  
  $exelauncher->install();

=head1 DESCRIPTION

This asset creates a Start Menu entry for a script or executable file in the
perl binary directory.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str Bool );
use File::Spec::Functions qw( catfile );
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::NonURLAsset';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::Launcher> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new()|Perl::Dist::WiX::Role::Asset/new >> 
method documentation, and adds the additional parameters described below.

=head3 name

The required C<name> parameter is the name of the link in the start menu.

=cut



has name => (
	is       => 'bare',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);



=head3 bin

The C<bin> parameter is the name of the script or executable file to link 
to.

=cut



has bin => (
	is       => 'bare',
	isa      => Str,
	reader   => '_get_bin',
	required => 1,
);



=head3 exe

The C<exe> parameter specifies if the file is an executable file, as opposed to
a script that has been converted to a batch file.

=cut



has exe => (
	is      => 'bare',
	isa     => Bool,
	reader  => '_get_exe',
	default => 0,
);



=head3 directory_id

The C<directory_id> parameter specifies the directory that the Start menu 
link is to be created in.

=cut



has directory_id => (
	is      => 'bare',
	isa     => Str,
	reader  => '_get_directory_id',
	default => 'D_App_Menu_Tools',
);



=head2 install

The install method installs the Start Menu link described by the
B<Perl::Dist::WiX::Asset::Launcher> object and returns true 
(or throws an exception.)

=cut



sub install {
	my $self = shift;

	my $bin = $self->_get_bin();
	my $ext = $self->_get_exe() ? '.exe' : '.bat';

	# Check the script exists
	my $to = catfile( $self->_get_image_dir(), 'perl', 'bin', "$bin$ext" );
	if ( not -f $to ) {
		PDWiX::File->throw(
			file    => $to,
			message => 'File does not exist'
		);
	}

	my $icons     = $self->_get_icons();
	my $icon_type = ref $icons;
	$icon_type ||= '(undefined type)';
	if ( 'Perl::Dist::WiX::IconArray' ne $icon_type ) {
		PDWiX->throw( "Icons array is of type $icon_type, "
			  . 'not a Perl::Dist::WiX::IconArray' );
	}

	my $icon_id =
	  $self->_get_icons()
	  ->add_icon( $self->_get_icon_file($bin), "$bin$ext" );

	# Add the icon.
	$self->_add_icon(
		name         => $self->get_name(),
		filename     => $to,
		fragment     => 'StartMenuIcons',
		icon_id      => $icon_id,
		directory_id => $self->_get_directory_id(),
	);

	return 1;
} ## end sub install

sub _get_icon_file {
	my $self = shift;
	my $name = shift;

	my ( $dir, $file );

	# Start with the parent reference contained in this asset.
	my $class = ref $self->_get_parent();

	no strict 'refs'; ## no critic(ProhibitNoStrict)
	while ( defined $class and $class ne 'Moose::Object' ) {

		# Get the directory of this class's dist_dir and check for the icon.
		$dir = $class->dist_dir();
		$file = catfile( $dir, "$name.ico" );
		if ( -f $file ) {
			return $file;
		}

		# Pick up the first parent of the class, and try again.
		$class = ${"${class}::ISA"}[0];
	} ## end while ( defined $class and...)

	PDWiX::File->throw(
		message => 'File not found.',
		file    => "$name.ico"
	);

	return;

} ## end sub _get_icon_file

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

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
