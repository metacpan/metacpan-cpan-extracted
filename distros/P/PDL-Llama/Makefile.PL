use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $llama_inc;
for my $dir ('/usr/include/llama', '/usr/include', '/usr/local/include/llama', '/usr/local/include') {
    if (-f "$dir/llama.h") {
        $llama_inc = $dir;
        last;
    }
}

if (!$llama_inc) {
    warn "libllama-dev (llama.h) is required to build PDL::Llama.\n";
    exit 0;
}

my $llama_lib = -d '/usr/lib/x86_64-linux-gnu/llama'
    ? '/usr/lib/x86_64-linux-gnu/llama'
    : '/usr/lib';

my $ggml_inc = -d '/usr/include/ggml' ? '-I/usr/include/ggml' : '';

WriteMakefile(
    NAME               => 'PDL::Llama',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/Llama.pm',
    ABSTRACT_FROM      => 'lib/PDL/Llama.pm',
    LICENSE            => 'apache_2_0',
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0' },
    TEST_REQUIRES      => { 'Test::More' => '0.88' },
    PREREQ_PM          => { 'PDL' => '2.080', 'Carp' => '0' },
    INC                => "-I. -I$llama_inc $ggml_inc",
    LIBS               => ["-L$llama_lib -Wl,-rpath,$llama_lib -lllama"],
    clean              => { FILES => 'PDL-Llama-* *.o Llama.bs Llama.c' },
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
