use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Sys::Hostname::Long',
    'VERSION_FROM'	=> 'lib/Sys/Hostname/Long.pm',
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Sys/Hostname/Long.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Penrose <scott@cpan.org>') : ()),
    'LICENSE'   => 'perl',
    'META_MERGE' => {
        resources => {
            repository => 'https://github.com/scottp/sys-hostname-long/',
        },
    },
);
