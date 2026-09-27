use 5.010;
use strict;
use warnings;
use version;

use ExtUtils::MakeMaker;

my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver=~/_/) {
    $mm_ver=eval($mm_ver);
    die $@ if $@;
}
my %WriteMakefile=(
    NAME             => 'Task::Markdown::Publish',
    DISTNAME         => 'Task-Markdown-Publish',
    VERSION_FROM     => 'lib/Task/Markdown/Publish.pm',
    ABSTRACT_FROM    => 'lib/Task/Markdown/Publish.pm',
    EXE_FILES        => [],
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'ASPEER::MakeMaker::Markdown::Pod'     => '1.014',
        'ASPEER::MakeMaker::Markdown::Publish' => '1.003',
        'Docbook::Convert'                     => '1.012',
        'Markdown::Pod::Embed'                 => '1.013',
        'Markdown::Publish'                    => '1.003',
        'Task::Markdown::Pod'                  => '0.001',
        'strict'                               => 0,
        'vars'                                 => 0,
        'warnings'                             => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'version'             => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        x_authority => 'cpan:ASPEER',
        'meta-spec' => {version => 2},
        resources   => {
            bugtracker => {
                web => 'https://github.com/aspeer/pm-Task-Markdown-Publish/issues',
            },
            homepage   => 'https://github.com/aspeer/pm-Task-Markdown-Publish',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-Task-Markdown-Publish.git',
                web  => 'https://github.com/aspeer/pm-Task-Markdown-Publish',
            },
        },
    },
    depend => {Makefile => '$(VERSION_FROM)'},
    dist   => {COMPRESS => 'gzip -9f', SUFFIX => '.gz'},
);
my %MM_Compat=(
    '6.31' => [qw(LICENSE)],
    '6.46' => [qw(META_MERGE)],
    '6.48' => [qw(MIN_PERL_VERSION)],
    '6.52' => [qw(CONFIGURE_REQUIRES)],
    '6.64' => [qw(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $name_ar)=each(%MM_Compat)) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete(@WriteMakefile{@{$name_ar}});
    }
}
WriteMakefile(%WriteMakefile);
