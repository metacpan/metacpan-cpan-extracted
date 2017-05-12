package Perl::Dist::WiX::Asset::Website;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Website - Website link asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Website version 1.500.

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Website->new(
      parent     => $dist,
	  name       => 'Strawberry Perl Website',
	  url        => 'http://strawberryperl.com/',
	  icon_file  => 'C:\icons\strawberry.ico',
	  icon_index => 1,
  );

=head1 DESCRIPTION

This asset creates a website link in the Start Menu using the parameters 
given.

=cut

use 5.010;
use Moose;
use MooseX::Types::Moose qw( Str Int Maybe );
use File::Spec::Functions qw( catfile splitpath );
use English qw( -no_match_vars );

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

with 'Perl::Dist::WiX::Role::Asset';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Website> object.

It inherits all the params described in the 
L<< Perl::Dist::WiX::Role::Asset->new()|Perl::Dist::WiX::Role::Asset/new >> 
method documentation, and adds some additional params.

=head3 name

The required C<name> parameter is the name of the link on the Start Menu, 
and also becomes the name of the .url file in the C<win32> directory under 
the image location.

=cut

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);



=head3 url

The required C<url> parameter is the website to link to.

=cut



has url => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_url',
	required => 1,
);



=head3 directory_id

The optional C<directory_id> parameter is the ID of the Start Menu
directory (or subdirectory of that entry) used by the distribution.

Defaults to 'App_Menu_Websites', which puts the shortcut in the 
'Related Websites' subdirectory of the Start Menu directory used
by the distribution. 

=cut



has directory_id => (
	is      => 'bare',
	isa     => Str,
	reader  => '_get_directory_id',
	default => 'D_App_Menu_Websites',
);



=head3 icon_file

The optional C<icon_file> parameter is the file that contains the icon 
for the Start Menu entry.

Defaults to undef, which allows Windows to use its default icon for 
websites.

=cut



has icon_file => (
	is      => 'bare',
	isa     => Str,
	reader  => '_get_icon_file',
	default => undef,
);



=head3 icon_index

The optional C<icon_index> parameter is the index within a .dll file 
containing multiple icons of the icon to use.

This defaults to 1, meaning the first icon in the file, if C<icon_file> 
is set, and udenf if it is not.

=cut



has icon_index => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_icon_index',
	lazy    => 1,
	default => sub { defined shift->_get_icon_file() ? 1 : undef; },
);



has _icon_file_to => (
	is       => 'bare',
	isa      => Str,
	reader   => '_get_icon_file_to',
	lazy     => 1,
	init_arg => undef,
	builder  => '_build_icon_file_to',
);



sub _build_icon_file_to {
	my $self = shift;
	my $file = $self->_get_icon_file();
	if ( defined $file ) {
		( undef, undef, $file ) = splitpath( $file, 0 );
		$file = catfile( $self->_get_image_dir(), 'win32', $file );
		if ( !-f $file ) {
			$self->_copy( $self->_get_icon_file(), $file );
		}
		return $file;
	} else {
		## no critic (ProhibitExplicitReturnUndef)
		return undef;
	}
} ## end sub _build_icon_file_to



=head2 install

The install method installs the website link described by the
B<Perl::Dist::WiX::Asset::Website> object and returns true.

=cut

sub install {
	my $self = shift;

	# Create the file.
	my $name = $self->_get_name();
	my $filename = catfile( $self->_get_image_dir(), 'win32', "$name.url" );
	my $website;
	open $website, q{>}, $filename
	  or PDWiX->throw("open($filename): $OS_ERROR");
	print {$website} $self->_content()
	  or PDWiX->throw("print($filename): $OS_ERROR");
	close $website or PDWiX->throw("close($filename): $OS_ERROR");

	# Add the file.
	$self->_add_file(
		source   => $filename,
		fragment => 'Win32Extras'
	);

	# Add the icon.
	my $icon_id =
	  $self->_get_icons()->add_icon( $self->_get_icon_file(), $filename );
	$self->_add_icon(
		name         => $name,
		filename     => $filename,
		fragment     => 'Icons',
		icon_id      => $icon_id,
		directory_id => $self->_get_directory_id(),
	);
	$self->_add_file(
		source   => $self->_get_icon_file_to(),
		fragment => 'Win32Extras'
	);

	return 1;
} ## end sub install


# Assembles the content of the .url file.
sub _content {
	my $self = shift;

	my @content = "[InternetShortcut]\n";
	push @content, 'URL=' . $self->_get_url();
	my $file = $self->_get_icon_file_to();
	if ( defined $file ) {
		push @content, 'IconFile=' . $file;
	}
	my $index = $self->_get_icon_index();
	if ( defined $index ) {
		push @content, 'IconIndex=' . $index;
	}
	return join q{}, map {"$_\n"} @content;
} ## end sub _content

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

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
