package Modulino::Base;
use utf8;
use strict;
no warnings;

use v5.10.1;

use vars qw($VERSION);
use Carp;

our $VERSION = '1.001';

sub _running_under_tester { !! $ENV{CPANTEST} }

sub _running_as_app {
	my $caller = scalar caller(1);
	(defined $caller) && $caller ne 'main';
	}

# run directly
if( ! defined caller(0) ) {
	carp sprintf "You cannot run %s directly!", __PACKAGE__;
	}
# loaded from a module that was run directly
elsif( ! defined caller(1) ) {
	my @caller = caller(0);
	my $method = do {
		   if( _running_under_tester()    ) { 'test' }
		elsif( _running_as_app()          ) { 'run'  }
		else                                { undef  }
		};

	if( $caller[0]->can( $method ) ) {
		$caller[0]->$method( @ARGV );
		}
	elsif( __PACKAGE__->can( $method ) ) { # faking inheritance
		__PACKAGE__->$method( $caller[0], @ARGV )
		}
	else {
		carp "There is no $method() method defined in $caller[0]\n";
		}
	}

sub test {
	my( $class, $caller ) = @_;

	my @tests = do {
		if( $caller->can( '_get_tests' ) ) {
			$caller->_get_tests;
			}
		else {
			$class->_get_tests( $caller );
			}
		};

	require Test::More;
	Test::More::note( "Running $caller as a test" );
	foreach my $test ( @tests ) {
		Test::More::subtest( $test => sub {
			my $rc = eval { $caller->$test(); 1 };
			Test::More::diag( $@ ) unless defined $rc;
			} );
		}

	Test::More::done_testing();
	}

sub _get_tests {
	my( $class, $caller ) = @_;
	print "_get_tests class is [$class]\n";
	no strict 'refs';
	my $stub = $caller . '::';
	my @tests =
		grep { defined &{"$stub$_"}    }
		grep { 0 == index $_, '_test_' }
		keys %{ "$stub" };

	@tests;
	}

1;
