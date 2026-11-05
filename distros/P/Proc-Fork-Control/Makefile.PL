use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Proc::Fork::Control',
    VERSION_FROM       => 'lib/Proc/Fork/Control.pm',
    ABSTRACT_FROM      => 'lib/Proc/Fork/Control.pm',
    AUTHOR             => 'Colin Faber <cfaber@fpsn.net>',
    LICENSE            => 'gpl_2',
    MIN_PERL_VERSION   => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM          => {
        'POSIX'       => 0,
        'Time::HiRes' => 0,
    },
    TEST_REQUIRES      => {
        'File::Temp' => 0,
        'Test::More' => 0,
    },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        # LICENSE above contributes gpl_2. MakeMaker appends this list.
        license     => [ 'artistic_1' ],
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cfaber/Proc-Fork-Control.git',
                web  => 'https://github.com/cfaber/Proc-Fork-Control',
            },
            bugtracker => {
                web => 'https://github.com/cfaber/Proc-Fork-Control/issues',
            },
        },
    },
    dist               => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

# This distribution is pure Perl. PERL_DL_NONLAZY hides nothing useful
# here and has been turned off since the first release.
sub MY::test {
    package MY;
    my $make = shift->SUPER::test();
    $make =~ s/(PERL_DL_NONLAZY)=1/$1=0/g;
    return $make;
}
