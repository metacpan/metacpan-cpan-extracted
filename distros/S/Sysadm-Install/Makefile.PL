use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/sysadm-install-perl',
        },
    }
};

eval {
    require Expect;
};

if($@) {
    print <<EOT;
WARNING: Expect not found.
         You won't be able to use hammer().
         Install Expect from CPAN later if you want to.
EOT
}

eval {
    require Archive::Tar;
};

if($@) {
    print <<EOT;
WARNING: Archive::Tar not found.
         You won't be able to use untar() or untar_in().
         Install Archive::Tar from CPAN later if you want to.
EOT
}

WriteMakefile(
    NAME              => 'Sysadm::Install',
    VERSION_FROM      => 'lib/Sysadm/Install.pm', # finds $VERSION
    EXE_FILES         => ['eg/one-liner' ],
    PREREQ_PM         => {
        Log::Log4perl   => 1.28,
        File::Copy      => 0,
        File::Path      => 0,
        File::Basename  => 0,
        File::Which     => 1.09,
        Term::ReadKey   => 0,
        LWP::Simple     => 0,
        Cwd             => 0,
        File::Temp      => 0.16,
                         }, # e.g., Module::Name => 1.1
   
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sysadm/Install.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <m@perlmeister.com>') : ()),
);
