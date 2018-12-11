use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SNMP::Trapinfo',
    VERSION_FROM      => 'lib/SNMP/Trapinfo.pm', # finds $VERSION
    LICENSE           => 'perl_5',
    PREREQ_PM         => { File::Temp => 0.05, Safe => 2.11 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SNMP/Trapinfo.pm', # retrieve abstract from module
       AUTHOR         => 'Ton Voon <ton.voon@opsview.com>') : ()),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tonvoon/perl-snmp-trapinfo.git',
                web  => 'https://github.com/tonvoon/perl-snmp-trapinfo',
            },
        },
    },
);
