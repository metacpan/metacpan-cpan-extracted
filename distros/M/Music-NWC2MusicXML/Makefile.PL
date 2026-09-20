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
	NAME             => 'Music::NWC2MusicXML',
	AUTHOR           => 'Nigel Horne <njh@nigelhorne.com>',
	VERSION_FROM     => 'lib/Music/NWC2MusicXML.pm',
	ABSTRACT_FROM    => 'lib/Music/NWC2MusicXML.pm',
	LICENSE          => 'gpl_2',
	MIN_PERL_VERSION => '5.036',
	EXE_FILES        => [ 'bin/nwc2musicxml' ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM        => {
		'strict'                  => 0,
		'warnings'                => 0,
		'autodie'                 => 0,
		'Carp'                    => 0,
		'Compress::Zlib'          => 0,
		'File::Basename'          => 0,
		'File::Find'              => 0,
		'File::Path'              => 0,
		'File::Spec'              => 0,
		'Getopt::Long'            => 0,
		'List::Util'              => 0,
		'Object::Configure'       => 0,
		'Params::Get'             => 0,
		'Params::Validate::Strict'=> 0.39,
		'Pod::Usage'          => 0,
		'POSIX'                   => 0,
		'Readonly'                => 0,
		'Scalar::Util'            => 0,
	}, TEST_REQUIRES => {
		'File::Copy'              => 0,
		'File::Temp'              => 0,
		'IPC::System::Simple'  => 0,
		'Test::DescribeMe' => 0,
		'Test::Exception'         => 0,
		'Test::Memory::Cycle'     => 0,
		'Test::Mockingbird'       => 0,
		'Test::More'              => 0,
		'Test::Most'              => 0,
		'Test::Returns'           => 0,
		'Test::Without::Module'   => 0,
		'XML::PP'                 => 0,	# pure-Perl XML parser; no libxml2 dependency required
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources   => {
			homepage => 'https://metacpan.org/pod/Music::NWC2MusicXML',
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/NWC2MusicXML.git',
				web  => 'https://github.com/nigelhorne/NWC2MusicXML',
			},
			bugtracker => {
				# web => 'https://github.com/nigelhorne/NWC2MusicXML/issues',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Music-NWC2MusicXML',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Music-NWC2MusicXML',
				mailto => 'bug-Music-NWC2MusicXML@rt.cpan.org'
			},
		},
	},
	dist  => $dist,
	clean => { FILES => 'Music-NWC2MusicXML-*' },
);
