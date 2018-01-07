use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Devel::TestHelper;
# ABSTRACT: A test helper with functions useful for various Renard distributions
$Renard::Incunabula::Devel::TestHelper::VERSION = '0.004';
use Renard::Incunabula::Common::Types qw(Dir);

classmethod test_data_directory() :ReturnType(Dir) {
	require Path::Tiny;
	Path::Tiny->import();

	if( not defined $ENV{RENARD_TEST_DATA_PATH} ) {
		die "Must set environment variable RENARD_TEST_DATA_PATH to the path for the test-data repository";
	}
	return path( $ENV{RENARD_TEST_DATA_PATH} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Devel::TestHelper - A test helper with functions useful for various Renard distributions

=head1 VERSION

version 0.004

=head1 FUNCTIONS

=head2 test_data_directory

  Renard::Incunabula::Devel::TestHelper->test_data_directory

Returns a L<Path::Class> object that points to the path defined by
the environment variable C<RENARD_TEST_DATA_PATH>.

If the environment variable is not defined, throws an error.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
