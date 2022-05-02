use strict;
use warnings;
use ExtUtils::MakeMaker 6.52;

use Devel::CheckLib;

check_lib_or_exit(header => 'spawn.h');

my %conf = (
    NAME               => 'POSIX::RT::Spawn',
    AUTHOR             => 'gray <gray@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/POSIX/RT/Spawn.pm',
    ABSTRACT_FROM      => 'lib/POSIX/RT/Spawn.pm',
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib'     => 0,
        'ExtUtils::MakeMaker' => 6.52,
    },
    PREREQ_PM => {
        Exporter => 5.57,
        XSLoader => 0,
    },
    TEST_REQUIRES => { 'Test::More' => 0.98, },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/posix-rt-spawn',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'POSIX-RT-Spawn-*' },
);

for ([BUILD_REQUIRES => 6.55_03], [TEST_REQUIRES => 6.64]) {
    my ($tag, $ver) = @$_;
    $conf{PREREQ_PM} = { %{ $conf{PREREQ_PM} }, %{ delete $conf{$tag} } }
        if $conf{$tag} and ! eval { ExtUtils::MakeMaker->VERSION($ver) };
}

WriteMakefile(%conf);


sub MY::postamble {
    return <<"    MAKE_FRAG";
authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    my $self = shift;
    return $self->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
