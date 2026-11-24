use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $sp_inc;
for my $dir ('/usr/include', '/usr/local/include') {
    if (-f "$dir/sentencepiece_processor.h") {
        $sp_inc = $dir;
        last;
    }
}

if (!$sp_inc) {
    warn "libsentencepiece-dev (sentencepiece_processor.h) is required to build PDL::SentencePiece.\n";
    exit 0;
}

WriteMakefile(
    NAME               => 'PDL::SentencePiece',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/SentencePiece.pm',
    ABSTRACT_FROM      => 'lib/PDL/SentencePiece.pm',
    LICENSE            => 'apache_2_0',
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0' },
    TEST_REQUIRES      => { 'Test::More' => '0.88' },
    PREREQ_PM          => { 'PDL' => '2.080', 'Carp' => '0' },
    CC                 => 'g++',
    LD                 => 'g++',
    CCFLAGS            => '-std=c++17 -fPIC',
    INC                => "-I. -I$sp_inc",
    LIBS               => ['-lsentencepiece'],
    XSOPT              => '-C++',
    clean              => { FILES => 'PDL-SentencePiece-* *.o SentencePiece.bs SentencePiece.c' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl.git',
                web  => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl',
            },
            bugtracker => {
                web => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues',
            },
        },
    },
);
