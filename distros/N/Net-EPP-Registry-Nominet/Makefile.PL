use strict;
use warnings;
use ExtUtils::MakeMaker;

my %MF = (
	NAME             => 'Net::EPP::Registry::Nominet',
	ABSTRACT         => 'EPP client code for Nominet',
	AUTHOR           => 'Pete Houston (cpan@openstrike.co.uk)',
	LICENSE          => 'perl',
	META_MERGE       => {
		'meta-spec' => { version => 2 },
		resources   => {
			bugtracker => {
				web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-EPP-Registry-Nominet'
			},
			repository => {
				type => 'git',
				url  => 'git://gitlab.com/openstrike/nominet-epp.git',
				web  => 'https://gitlab.com/openstrike/nominet-epp',
			}
		}
	},
	MIN_PERL_VERSION => '5.8.0',
	PREREQ_PM        => {
		'Net::EPP' => '0.19',
		'Carp'     => '0',
	},
	TEST_REQUIRES    => {
		'Test::More'  => '0.41',
		'Test::Warn'  => '0.09',
		'Time::Piece' => '0',
	},
	VERSION_FROM     => 'lib/Net/EPP/Registry/Nominet.pm'
);

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

unless (exists $ENV{NOMTAG} and exists $ENV{NOMPASS}) {
	print <<EOT;

It is *highly* recommended that you set the environment variables NOMTAG
and NOMPASS to be your tag name and password respectively for the
Nominet EPP testbed prior to running "make test". Doing so allows the
full suite of tests to be run. See
https://registrars.nominet.uk/uk-namespace/registration-and-domain-management/registration-systems/epp/testbed/
for details of the testbed and how to register for it.

EOT
}
