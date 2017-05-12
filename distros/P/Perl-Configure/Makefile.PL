use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/perl-configure-perl',
        },
    }
};

WriteMakefile(
    NAME              => 'Perl::Configure',
    VERSION_FROM      => 'lib/Perl/Configure.pm', # finds $VERSION
    PREREQ_PM         => {
        YAML          => 0.35,
        Expect        => 1.15,
        Data::Dumper  => 0,
        Log::Log4perl => 1.0,
        Getopt::Long  => 2.35,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    EXE_FILES         => [ 'eg/perl-configure' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl/Configure.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <m@perlmeister.com>') : ()),
);
