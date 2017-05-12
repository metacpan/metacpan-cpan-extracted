package Modulino::Demo2;
use strict;
use utf8;

use v5.14.2;

use warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.001';

UNITCHECK {
sub _running_under_docreader {
	!! $ENV{PERLDOC}
	}

sub _running_under_tester {
	!! $ENV{HARNESS_ACTIVE}
	}

sub _running_as_app {
	defined scalar caller
	}

my $method = do {
	   if( _running_under_docreader() ) { 'doc'  } # reading docs
	elsif( _running_under_tester()    ) { 'test' } # testing
	elsif( _running_as_app()          ) { 'run'  } # running the application
	else                                { undef  } #everything else
	};

__PACKAGE__->$method(@ARGV) if defined $method;
}

=encoding utf8

=head1 NAME

Modulino::Demo - A demonstration of modulino ideas

=head1 SYNOPSIS

	use Modulino::Demo;

=head1 DESCRIPTION

=over 4

=item run

=cut

sub run {
	say "Running as program";
	}

sub _test_run {
	require Test::More;

	Test::More::pass();
	Test::More::pass();

	SKIP: {
		Test::More::skip( "These tests don't work", 2 );
		Test::More::fail();
		Test::More::fail();
		}
	}

=back

=head2 Testing

=over 4

=item test

Run all of the subroutines that start with C<_test_>. Each subroutine
is wrapped in a C<Test::More> subtest.

=cut

sub test {
	say "Running as test";

	my( $class ) = @_;
	my @tests = $class->_get_tests;

	require Test::More;

	foreach my $test ( @tests ) {
		Test::More::subtest( $test => sub {
			my $rc = eval { $class->$test(); 1 };
			Test::More::diag( $@ ) unless defined $rc;
			} );
		}
	}

sub _get_tests {
	my( $class ) = @_;
	no strict 'refs';
	my $stub = $class . '::';
	my @tests =
		grep { defined &{"$stub$_"}    }
		grep { 0 == index $_, '_test_' }
		keys %{ "$stub" };

	say "Tests are @tests";
	@tests;
	}

=back

=head2 Reading the docs

=over 4

=item doc

=cut

sub doc {
	say "Running as docs";
	require Pod::Perldoc;

	*Pod::Perldoc::program_name = sub {
		'perldoc';
		};

	Pod::Perldoc->new( args => [ __FILE__ ] )->process();
	}

sub _test_doc {
	require Test::More;
	require Test::Pod;
	require Test::Pod::Coverage;
	our $TODO;

	Test::Pod::pod_file_ok( __FILE__ );
	TODO: {
		local $TODO = "Pod::Coverage can't find the pod";
		Test::Pod::Coverage::pod_coverage_ok( __PACKAGE__ );
		}
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/modulino-demo/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
