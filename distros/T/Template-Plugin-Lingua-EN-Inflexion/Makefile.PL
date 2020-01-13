use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %MF = (
	NAME             => 'Template::Plugin::Lingua::EN::Inflexion',
	AUTHOR           => 'Pete Houston <cpan@openstrike.co.uk>',
	VERSION_FROM     => 'lib/Template/Plugin/Lingua/EN/Inflexion.pm',
	ABSTRACT_FROM    => 'lib/Template/Plugin/Lingua/EN/Inflexion.pm',
	LICENSE          => 'perl_5',
	META_MERGE       => {
		'meta-spec' => { version => 2 },
		resources   => {
			bugtracker => {
				web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Lingua-EN-Inflexion'
			},
			repository => {
				type => 'git',
				url  => 'git://gitlab.com/openstrike/template-inflexion.git',
				web  => 'https://gitlab.com/openstrike/template-inflexion',
			}
		}
	},
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.10.0',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0.41',
	},
	PREREQ_PM => {
		'Lingua::EN::Inflexion' => '0.001008',
		'Template' => '2.24',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Template-Plugin-Lingua-EN-Inflexion-*' },
);

# Extra tests
if ($ENV{RELEASE_TESTING}   ||
	$ENV{AUTOMATED_TESTING} ||
	$ENV{AUTHOR_TESTING}) {
	$MF{test} = { TESTS => 't/*.t xt/*.t' };
}

# Remove entries from the hash where version of ExtUtils::MakeMaker is
# too old to support them
if ($ExtUtils::MakeMaker::VERSION lt 6.63_03) {
	my $req = $ExtUtils::MakeMaker::VERSION lt 6.55 ?
		'PREREQ_PM' : 'BUILD_REQUIRES';
	# Move test prereqs into appropriate target
	for my $key (keys %{$MF{TEST_REQUIRES}}) {
		$MF{$req}{$key} = $MF{TEST_REQUIRES}{$key};
	}
	delete $MF{TEST_REQUIRES};
}
if ($ExtUtils::MakeMaker::VERSION lt 6.48) { delete $MF{MIN_PERL_VERSION}; }
if ($ExtUtils::MakeMaker::VERSION lt 6.46) { delete $MF{META_MERGE};       }
if ($ExtUtils::MakeMaker::VERSION lt 6.31) { delete $MF{LICENSE};          }

WriteMakefile (%MF);
