package t::lib::Test1;

use strict;
use Perl::Dist::Inno;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.14';
	@ISA     = 'Perl::Dist::Inno';
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

	# Just install a single binary
	$self->checkpoint_task( install_dmake => 1 );

	return 1;
}

sub trace { 1 } # Test::More::diag($_[1]) }

sub install_binary {
	return shift->SUPER::install_binary( @_, trace => sub { 1 } );
}

1;
