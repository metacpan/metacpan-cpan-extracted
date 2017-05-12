use 5;
use ExtUtils::MakeMaker;

unless ($ENV{PERL_PLATFORM_OVERRIDE}||($^O =~ /^(Linux|.*BSD.*|.*UNIX.*|Darwin|Solaris|SunOS|Haiku|Next|dec_osf|svr4|sco_sv|unicos.*|.*x)$/i))
{
	warn "Requires Unix!\n";
	die "No support for OS.\n";
}

WriteMakefile(
	NAME              => 'Platform::Unix',
	VERSION_FROM      => 'lib/Platform/Unix.pm',
	PREREQ_PM         => {},
	BUILD_REQUIRES    => { "Test::More" => "0.80" },
	($] >= 5.005 ? (ABSTRACT_FROM  => 'lib/Platform/Unix.pm', AUTHOR => 'Toby Inkster <tobyink@cpan.org>') : ()),
	LICENSE           => 'perl',
	META_MERGE => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			homepage    => 'https://metacpan.org/release/Platform-Unix',
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Platform-Unix',
			repository  => 'https://github.com/tobyink/p5-platform',
		},
	},
);
