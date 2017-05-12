#!/usr/bin/perl

# Unit tests for the PITA::XML::Platform class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 40;
use Test::XML;
use Config           ();
use PITA::XML        ();
use XML::SAX::Writer ();

my $XMLNS = PITA::XML->XMLNS;

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

sub driver_new {
	my $driver = PITA::XML::SAXDriver->new;
	isa_ok( $driver, 'PITA::XML::SAXDriver' );
	return $driver;
}

sub driver_is {
	my ($driver, $string, $message) = @_;
	my $output = $driver->Output;

	# Clean up the expected string
	chomp $string;
	$string =~ s/>\n</></g;

	# Compare the two
	is_xml( $$output, $string, $message );
}





#####################################################################
# Prepare

# Check the normal way we make output writers
my $output = '';
my $writer = XML::SAX::Writer->new( Output => \$output );
isa_ok( $writer,            'XML::Filter::BufferText' );
isa_ok( $writer->{Handler}, 'XML::SAX::Writer::XML'   );

# Get a platform object
isa_ok( PITA::XML::Platform->autodetect_perl5,
	'PITA::XML::Platform' );

# Check we can make a basic driver
driver_new();





#####################################################################
# Test the XML Support Methods

SCOPE: {
	# Test the _element hash
	my $driver  = driver_new();
	my $element = $driver->_element( 'foo' );
	is_deeply( $element, {
		Name         => 'foo',
		#Prefix       => '',
		#LocalName    => 'foo',
		#NamespaceURI => 'http://ali.as/xml/schema/pita-xml/'
		#	. $PITA::XML::VERSION,
		Attributes   => {},
		}, 'Basic _element call matches expected' );
}





SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create an undef tag
	$driver->_undef;

	$driver->end_document( {} );
	driver_is( $driver, <<END_XML, '->_undef works as expected' );
<?xml version='1.0' encoding='UTF-8'?><null xmlns='$XMLNS' />
END_XML
		
}





my $platform = PITA::XML::Platform->autodetect_perl5;
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Test a cut-down version of a platform object
	isa_ok( $platform, 'PITA::XML::Platform' );
	$platform->{scheme} = 'perl5';
	$platform->{path}   = 'PATH';
	$platform->{env}    = { foo => 'FOO', bar => '', baz => undef };
	$platform->{config} = { foo => 'FOO', bar => undef, baz => '' };
	$driver->_parse_platform( $platform );

	$driver->end_document( {} );
	my $platform_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<platform xmlns='$XMLNS'>
<scheme>perl5</scheme>
<path>PATH</path>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
END_XML

	driver_is( $driver, $platform_string, '->_parse_platform works as expected' );	
}





my $file = PITA::XML::File->new(
	filename  => 'Foo-Bar-0.01.tar.gz',
	digest    => 'MD5.5cf0529234bac9935fc74f9579cc5be8',
	);

SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $file, 'PITA::XML::File' );
	$driver->_parse_file( $file );

	$driver->end_document( {} );	
	my $request_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<file xmlns='$XMLNS'>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.5cf0529234bac9935fc74f9579cc5be8</digest>
</file>
END_XML

	driver_is( $driver, $request_string, '->_parse_file works as expected' );	
}




my $request = PITA::XML::Request->new(
	scheme    => 'perl5',
	distname  => 'Foo-Bar',
	file      => $file,
	authority => 'cpan',
	authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
	);
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $request, 'PITA::XML::Request' );
	$driver->_parse_request( $request );

	$driver->end_document( {} );	
	my $request_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<request xmlns='$XMLNS'>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<file>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.5cf0529234bac9935fc74f9579cc5be8</digest>
</file>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
END_XML

	driver_is( $driver, $request_string, '->_parse_request works as expected' );	
}





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
- File::Spec              ...loaded. (3.11 >= 0.80)
- Test::More              ...loaded. (0.62 >= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 >= 101.060501)
- Params::Util            ...loaded. (0.07 >= 0.07)
- File::ShareDir          ...loaded. (0.02 >= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 >= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 >= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::XML
END_STDOUT
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create the command object
	isa_ok( $command, 'PITA::XML::Command' );
	$driver->_parse_command( $command );

	$driver->end_document( {} );
	my $command_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<command xmlns='$XMLNS'>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-XML/inc/Module/Install.pm
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
- File::Spec              ...loaded. (3.11 &gt;= 0.80)
- Test::More              ...loaded. (0.62 &gt;= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 &gt;= 101.060501)
- Params::Util            ...loaded. (0.07 &gt;= 0.07)
- File::ShareDir          ...loaded. (0.02 &gt;= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 &gt;= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 &gt;= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::XML
</stdout>
<stderr />
</command>
END_XML

	driver_is( $driver, $command_string, '->_parse_command works as expected' );	
}





# Create the command object
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
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $test, 'PITA::XML::Test' );
	$driver->_parse_test( $test );

	$driver->end_document( {} );
	my $test_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<test xmlns='$XMLNS' language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
END_XML

	driver_is( $driver, $test_string, '->_parse_test works as expected' );	
}




# Create a single install
my $install = PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	);
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $install,           'PITA::XML::Install'  );
	isa_ok( $install->request,  'PITA::XML::Request'  );
	isa_ok( $install->platform, 'PITA::XML::Platform' );
	$driver->_parse_install( $install );

	$driver->end_document( {} );
	my $install_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<install xmlns='$XMLNS'>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<file>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.5cf0529234bac9935fc74f9579cc5be8</digest>
</file>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<scheme>perl5</scheme>
<path>PATH</path>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
</install>
END_XML

	driver_is( $driver, $install_string, '->_parse_install works as expected' );	
}




# Add the command and test to the install and try again
ok( $install->add_test( $test ),       '->add_test returned true'    );
ok( $install->add_command( $command ), '->add_command returned true' );
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_install( $install );

	$driver->end_document( {} );
	my $install_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<install xmlns='$XMLNS'>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<file>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.5cf0529234bac9935fc74f9579cc5be8</digest>
</file>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<scheme>perl5</scheme>
<path>PATH</path>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
<command>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-XML/inc/Module/Install.pm
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
- File::Spec              ...loaded. (3.11 &gt;= 0.80)
- Test::More              ...loaded. (0.62 &gt;= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 &gt;= 101.060501)
- Params::Util            ...loaded. (0.07 &gt;= 0.07)
- File::ShareDir          ...loaded. (0.02 &gt;= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 &gt;= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 &gt;= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::XML
</stdout>
<stderr />
</command>
<test language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
</install>
END_XML

	driver_is( $driver, $install_string, '->_parse_install works as expected' );	
}




# Create a new report
my $report = PITA::XML::Report->new;
isa_ok( $report, 'PITA::XML::Report' );
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_report( $report );

	$driver->end_document( {} );
	my $report_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<report xmlns='$XMLNS' />
END_XML

	driver_is( $driver, $report_string,
		'->_parse_report works as expected' );
}




# Add an install report to the file
ok( $report->add_install( $install ), '->add_install returns ok' );
my $report_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<report xmlns='$XMLNS'>
<install>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<file>
<filename>Foo-Bar-0.01.tar.gz</filename>
<digest>MD5.5cf0529234bac9935fc74f9579cc5be8</digest>
</file>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<scheme>perl5</scheme>
<path>PATH</path>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
<command>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-XML/inc/Module/Install.pm
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
- File::Spec              ...loaded. (3.11 &gt;= 0.80)
- Test::More              ...loaded. (0.62 &gt;= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 &gt;= 101.060501)
- Params::Util            ...loaded. (0.07 &gt;= 0.07)
- File::ShareDir          ...loaded. (0.02 &gt;= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 &gt;= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 &gt;= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::XML
</stdout>
<stderr />
</command>
<test language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
</install>
</report>
END_XML

SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_report( $report );
	$driver->end_document( {} );
	driver_is( $driver, $report_string,
		'->_parse_report works as expected' );
}



# Clean up the expected string
chomp $report_string;
$report_string =~ s/>\n</></g;

# Try the normal way
my $string = '';
ok( $report->write( \$string ), '->write returns true for report' );
is_xml( $string, $report_string, '->write outputs the expected XML' );
