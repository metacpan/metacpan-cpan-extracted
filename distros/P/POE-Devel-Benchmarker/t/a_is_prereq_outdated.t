#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	# can we load YAML?
	eval "use YAML";
	if ( $@ ) {
		plan skip_all => 'YAML is necessary to check META.yml for prerequisites!';
	}

	# can we load CPANPLUS?
	eval "use CPANPLUS::Backend";
	if ( $@ ) {
		plan skip_all => 'CPANPLUS is necessary to check module versions!';
	}

	# can we load version.pm?
	eval "use version";
	if ( $@ ) {
		plan skip_all => 'version.pm is necessary to compare versions!';
	}

	# does META.yml exist?
	if ( -e 'META.yml' and -f _ ) {
		load_yml( 'META.yml' );
	} else {
		# maybe one directory up?
		if ( -e '../META.yml' and -f _ ) {
			load_yml( '../META.yml' );
		} else {
			plan skip_all => 'META.yml is missing, unable to process it!';
		}
	}
}

# main entry point
sub load_yml {
	# we'll load a file
	my $file = shift;

	# okay, proceed to load it!
	my $data;
	eval {
		$data = YAML::LoadFile( $file );
	};
	if ( $@ ) {
		plan skip_all => "Unable to load $file => $@";
	} else {
		note( "Loaded $file, proceeding with analysis" );
	}

	# massage the data
	$data = $data->{'requires'};
	delete $data->{'perl'} if exists $data->{'perl'};

	# FIXME shut up warnings ( eval's fault, blame it! )
	require version;

	# init the backend ( and set some options )
	my $cpanconfig = CPANPLUS::Configure->new;
	$cpanconfig->set_conf( 'verbose' => 0 );
	$cpanconfig->set_conf( 'no_update' => 1 );
	my $cpanplus = CPANPLUS::Backend->new( $cpanconfig );

	# silence CPANPLUS!
	{
		no warnings 'redefine';
		eval "sub Log::Message::Handlers::cp_msg { return }";
		eval "sub Log::Message::Handlers::cp_error { return }";
	}

	# Okay, how many prereqs do we have?
	plan tests => scalar keys %$data;

	# analyze every one of them!
	foreach my $prereq ( keys %$data ) {
		check_cpan( $cpanplus, $prereq, $data->{ $prereq } );
	}
}

# checks a prereq against CPAN
sub check_cpan {
	my $backend = shift;
	my $prereq = shift;
	my $version = shift;

	# check CPANPLUS
	my $module = $backend->parse_module( 'module' => $prereq );
	if ( defined $module ) {
		# okay, for starters we check to see if it's version 0 then we skip it
		if ( $version eq '0' ) {
			ok( 1, "Skipping '$prereq' because it is specified as version 0" );
			return;
		}

		# Does the prereq have funky characters that we're unable to process now?
		if ( $version =~ /[<>=,!]+/ ) {
			# FIXME simplistic style of parsing
			my @versions = split( ',', $version );

			# sort them by version, descending
			s/[\s<>=!]+// for @versions;
			@versions = sort { $b <=> $a }
				map { version->new( $_ ) } @versions;

			# pick the highest version to use as comparison
			$version = $versions[0];
		}

		# convert both objects to version objects so we can compare
		$version = version->new( $version ) if ! ref $version;
		my $cpanversion = version->new( $module->version );

		# check it!
		is( $cpanversion, $version, "Comparing '$prereq' to CPAN version" );
	} else {
		ok( 0, "Warning: '$prereq' is not found on CPAN!" );
	}

	return;
}
