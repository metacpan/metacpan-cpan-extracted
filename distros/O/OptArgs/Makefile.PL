#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME       => 'OptArgs',
    ABSTRACT   => 'CLI argument and option processing',
    AUTHOR     => 'Mark Lawrence <nomad@null.net>',
    VERSION    => '0.1.21',
    LICENSE    => 'gpl_3',
    test       => { RECURSIVE_TEST_FILES => 1, },
    EXE_FILES  => ['bin/optargs'],
    META_MERGE => {
        dynamic_config => 1,
        'meta-spec'    => { version => 2 },
        no_index       => {
            package => [
                qw/
                  OptArgs::Usage
                  Getopt::Args::Usage
                  /
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-OptArgs/issues', },
            homepage   => 'https//github.com/mlawren/p5-OptArgs',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-OptArgs.git',
                web  => 'https//github.com/mlawren/p5-OptArgs',
            }
        },
    },
);

# Duplicate OptArgs as Getopt::Args for easy discoverability

my $src;
{
    open my $fh, '<', File::Spec->catfile(qw/lib OptArgs.pm/);
    local $/ = undef;
    $src = <$fh>;
}

$src =~ s/Getopt::Args/GETOPT::ARGS/g;
$src =~ s/OptArgs/Getopt::Args/g;
$src =~ s/p5-Getopt::Args/p5-OptArgs/g;
$src =~ s/GETOPT::ARGS/OptArgs/g;

mkdir File::Spec->catdir(qw/lib Getopt/);
open my $fh, '>', File::Spec->catfile(qw/lib Getopt Args.pm/);
print $fh $src;
close $fh;
