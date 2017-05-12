#!/usr/bin/perl

# Compile-testing for PITA-Scheme

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 28;
use Cwd                       ();
use Data::GUID                ();
use File::Remove              ();
use File::Spec::Functions     (':ALL');
use PITA::Scheme::Perl5::Make ();

# Locate the injector directory
my $injector = catdir( 't', 'prepare', 'injector' );
ok( -d $injector, 'Test injector exists' );

# Create the workarea directory
my $cwd      = Cwd::cwd();
my $workarea = catdir( 't', 'prepare', 'workarea' );
File::Remove::clear( $workarea );
ok( mkdir( $workarea ), 'Created workarea' );
ok( -d $workarea, 'Test workarea exists' );





#####################################################################
# Main Testing

my $id     = Data::GUID->new->as_string;
my $scheme = PITA::Scheme::Perl5::Make->new(
	injector    => $injector,
	workarea    => $workarea,
	scheme      => 'perl5.make',
	path        => '',
	request_xml => 'request.pita',
	request_id  => $id,
);
isa_ok( $scheme, 'PITA::Scheme'              );
isa_ok( $scheme, 'PITA::Scheme::Perl5::Make' );

# Check the accessors
is( $scheme->injector, $injector, '->injector matches original'  );
is( $scheme->workarea, $workarea, '->workarea matches original'  );
ok( $scheme->request_xml, '->request_xml returns true'           );
ok( -f $scheme->request_xml, '->request_xml file exists'         );
isa_ok( $scheme->request, 'PITA::XML::Request'                );
is( $scheme->request_id, $id, 'Got expected ->request_id value' );
ok( $scheme->archive, '->archive returns true'                   );
ok( -f $scheme->archive, '->archive file exists'                 );
is( $scheme->extract_path, undef, 'No ->extract_path value yet'  );
is( scalar($scheme->extract_files), undef, 'No ->extract_files ' );
is_deeply( [ $scheme->extract_files ], [], 'No ->extract_files ' );

# Prepare the package
ok( $scheme->prepare_package, '->prepare_package runs ok' );
ok( $scheme->extract_path, '->extract_path gets set'  );
ok( -d $scheme->extract_path, '->extract_path exists' );
ok( $scheme->workarea_file('Makefile.PL'), '->workarea_file returns a value' );
like(
	$scheme->workarea_file('Makefile.PL'),
	qr/\bMakefile\.PL$/,
	'->workarea_file return a right-looking string',
);
ok(
	-f $scheme->workarea_file('Makefile.PL'),
	'Makefile.PL exists in the extract package',
);

# Prepare the environment
ok( $scheme->prepare_environment, '->prepare_environment runs ok' );
ok( -f 'Makefile.PL', 'Changed to package directory, found Makefile.PL' );
isa_ok( $scheme->platform, 'PITA::XML::Platform' );

# Prepare the report
ok( $scheme->prepare_report, '->prepare_report runs ok' );
isa_ok( $scheme->install, 'PITA::XML::Install' );
isa_ok( $scheme->report,  'PITA::XML::Report'  );
