use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME => 'String::Replace',
		AUTHOR => 'Mathias Kende <mathias@cpan.org>',
		VERSION_FROM => 'lib/String/Replace.pm',
		ABSTRACT_FROM => 'lib/String/Replace.pm',
		#README_FROM => 'lib/String/Replace.pm',
		LICENSE => 'perl',
		MIN_PERL_VERSION => '5.8.0',
		CONFIGURE_REQUIRES => {
				'ExtUtils::MakeMaker' => 6.3002,
			},
		BUILD_REQUIRES => {
				'Test::Subs' => 0,
				'Tie::Scalar' => 0
			},
		PREREQ_PM => {
				'Exporter' => 0,
				'Carp' => 0,
				'Scalar::Util' => 0,
				'List::MoreUtils' => 0
    		},
	);

