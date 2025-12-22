use 5.034000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Solana::SPLAddress',
    VERSION_FROM      => 'lib/Solana/SPLAddress.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Digest::SHA' => 1,
    },
    ABSTRACT_FROM     => 'lib/Solana/SPLAddress.pm', # retrieve abstract from module
    AUTHOR            => 'shmakins@gmail.com',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    CCFLAGS => "$Config::Config{ccflags}",
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES) src/decompress.c', # link all the C files too

);
