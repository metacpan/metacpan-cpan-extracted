use ExtUtils::MakeMaker;
use File::Spec;

my $ok;
for my $path (split /:/, $ENV{PATH}) {
    if (-e File::Spec->catfile($path, "raop_play")) {
        $ok = 1;
        last;
    }
}

unless ($ok) {
    warn <<WARN;
It looks like you don't have Airport Express Client (raop-play) installed.
Get it from http://raop-play.sourceforge.net/
WARN
}

WriteMakefile(
    'NAME'      => 'POE::Component::Client::AirTunes',
    'VERSION_FROM' => 'lib/POE/Component/Client/AirTunes.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        POE => 0.30,
    },
);
