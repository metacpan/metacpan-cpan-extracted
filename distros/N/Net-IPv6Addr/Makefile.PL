use utf8;
use ExtUtils::MakeMaker;
my $pm = 'lib/Net/IPv6Addr.pm';
my $pod = 'lib/Net/IPv6Addr.pod';
my $github = 'github.com/benkasminbullock/net-ipv6addr';
my $repo = "https://$github";
WriteMakefile(
#    'AUTHOR' => 'Tony Monroe',
    
    # This is set for documentation generation. Tony Monroe is the
    # author of the module.
    'AUTHOR' => 'Ben Bullock <bkb@cpan.org>',
    'NAME'	=> 'Net::IPv6Addr',
    'VERSION_FROM' => $pm,
    'ABSTRACT_FROM' => $pod,
    'PREREQ_PM' => { 
	'Net::IPv4Addr' => '0.10', 
	'Math::Base85' => '0.2',
	'Carp' => '0',
	'Math::BigInt' => '1.999813',
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
	    bugtracker => {
		web => "https://rt.cpan.org/Dist/Display.html?Name=Net-IPv6Addr",
	    },
	},
	x_contributors => [
	    'Jyrki Soini',
	    'Joacim Haggmark',
	    'Ben Bullock <bkb@cpan.org>',
	    'Neil Bowers <neilb@cpan.org>',
	    'Salvador Fandiño García <salva@cpan.org>',
	],
    },
    # http://matrix.cpantesters.org/?dist=Net-IPv6Addr%200.8 gives
    # 5.6.2 as valid.
    MIN_PERL_VERSION => '5.006000',
);
