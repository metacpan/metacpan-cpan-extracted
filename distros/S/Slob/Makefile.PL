use 5.014000;
use ExtUtils::MakeMaker;

my $packed_nr = "\x00\x00\x00\x00\x00\xBC\x61\x4E";
my $unpacked_nr = eval { unpack 'Q>', $packed_nr };
$unpacked_nr == 12345678 || die "Failed to unpack quad, this Perl does not support 64-bit integers. Bailing out. Error '$!'\n";

WriteMakefile(
	NAME              => 'Slob',
	VERSION_FROM      => 'lib/Slob.pm',
	ABSTRACT_FROM     => 'lib/Slob.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Compress::Raw::Lzma 0/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=slob.git',
		},
	}
);
