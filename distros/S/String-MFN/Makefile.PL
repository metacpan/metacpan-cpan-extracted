use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my @programs;
my %reqs;

$reqs{'Test::More'} = 0;

for (split "\n", <<'QUERIES') {
mfn|y|Moronic Filename Normalizer
QUERIES
    my ($program, $default, $description) = split /\|/, $_;
    if (prompt("Install '$program', the $description?\n(Almost certianly NO if you are on Windows)", $default) =~ /^y/i) {
	push(@programs, 'bin/mfn');
        $reqs{'Config::YAML'} = 0;
	print STDOUT "\nInstalling mfn. Please read the manpage before using!\n\n"
    }
}

WriteMakefile(
    NAME           => 'String::MFN',
    AUTHOR         => 'Shawn Boyette <mdxi@cpan.org>',
    VERSION_FROM   => 'lib/String/MFN.pm',
    ABSTRACT_FROM  => 'lib/String/MFN.pm',
    EXE_FILES      => \@programs,
    PREFIX         => $Config{siteprefix},
    PREREQ_PM      => \%reqs,
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean          => { FILES => 'String-MFN-*' },
);
