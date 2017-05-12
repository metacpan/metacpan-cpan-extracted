use ExtUtils::MakeMaker 6.48;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	        => 'PPI::App::ppi_version::BDFOY',
	'ABSTRACT_FROM' => 'lib/PPI/App/ppi_version/BDFOY.pm',
	'VERSION_FROM'  => 'lib/PPI/App/ppi_version/BDFOY.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'    => { 
		'File::Find::Rule::Perl' => '0',
		'File::Find::Rule'       => '0',
		'PPI::App::ppi_version'  => '0',
		'PPI::Document'          => '0',
		'PPI'                    => '0',
		'Term::ANSIColor'        => '0',		
		'Test::More'             => '0',
		'version'                => '0',
		},

	'MIN_PERL_VERSION' => 5.008,

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/PPI-App-ppi_version-BDFOY.git',
				web  => 'https://github.com/briandfoy/PPI-App-ppi_version-BDFOY',
				},
			},
		},


	'EXE_FILES'     => [ qw(script/ppi_version) ],

	'clean'  => { FILES    => q|PPI-App-ppi_version-BDFOY-*| },
	);
