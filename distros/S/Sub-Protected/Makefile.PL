use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME             => 'Sub::Protected',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
    VERSION_FROM     => 'lib/Sub/Protected.pm',
    ABSTRACT_FROM    => 'lib/Sub/Protected.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
    PREREQ_PM        => {
        'Attribute::Handlers' => 0,
        'Carp'                => 0,
	'Params::Get' => 0,
	'Params::Validate::Strict' => 0,
	'Readonly' => 0,
	'Return::Set' => 0,
    }, TEST_REQUIRES    => {
	'IPC::System::Simple' => 0,
	'Moo' => 0,
        'Test::Exception' => 0,
	'Test::Memory::Cycle' => 0,
	'Test::Mockingbird' => 0,
        'Test::Most'      => 0,
	'Test::Returns' => 0,
    },
	clean		=> { FILES => 'Sub-Protected-*' },
	dist => $dist,
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Sub::Protected',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Sub-Protected.git',
				web => 'https://github.com/nigelhorne/Sub-Protected',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Protected',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Protected',
				# web => 'https://github.com/nigelhorne/Sub-Protected/issues',
				# url => 'https://github.com/nigelhorne/Sub-Protected/issues',
				mailto => 'bug-Sub-Protected@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
