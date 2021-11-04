use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                   => 'No::Worries',
    AUTHOR                 => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION                => '1.7',
    ABSTRACT_FROM          => 'lib/No/Worries.pm',
    LICENSE                => 'perl',
    PL_FILES               => {},
    BUILD_REQUIRES => {
        'File::Temp'       => 0,
        'Getopt::Long'     => 0,
        # optional: Pod::Coverage
        'Test::More'       => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        'Carp'             => 0,
        'Config'           => 0,
        'Encode'           => 0,
        'Fcntl'            => 0,
        'HTTP::Date'       => 0,
        'IO::Handle'       => 0,
        'IO::Select'       => 0,
        'POSIX'            => 0,
        'Params::Validate' => 0,
        'Sys::Hostname'    => 0,
        'Sys::Syslog'      => 0,
        'Time::HiRes'      => 0,
        'URI::Escape'      => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean                  => { FILES => 'No-Worries-*' },
);

($emv = $ExtUtils::MakeMaker::VERSION) =~ s/_//;
if ($emv < 6.5503) {
    # missing BUILD_REQUIRES
    foreach $name (keys(%{ $param{BUILD_REQUIRES} })) {
	$param{PREREQ_PM}{$name} = $param{BUILD_REQUIRES}{$name};
    }
    delete($param{BUILD_REQUIRES});
}
if ($emv < 6.31) {
    # missing LICENSE
    delete($param{LICENSE});
}

WriteMakefile(%param);
