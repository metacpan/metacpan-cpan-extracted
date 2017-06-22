use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

# Check for pkg-config
my $pkgconfig = `which pkg-config`;
chomp($pkgconfig);
if ($pkgconfig !~ /pkg-config/ or
	$pkgconfig =~ /not found/i)
{
	die "Error: pkgconfig is not available on your system\n".
	    "It is available from http://pkgconfig.freedesktop.org/\n";
} else {
	my $pkgconfig_version = `$pkgconfig --version`;
	chomp( $pkgconfig_version );
	print "Found pkg-config version $pkgconfig_version.\n";
}

# Display libdiscid version
my $libdiscid_version = `$pkgconfig --modversion libdiscid`;
chomp($libdiscid_version);
if ($libdiscid_version =~ /^\d+\.\d+/) {
	print "Found libdiscid library version $libdiscid_version.\n";
}

# Check libdiscid is new enough
my $status = system("$pkgconfig --atleast-version=0.2.2 libdiscid");
if ($status != 0) {
	die "Error: libdiscid version 0.2.2 or higher is required.\n";
}

# Get libdiscid CFLAGS
my $LIBDISCID_CFLAGS = `$pkgconfig --cflags libdiscid`;
chomp( $LIBDISCID_CFLAGS );
print " LIBDISCID_CFLAGS = $LIBDISCID_CFLAGS\n";

# Get libdiscid LIBS
my $LIBDISCID_LIBS = `$pkgconfig --libs libdiscid`;
chomp( $LIBDISCID_LIBS );
print " LIBDISCID_LIBS = $LIBDISCID_LIBS\n";

my %WriteMakefileArgs = (
	NAME => 'MusicBrainz::DiscID',
	ABSTRACT_FROM => 'lib/MusicBrainz/DiscID.pm',
	VERSION_FROM => 'lib/MusicBrainz/DiscID.pm',
	AUTHOR => 'Nicholas J. Humfrey',
	LICENSE => 'gpl_2',

	TEST_REQUIRES => {
		'Test' => '1.00',
		'Test::More' => 0,
		'Test::Pod' => '1.00'
	},

	CCFLAGS => "$Config{ccflags} $LIBDISCID_CFLAGS",
	LIBS => $LIBDISCID_LIBS,
	XSPROTOARG => '-noprototypes'
);

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$WriteMakefileArgs{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			bugtracker  => {
				web => 'https://github.com/njh/perl-musicbrainz-discid/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/njh/perl-musicbrainz-discid.git',
				web => 'https://github.com/njh/perl-musicbrainz-discid',
			},
		},
	}
}

if (!eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	while (my ($m, $v) = each %{$WriteMakefileArgs{TEST_REQUIRES}}) {
		$WriteMakefileArgs{PREREQ_PM}->{$m} = $v;
	}
	delete $WriteMakefileArgs{TEST_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);
