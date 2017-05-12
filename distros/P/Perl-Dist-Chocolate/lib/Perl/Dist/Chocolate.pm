package Perl::Dist::Chocolate;

=pod

=head1 NAME

Perl::Dist::Chocolate - Chocolate Perl for Win32 (EXPERIMENTAL)

=head1 DESCRIPTION

This is the distribution builder used to create Chocolate Perl.

=head1 Building Chocolate Perl

Unlike Strawberry, Chocolate does not have a standalone build script.

To build Chocolate Perl, run the following.

  perldist Chocolate

=cut

use 5.008;
use strict;
use Perl::Dist::Strawberry 1.07 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.07';
	@ISA     = 'Perl::Dist::Strawberry';
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'chocolateperl',
		app_name          => 'Chocolate Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\chocolate',

		# Build both exe and zip versions
		exe               => 1,
		zip               => 0,
		@_,
	);
}

# Lazily default the full name.
# Supports building multiple versions of Perl.
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human . ' Alpha 1';
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'chocolate-perl-' . $_[0]->perl_version_human . '-alpha-1';
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	die "Perl 5.8.8 is not available in Chocolate Perl";
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	# Current Padre encompasses all the stuff we care about
	$self->install_module( name => 'Padre' );

	# Install a range of the most popular modules for various tasks
	$self->install_modules( qw{
		DateTime
		Template
		POE
		Imager
		Perl::Critic
		Perl::Tidy
	} );

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Chocolate>

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
