use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'MyCPAN::Indexer',
	'ABSTRACT'     => 'Index a Perl distribution',
	'VERSION_FROM' => 'lib/Indexer.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Archive::Extract'                 => '0', # 0.32 when it's available
		'Archive::Tar'                     => '0',
		'ConfigReader::Simple'             => '0',
		'Data::UUID'                       => '0',
		'Distribution::Guess::BuildSystem' => '0.11',
		'File::Find'                       => '0',
		'File::Find::Closures'             => '0',
		'Log::Log4perl'                    => '0',
		'Digest::MD5'                      => '0',
		'Module::Extract::Namespaces'      => '0.14',
		'Module::Extract::Use'             => '0.13',
		'Module::Extract::VERSION'         => '0.13',
		'Parallel::ForkManager'            => '0',
		'Probe::Perl'                      => '0',
		'Test::More'                       => '0',
		'Test::Output'                     => '0.13',
		'YAML'                             => '0',
		'CPAN::PackageDetails'             => '0.21',
		'CPAN::Checksums'                  => '0',
		},

	'PM'           => {
		'lib/Reporter/Base.pm'       => '$(INST_LIBDIR)/Indexer/Reporter/Base.pm',
		'lib/Reporter/AsYAML.pm'     => '$(INST_LIBDIR)/Indexer/Reporter/AsYAML.pm',

		'lib/Interface/Text.pm'      => '$(INST_LIBDIR)/Indexer/Interface/Text.pm',
		'lib/Interface/Curses.pm'    => '$(INST_LIBDIR)/Indexer/Interface/Curses.pm',
		'lib/Interface/Tk.pm'        => '$(INST_LIBDIR)/Indexer/Interface/Tk.pm',

		'lib/Dispatcher/Parallel.pm' => '$(INST_LIBDIR)/Indexer/Dispatcher/Parallel.pm',
		'lib/Dispatcher/Serial.pm'   => '$(INST_LIBDIR)/Indexer/Dispatcher/Serial.pm',

		'lib/Indexer.pm'             => '$(INST_LIBDIR)/Indexer.pm',
		'lib/NullTester.pm'          => '$(INST_LIBDIR)/Indexer/NullTester.pm',
		'lib/Queue.pm'               => '$(INST_LIBDIR)/Indexer/Queue.pm',
		'lib/TestCensus.pm'          => '$(INST_LIBDIR)/Indexer/TestCensus.pm',
		'lib/Tutorial.pm'            => '$(INST_LIBDIR)/Indexer/Tutorial.pm',
		'lib/Worker.pm'              => '$(INST_LIBDIR)/Indexer/Worker.pm',
		'lib/Coordinator.pm'         => '$(INST_LIBDIR)/Indexer/Coordinator.pm',
		'lib/Component.pm'           => '$(INST_LIBDIR)/Indexer/Component.pm',
		'lib/Notes.pm'               => '$(INST_LIBDIR)/Indexer/Notes.pm',
		
		'lib/App/Indexer.pm'         => '$(INST_LIBDIR)/App/BackPAN/Indexer.pm',
		},

	'MAN3PODS'     => {},

	clean  => { FILES    => q|MyCPAN-Indexer-*| },
    (
    ( $ExtUtils::MakeMaker::VERSION ge '6.46' )
        ? (META_MERGE => {
            resources => {
                homepage    => 'http://github.com/briandfoy/mycpan-indexer/tree/master',
                repository  => 'git://github.com/briandfoy/mycpan-indexer.git',
            }
        })
        : ()
    )
	);
