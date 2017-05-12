use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Net::TacacsPlus',
	VERSION_FROM => 'lib/Net/TacacsPlus.pm', # finds $VERSION
	PREREQ_PM    => {
		Digest::MD5           => 0,
		Carp::Clan            => 0,
		IO::Socket            => 0,
		Test::More            => 0,
		Test::Differences     => 0,
		Class::Accessor::Fast => 0,
	},
	ABSTRACT_FROM => 'lib/Net/TacacsPlus.pm', # retrieve abstract from module
	AUTHOR        => 'Jozef Kutej <jkutej@cpan.org>',
	(MM->can('signature_target') ? (SIGN => 1) : ()),
	LICENSE => 'perl',
);
