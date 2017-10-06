use ExtUtils::MakeMaker;
my $pm = 'lib/Net/IPv6Addr.pm';
my $github = 'github.com/benkasminbullock/net-ipv6addr';
my $repo = "https://$github";
WriteMakefile(
    'AUTHOR' => 'Tony Monroe',
    'NAME'	=> 'Net::IPv6Addr',
    'VERSION_FROM' => $pm,
    'PREREQ_PM' => { 
	'Net::IPv4Addr' => '0.10', 
	'Math::Base85' => '0.2',
	'Carp' => '0',
	'Math::BigInt' => '0',
    },
    LICENSE => 'perl',
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
	},
	x_contributors => [
	    'Jyrki Soini',
	    'Joacim Haggmark',
	    'Ben Bullock <bkb@cpan.org>',
	    'Neil Bowers <neilb@cpan.org>',
	    'Salvador Fandiño García <salva@cpan.org>',
	],
	bugtracker => {
	    web => "https://rt.cpan.org/Dist/Display.html?Name=Net-IPv6Addr",
	},
    },
);
