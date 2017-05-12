use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME => 'OAuth::Consumer',
		AUTHOR => 'Mathias Kende <mathias@cpan.org>',
		VERSION_FROM => 'lib/OAuth/Consumer.pm',
		ABSTRACT_FROM => 'lib/OAuth/Consumer.pm',
		#README_FROM => 'lib/OAuth/Consumer.pm',
		LICENSE => 'perl',
		MIN_PERL_VERSION => '5.8.0',
		CONFIGURE_REQUIRES => {
				'ExtUtils::MakeMaker' => 6.3002,
			},
		BUILD_REQUIRES => {
				'Test::Subs' => 0.07,
				'LWP::UserAgent' => 0,
				'WWW::Mechanize' => 0
			},
		PREREQ_PM => {
				'Carp' => 0,
				'LWP::Authen::OAuth' => 0,
				'IO::Socket::INET' => 0,
				'URI::Escape' => 0,
				'HTTP::Response' => 0,
				'Encode' => 0,
				'HTML::Entities' => 0,
    		},
	);

