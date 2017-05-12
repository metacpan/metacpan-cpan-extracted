package t::lib::Test2;

use strict;
use Perl::Dist ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.14';
	@ISA     = 'Perl::Dist';
}





#####################################################################
# Configuration

sub app_name             { 'Test Perl'               }
sub app_ver_name         { 'Test Perl 1 alpha 1'     }
sub app_publisher        { 'Vanilla Perl Project'    }
sub app_publisher_url    { 'http://vanillaperl.org'  }
sub app_id               { 'testperl'                }
sub output_base_filename { 'test-perl-5.8.8-alpha-1' }





#####################################################################
# Main Methods

sub new {
	return shift->SUPER::new(
		perl_version => 588,
		@_,
	);
}

sub run {
	my $self = shift;

	# Install the core binaries
	$self->install_c_toolchain;

	# Install the extra libraries
	$self->install_c_libraries;

	# Install Perl 5.8.8
	$self->install_perl_588;

	# Install a test distro
	$self->install_distribution(
		name => 'ADAMK/Config-Tiny-2.12.tar.gz',
	);

	return 1;
}

sub trace { Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_distribution {
	return shift->SUPER::install_distribution( @_, trace => sub { 1 } );
}

sub install_file {
	return shift->SUPER::install_file( @_, trace => sub { 1 } );
}

sub install_perl_588_bin {
	return shift->SUPER::install_perl_588_bin( @_, trace => sub { 1 } );
}

sub install_perl_588_toolchain {
	return shift->SUPER::install_perl_588_toolchain( @_, trace => sub { 1 } );
}

1;
