######################################################################
# Makefile.PL for Pod::Licensizer
# 2011, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/pod-licensizer-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Pod::Licensizer',
    'VERSION_FROM' => 'Licensizer.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Pod::Abstract => 0.20,
        Log::Log4perl => 1.0,
        Pod::Usage    => 1.36,
        YAML          => 0.71,
        Pod::Parser   => 1.37,
    }, # e.g., Module::Name => 1.1
    EXE_FILES           => ["eg/licensizer"],
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Licensizer.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
