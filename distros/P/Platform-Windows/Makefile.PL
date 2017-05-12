use 5;
use ExtUtils::MakeMaker;

unless ($ENV{PERL_PLATFORM_OVERRIDE}||($^O =~ /^(MSWin32|cygwin)$/i))
{
	warn "Requires Windows!\n";
	die "No support for OS.\n";
}

WriteMakefile(
	NAME              => 'Platform::Windows',
	VERSION_FROM      => 'lib/Platform/Windows.pm',
	PREREQ_PM         => {},
	BUILD_REQUIRES    => { "Test::More" => "0.80" },
	($] >= 5.005 ? (ABSTRACT_FROM  => 'lib/Platform/Windows.pm', AUTHOR => 'Toby Inkster <tobyink@cpan.org>') : ()),
	LICENSE           => 'perl',
	META_MERGE => {
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			homepage    => 'https://metacpan.org/release/Platform-Windows',
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Platform-Windows',
			repository  => 'https://github.com/tobyink/p5-platform',
		},
	},
);
