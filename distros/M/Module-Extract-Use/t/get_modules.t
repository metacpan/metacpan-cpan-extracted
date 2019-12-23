#!/usr/bin/perl
use strict;

use Test::More 1.0;
use File::Basename;
use File::Spec::Functions qw(catfile);

my $class = "Module::Extract::Use";

use_ok( $class );

my $extor = $class->new;

subtest setup => sub {
	isa_ok( $extor, $class );
	can_ok( $extor, 'get_modules' );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that doesn't exist, should fail
subtest missing => sub {
	my $not_there = 'not_there';
	ok( ! -e $not_there, "Missing file is actually missing" );

	$extor->get_modules( $not_there );
	like( $extor->error, qr/does not exist/, "Missing file give right error" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that doesn't exist, should fail
subtest non_perl => sub {
	my $non_perl = 'corpus';
	ok( -e $non_perl, "Non-perl file is actually missing" );

	my $result = $extor->get_modules( $non_perl );
	is( $result, 0, "Non-perl file returns 0 in scalar context" );

	my @results = $extor->get_modules( $non_perl );
	is( scalar @results, 0, "Non-perl file returns empty list in list context" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with this file
subtest this_file => sub {
	my $test = $0;
	ok( -e $test, "Test file is there" );

	my %modules = map { $_, 1 } $extor->get_modules( $test );
	ok( ! $extor->error, "No error for parseable file [$test]" );

	foreach my $module ( qw(Test::More File::Basename File::Spec::Functions strict) ) {
		ok( exists $modules{$module}, "Found $module" );
		}

	foreach my $module ( qw(Foo Bar::Baz) ) {
		ok( ! exists $modules{$module}, "Didn't find $module" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that has repeated use lines
# I should only get unique names
subtest repeated => sub {
	my $file = catfile( qw(corpus Repeated.pm) );
	ok( -e $file, "Test file [$file] is there" );

	my @modules = sort { $a cmp $b } $extor->get_modules( $file );
	is( scalar @modules, 3 );

	is_deeply( \@modules, [qw(constant strict warnings)] );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest rt79273 => sub {
	my $file = catfile( qw(corpus RT79273.pm) );
	ok( -e $file, "Test file [$file] is there" );

	my @modules = sort { $a cmp $b } $extor->get_modules( $file );
	is( scalar @modules, 3 );

	is_deeply( \@modules, [qw(CGI::Snapp Capture::Tiny parent)] );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest expression => sub {
	my $file = catfile( qw(corpus state_require.pm) );
	ok( -e $file, "Test file [$file] is there" );

	my @modules = sort { $a cmp $b } $extor->get_modules( $file );
	is( scalar @modules, 2 );

	is_deeply( \@modules, [qw(ConfigReader::Simple Mojo::Util)] );
	};

done_testing();
