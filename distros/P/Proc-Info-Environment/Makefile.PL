######################################################################
# Makefile.PL for Proc::Info::Environment
# 2010, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
my $meta_merge = {
    META_MERGE => {
      resources => {
        repository => 'http://github.com/mschilli/proc-info-environment-perl',
      },
    }
};
WriteMakefile(
    'NAME'         => 'Proc::Info::Environment',
    'VERSION_FROM' => 'lib/Proc/Info/Environment.pm', # finds $VERSION
    'PREREQ_PM'    => {
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Proc/Info/Environment.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
