use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name         => 'OWL-Simple',
    module_name	      => 'OWL::Simple::Parser',
    license             => 'gpl',
    dist_author         => q{Tomasz Adamusiak <tomasz@cpan.org>},
    dist_version => '0.51',
    dist_abstract => 'A set of modules and scripts for parsing OWL ontologies',
    configure_requires => { 
    	'Module::Build' => 0.38 
    },
    build_requires => {
    	'Test::More' => 0,
    	'File::Temp' => 0,
    },
    requires => {
		'Moose' => '0.89',
		'Log::Log4perl' => 0,
		'List::Util' => 0,
		'XML::Parser' => '2.34',
    },
    recommends => {
    	'IO::File' => 0,
		'IO::Handle' => 0,
		'Getopt::Long' => 0,
    	'GO::Parser' => 0,
    	'Benchmark' => 0,
		#'Text::LevenshteinXS' => 0,
    },
    #script_files        => ['scripts/similarity_match.pl'],
    add_to_cleanup      => [ 'OWL-Simple-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
