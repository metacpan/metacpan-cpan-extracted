package t::lib::Test4;

use strict;
use Perl::Dist ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.14';
	@ISA     = 'Perl::Dist';
}





#####################################################################
# Configuration

sub app_name             { 'Test Perl'                }
sub app_ver_name         { 'Test Perl 1 alpha 1'      }
sub app_publisher        { 'Vanilla Perl Project'     }
sub app_publisher_url    { 'http://vanillaperl.org'   }
sub app_id               { 'testperl'                 }
sub output_base_filename { 'test-perl-5.10.0-alpha-1' }





#####################################################################
# Main Methods

sub new {
	return shift->SUPER::new(
		perl_version => 5100,
		portable     => 1,
		@_,
	);
}

sub trace { Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

sub install_library {
	return shift->SUPER::install_library( @_, trace => sub { 1 } );
}

sub install_distribution {
	return shift->SUPER::install_distribution( @_, trace => sub { 1 } );
}

sub install_perl_5100_bin {
	return shift->SUPER::install_perl_5100_bin( @_, trace => sub { 1 } );
}

sub install_perl_5100_toolchain {
	return shift->SUPER::install_perl_5100_toolchain( @_, trace => sub { 1 } );
}

1;
