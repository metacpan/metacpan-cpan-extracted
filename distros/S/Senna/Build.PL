#!perl
# $Id: /mirror/Senna-Perl/Build.PL 2487 2006-07-12T16:49:51.285816Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;
use vars qw(%MyArgs);

my $debugging = 0;
foreach (@ARGV) {
    /^--debugging$/ and $debugging = 1;
}

my $config = do 'tools/prompt.pl';
$config->{cflags} .= ' -g' if $debugging;

my($major, $minor, $micro) = split(/\./, $config->{version});

my %args = (
    dist_name => 'Senna',
    dist_version_from => 'lib/Senna.pm',
    license => 'lgpl',
    c_source => 'src',
    extra_compiler_flags => [ 
        split(/\s+/, $config->{cflags}),
        "-DSENNA_MAJOR_VERSION=$major",
        "-DSENNA_MINOR_VERSION=$minor",
        "-DSENNA_MICRO_VERSION=$micro",
        "-DSENNA_VERSION=$config->{version}"
    ],
    extra_linker_flags   => [ split(/\s+/, $config->{libs}) ],
    build_requires => {
        'File::Spec' => 0,
        'File::Temp' => 0,
    }
);

my $class = Module::Build->subclass(code => <<'EOSUB');
    sub ACTION_build {
        my $self = shift;

        if (-f 'lib/Senna.c') {
            my $copy_mtime = (stat('lib/Senna.c'))[9];
            my $orig_mtime = (stat('lib/Senna.xs'))[9];
            if ($copy_mtime <= $orig_mtime) {
                unlink 'lib/Senna.c' if -f 'lib/Senna.c';
            }
        }
        $self->SUPER::ACTION_build(@_);
    }

    sub ACTION_disttest
    {
        my $self = shift;
        local $ENV{PERL_TESTPOD} = 1;
        $self->SUPER::ACTION_disttest(@_);
    }

    sub find_test_files
    {
        my $self  = shift;
        my $tests = $self->SUPER::find_test_files(@_);

        return $tests if $ENV{PERL_TESTPOD};
        return [ grep { $_ !~ /\bpod.*\.t\z/ } @$tests ];
    }
EOSUB

my $build = $class->new(%args);
$build->create_build_script;