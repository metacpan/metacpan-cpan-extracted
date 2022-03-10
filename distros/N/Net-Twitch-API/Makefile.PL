
use ExtUtils::MakeMaker;

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Net::Twitch::API',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT_FROM	=> 'lib/Net/Twitch/API.pm',
	VERSION_FROM	=> 'lib/Net/Twitch/API.pm',
	LICENSE	=> 'artistic_2',
	PREREQ_PM	=> {
		"JSON"			=> 0,
		"WebService::Simple"	=> 0,
	},
	META_MERGE	=> {
		'meta-spec'	=> { version => 2 },
		resources	=> {
			repository => {
				url => 'https://github.com/clipland/net-twitch-api.git',
				web => 'https://github.com/clipland/net-twitch-api',
				type=> 'git',
			},
			bugtracker => 'https://github.com/clipland/net-twitch-api/issues'
		},
	},
	dist => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	realclean => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	MIN_PERL_VERSION	=> 5.004, # nothing special in this dist, let's just make CPANTS happier
);
