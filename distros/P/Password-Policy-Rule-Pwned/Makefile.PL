use ExtUtils::MakeMaker;
use strict;
use warnings;
require 5.6.0;

my $release = '0.03';
my %MF = (
	NAME            => 'Password::Policy::Rule::Pwned',
	ABSTRACT        => 'Compare text to known pwned passwords list',
	AUTHOR          => 'Pete Houston (cpan@openstrike.co.uk)',
	LICENSE         => 'perl',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			bugtracker => {
				web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Password-Policy-Rule-Pwned'
			},
			repository => {
				type => 'git',
				url  => 'git://gitlab.com/openstrike/password-pwned.git',
				web  => 'https://gitlab.com/openstrike/password-pwned',
			},
		},
		provides => {
			'Password::Policy::Rule::Pwned' => {
				file    => 'lib/Password/Policy/Rule/Pwned.pm',
				version => $release
			},
			'Password::Policy::Exception::Pwned' => {
				file    => 'lib/Password/Policy/Exception/Pwned.pm',
				version => $release
			},
			'Password::Policy::Exception::PwnedError' => {
				file    => 'lib/Password/Policy/Exception/PwnedError.pm',
				version => $release
			},
		},
	},
	MIN_PERL_VERSION => '5.8.0',
	PREREQ_PM        => {
		'Password::Policy'     => '0.06',
		'LWP'                  => '6.02',
		'LWP::Protocol::https' => '6.02',
		'Digest::SHA'          => '0',
		'String::Multibyte'    => '0',
	},
	TEST_REQUIRES    => {
		'Test::More'	  => '0.84',
		'Test::Exception' => '0.38',
		'Encode'          => '0',
	},
	VERSION_FROM     => 'lib/Password/Policy/Rule/Pwned.pm',
	'dist'           => {
		COMPRESS => 'gzip -9f', 
		SUFFIX   => 'gz'
	}
);

# Extra tests
if ($ENV{RELEASE_TESTING}   ||
	$ENV{AUTHOR_TESTING}) {
	$MF{test} = { TESTS => 't/*.t xt/*/*.t' };
	my $req = $MF{META_MERGE}{prereqs}{test}{requires};
	$req->{'Test::Vars'}             = '0.12';
	$req->{'Test::Kwalitee'}         = '1.28';
	$req->{'Test::DistManifest'}     = '1.014';
	$req->{'Test::Version'}          = '2.09';
	$req->{'Test::NewVersion'}       = '0.003';
	$req->{'Test::MinimumVersion'}   = '0.101082';
}

if ($ExtUtils::MakeMaker::VERSION lt 6.64) {
	if ($ExtUtils::MakeMaker::VERSION ge 6.55) {
		$MF{BUILD_REQUIRES} = $MF{TEST_REQUIRES};
	}
	delete $MF{TEST_REQUIRES};
}
if ($ExtUtils::MakeMaker::VERSION lt 6.55) { delete $MF{BUILD_REQUIRES};   }
if ($ExtUtils::MakeMaker::VERSION lt 6.48) { delete $MF{MIN_PERL_VERSION}; }
if ($ExtUtils::MakeMaker::VERSION lt 6.46) { delete $MF{META_MERGE};       }
if ($ExtUtils::MakeMaker::VERSION lt 6.31) { delete $MF{LICENSE};          }
WriteMakefile (%MF);

print <<End_of_Text;

Now do the following to install Password::Policy::Rule::Pwned:

    % make
    % make test
    % make install

Parts of the test suite will call the actual API at
https://api.pwnedpasswords.com/range/ unless the environment variable
NO_NETWORK_TESTING is set to a true value.

End_of_Text
