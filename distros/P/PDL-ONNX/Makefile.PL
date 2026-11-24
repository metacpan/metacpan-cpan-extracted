use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $ort_inc;
for my $dir ('/usr/include/onnxruntime', '/usr/include', '/usr/local/include/onnxruntime') {
    if (-f "$dir/onnxruntime_c_api.h") {
        $ort_inc = $dir;
        last;
    }
}

if (!$ort_inc) {
    warn "libonnxruntime-dev (onnxruntime_c_api.h) is required to build PDL::ONNX.\n";
    exit 0;
}

my $pdl_inc = PDL::Core::Dev::PDL_INCLUDE();
$pdl_inc =~ s/^"|"$//g;

WriteMakefile(
    NAME               => 'PDL::ONNX',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/ONNX.pm',
    ABSTRACT_FROM      => 'lib/PDL/ONNX.pm',
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
    INC   => "-I. $pdl_inc -I$ort_inc",
    LIBS  => ['-lonnxruntime'],
    clean => { FILES => 'PDL-ONNX-* *.o ONNX.bs ONNX.c' },
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
