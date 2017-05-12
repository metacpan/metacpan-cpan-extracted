######################################################################
# Makefile.PL for Process::MaxSize
# 2007, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/process-maxsize-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Process::MaxSize',
    'VERSION_FROM' => 'MaxSize.pm', # finds $VERSION
    'PREREQ_PM'    => {
        "Log::Log4perl" => 1.0,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MaxSize.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);
