use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Palm::TreoPhoneCallDB',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Palm-TreoPhoneCallDB',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Palm-TreoPhoneCallDB/issues'
        }
    },
    VERSION_FROM => 'lib/Palm/TreoPhoneCallDB.pm',
    PREREQ_PM    => {
        Palm::PDB => 1.016,
        DateTime  => 0.30
    }
);
