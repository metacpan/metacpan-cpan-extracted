use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $ggml_inc;
for my $dir ('/usr/include/ggml', '/usr/include', '/usr/local/include/ggml', '/usr/local/include') {
    if (-f "$dir/ggml.h") {
        $ggml_inc = $dir;
        last;
    }
}

if (!$ggml_inc) {
    warn "libggml-dev (ggml.h) is required to build PDL::GGML.\n";
    exit 0;
}

my $ggml_lib = -d '/usr/lib/x86_64-linux-gnu/ggml'
    ? '/usr/lib/x86_64-linux-gnu/ggml'
    : '/usr/lib';

my $pdl_inc = PDL::Core::Dev::PDL_INCLUDE();
$pdl_inc =~ s/^"|"$//g;

WriteMakefile(
    NAME               => 'PDL::GGML',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/GGML.pm',
    ABSTRACT_FROM      => 'lib/PDL/GGML.pm',
    LICENSE            => 'apache_2_0',
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'PDL'                 => '2.080',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL' => '2.080',
    },
    INC   => "-I. $pdl_inc -I$ggml_inc",
    LIBS  => ["-L$ggml_lib -Wl,-rpath,$ggml_lib -lggml -lggml-base"],
    clean => { FILES => 'PDL-GGML-* *.o GGML.bs GGML.c' },
    META_MERGE => {
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
