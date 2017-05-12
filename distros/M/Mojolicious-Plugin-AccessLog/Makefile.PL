use 5.010001;

use strict;
use warnings;
use version 0.77;

use ExtUtils::MakeMaker;

my $eumm_version = version->parse($ExtUtils::MakeMaker::VERSION);
my $prereq = {
    'Mojolicious' => '3.28',
    'IO::File' => 0,
    'Scalar::Util' => 0,
    'Socket' => 0,
    'Time::HiRes' => 0,
    'File::Spec' => 0,
};

my @args = (
    NAME           => 'Mojolicious::Plugin::AccessLog',
    VERSION_FROM   => 'lib/Mojolicious/Plugin/AccessLog.pm',
    ABSTRACT       => 'An AccessLog Plugin for Mojolicious',
    AUTHOR         => 'Bernhard Graf',
    LICENSE        => 'perl_5',
    test           => {TESTS => 't/*.t'}
);

if ($eumm_version >= 6.46) {
    push @args,
        META_MERGE     => {
            requires   => {perl => '5.010001'},
            resources  => {
                license    => 'http://dev.perl.org/licenses/',
                bugtracker => 'https://github.com/augensalat/mojolicious-plugin-accesslog/issues',
                repository => 'https://github.com/augensalat/mojolicious-plugin-accesslog.git',
            },
        };
}

my %eumm_req = (
    'POSIX' => 0,
    'Time::Local' => 0,
    %$prereq,
);

if ($eumm_version >= 6.64) {
    push @args,
        PREREQ_PM => $prereq,
        TEST_REQUIRES => \%eumm_req;
}
elsif ($eumm_version >= 6.5503) {
    push @args,
        PREREQ_PM => $prereq,
        BUILD_REQUIRES => \%eumm_req;
}
else {
    push @args, PREREQ_PM => \%eumm_req;
}

WriteMakefile(@args);
