#!/usr/bin/perl

# Round-trip from an object to XML and back again

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More   tests => 35;
use Params::Util '_INSTANCE';
use PITA::XML ();

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}





#####################################################################
# Round-Testing Function

sub round_trip_ok {
	my $report = _INSTANCE(shift, 'PITA::XML::Report')
		or die "Did not pass a PITA::XML::Report to round_trip_ok";
	my $name   = $_[0] ? "$_[0]: " : '';


	# Save the Report object
	my $output = '';
	ok( $report->write( \$output ), "${name}->write(SCALAR) returns true" );


	# Did we generate an XML document
	like( $output,

		qr{^
			<\?xml   .+
			(?:
				</report  \s*  >
				|
				<report[^<>]+/>
			)
		$}sx,
		"${name}PITA-XML is written" );



	SKIP: {
		# Load
		my $report2 = eval { PITA::XML::Report->read( \$output ) };
		diag($@) if $@;
		isa_ok( $report2, 'PITA::XML::Report' );

		unless ( $report2 ) {
			skip("${name}Parsing failed, skipping comparison check", 1);
		}

		# Compare
		is_deeply( $report, $report2,
			"${name}PITA::XML::Report object round-trips correctly" );
	}
}





#####################################################################
# Create the Report components

my $platform = PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => '/usr/bin/perl',
	env    => { abc => 'def' },
	config => { foo => undef },
	);
isa_ok( $platform, 'PITA::XML::Platform' );

my $request = PITA::XML::Request->new(
	scheme    => 'perl5',
	distname  => 'Foo-Bar',
	file      => PITA::XML::File->new(
		filename  => 'Foo-Bar-0.01.tar.gz',
		digest    => 'MD5.5cf0529234bac9935fc74f9579cc5be8',
		),
	authority => 'cpan',
	authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
	);
isa_ok( $request, 'PITA::XML::Request' );

my $command = PITA::XML::Command->new(
	cmd    => 'perl Makefile.PL',
	stderr => \"",
	stdout => \<<'END_STDOUT' );
include /home/adam/cpan2/trunk/PITA-XML/inc/Module/Install.pm
include inc/Module/Install/Metadata.pm
include inc/Module/Install/Base.pm
include inc/Module/Install/Share.pm
include inc/Module/Install/Makefile.pm
include inc/Module/Install/AutoInstall.pm
include inc/Module/Install/Include.pm
include inc/Module/AutoInstall.pm
*** Module::AutoInstall version 1.00
*** Checking for dependencies...
[Core Features]
- File::Spec ...loaded. (3.11 >= 0.80)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::XML
END_STDOUT

isa_ok( $command, 'PITA::XML::Command' );

my $test = PITA::XML::Test->new(
	name     => 't/01_main.t',
	stderr   => \"",
	exitcode => 0,
	stdout   => \<<'END_STDOUT' );
1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
END_STDOUT
isa_ok( $test, 'PITA::XML::Test' );

my $install = PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	);
isa_ok( $install, 'PITA::XML::Install' );
ok( $install->add_command( $command ), '->add_command returned true' );
ok( $install->add_test( $test ), '->add_test returned true' );





#####################################################################
# Test a Simple Report

my $report = PITA::XML::Report->new;
isa_ok( $report, 'PITA::XML::Report' );
round_trip_ok( $report, 'Empty' );





#####################################################################
# Repeat with a relatively simple Install

ok( $report->add_install( $install ), '->add_install returns ok' );
round_trip_ok( $report, 'Simple' );





#####################################################################
# Test a Guest object

# Start with the most simple possible guest
my $file = PITA::XML::File->new(
	filename => 'foo.img',
	digest   => 'MD5.01234567890123456789012345678901',
	);
isa_ok( $file, 'PITA::XML::File' );

my $guest = PITA::XML::Guest->new(
	driver   => 'ImageTest',
	memory   => 256,
	snapshot => 1,
	);
isa_ok( $guest, 'PITA::XML::Guest' );
ok( $guest->add_file( $file ), 'Added file' );

SCOPE: {
	# Save the Report object
	my $output = '';
	ok( $guest->write( \$output ), "Guest->write(SCALAR) returns true" );
	like( $output, qr/\<guest xmlns/, 'Wrote XML' );

	# Read it back in
	my $guest2 = eval {
		PITA::XML::Guest->read(
			\$output,
			base => $guest->base,
		)
	};
	is( $@, '', 'Parses back in again without error' );
	isa_ok( $guest2, 'PITA::XML::Guest' );
	is_deeply( $guest2, $guest, 'Round-trips ok' );
}

# Repeat this time with a platform
ok( $guest->add_platform( $platform ), 'Added platform' );
is( scalar($guest->platforms), 1, '->platforms returns 1' );
isa_ok( ($guest->platforms)[0], 'PITA::XML::Platform' );
dies_like( sub { $guest->add_platform('PITA::XML::Platform') },
	qr/Did not provide a PITA::XML::Platform object/,
	'->add_platform(bad) died as expected',
);

SCOPE: {
	# Save the Report object
	my $output = '';
	ok( $guest->write( \$output ), "Guest->write(SCALAR) returns true" );
	like( $output, qr/\<guest xmlns/, 'Wrote XML' );
	like( $output, qr/\<platform/, 'Contains a platform' );

	# Read it back in
	my $guest2 = eval {
		PITA::XML::Guest->read(
			\$output,
			base => $guest->base,
		)
	};
	is( $@, '', 'Parses back in again without error' );
	isa_ok( $guest2, 'PITA::XML::Guest' );
	is_deeply( $guest2, $guest, 'Round-trips ok' );	
}


exit(0);
