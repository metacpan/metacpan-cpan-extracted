use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pick::TCL',
    AUTHOR              => q{Jack Burton <jack@saosce.com.au>},
    VERSION_FROM        => 'lib/Pick/TCL.pm',
    ABSTRACT_FROM       => 'lib/Pick/TCL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION    => 5.006,
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'IO::Select' => 0,
        'IO::Socket' => 0,
        'IPC::Run' => 0,
        'Socket' => 0,
    },
    PREREQ_PM => { 'Carp' => 0,
                   'IO::Select' => 0,
                   'IO::Socket' => 0,
                   'Socket' => 0,
    },
    META_MERGE => {
        optional_features => {
            local_pick => {
                description => "Connect to a local Pick VM without ssh",
                requires => { 'IPC::Run' => 0, },
            },
            remote_pick => {
                description => "Connect to a Pick VM over ssh",
                requires => { 'Net::OpenSSH' => 0, },
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pick-TCL-*' },
);
