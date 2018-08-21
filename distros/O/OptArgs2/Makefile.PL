#!/usr/bin/env perl
use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME       => 'OptArgs2',
    ABSTRACT   => 'CLI argument and option processing',
    AUTHOR     => 'Mark Lawrence <nomad@null.net>',
    VERSION    => '0.0.11',
    LICENSE    => 'gpl_3',
    test       => { RECURSIVE_TEST_FILES => 1, },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            package => [
                qw/
                  OptArgs2::Arg
                  OptArgs2::Cmd
                  OptArgs2::Fallback
                  OptArgs2::Mo
                  OptArgs2::Opt
                  OptArgs2::Result
                  OptArgs2::Util
                  Getopt::Args2::Arg
                  Getopt::Args2::Cmd
                  Getopt::Args2::Fallback
                  Getopt::Args2::Mo
                  Getopt::Args2::Opt
                  Getopt::Args2::Result
                  Getopt::Args2::Util
                  /
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-OptArgs2/issues', },
            homepage   => 'https//github.com/mlawren/p5-OptArgs2',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-OptArgs2.git',
                web  => 'https//github.com/mlawren/p5-OptArgs2',
            }
        },
    },
);

# Duplicate OptArgs2 as Getopt::Args2 for easy discoverability
use File::Spec;

open my $fh, '<', File::Spec->catfile(qw/lib OptArgs2.pm/) or die "open: $!";
my $src = do { local $/ = undef; <$fh> };
close $fh;

$src =~ s/Getopt::Args2/GETOPT::ARGS2/g;
$src =~ s/OptArgs2/Getopt::Args2/g;
$src =~ s/p5-Getopt::Args2/p5-OptArgs2/g;
$src =~ s/GETOPT::ARGS2/OptArgs2/g;

mkdir File::Spec->catdir(qw/lib Getopt/);
open $fh, '>', File::Spec->catfile(qw/lib Getopt Args2.pm/);
print $fh $src;
close $fh;
