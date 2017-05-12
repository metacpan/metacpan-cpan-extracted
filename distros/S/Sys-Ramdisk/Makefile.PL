######################################################################
# Makefile.PL for Sys::Ramdisk
# 2010, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => 'http://github.com//sys-ramdisk-perl',
        },
    }
};
WriteMakefile(
    'NAME'         => 'Sys::Ramdisk',
    'VERSION_FROM' => 'lib/Sys/Ramdisk.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl   => 1,
        Sysadm::Install => 0.35,
        File::Temp      => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Sys/Ramdisk.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
