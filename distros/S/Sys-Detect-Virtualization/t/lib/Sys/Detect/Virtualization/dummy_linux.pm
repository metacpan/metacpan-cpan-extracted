package Sys::Detect::Virtualization::dummy_linux;
use Sys::Detect::Virtualization::linux;
use base qw( Sys::Detect::Virtualization::linux );

use File::Spec;

# Dummy class for testing

sub get_detectors
{
	return Sys::Detect::Virtualization::linux->get_detectors();
}

sub _check_file_contents
{
	my ($self, $glob, @rest) = @_;

	return $self->SUPER::_check_file_contents(
		File::Spec->catfile( $ENV{FAKE_DATA}, $glob ),
		@rest,
	);
}

1;
