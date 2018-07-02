#!perl
use 5.010;
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;
use Module::Build::Pluggable 'CPANfile';

our $VERSION = '0.0.10';

my $builder = Module::Build::Pluggable->new(
    module_name        => 'OptArgs2',
    create_license     => 1,
    create_makefile_pl => 'small',
    create_readme      => 1,
    license            => 'GPL_3',
    dist_author        => 'Mark Lawrence <nomad@null.net>',
    dist_version       => $VERSION,
    no_index           => {
        package => [
            qw/
              OptArgs2::Arg
              OptArgs2::Cmd
              OptArgs2::Fallback
              OptArgs2::Mo
              OptArgs2::Opt
              OptArgs2::Result
              OptArgs2::Util
              Getopt::Args2::Result
              /
        ],
    },
    recursive_test_files => 1,
    add_to_cleanup =>
      [ 'OptArgs2-*', '*.bak', 'blib', 'Makefile', 'lib*Getopt*Args2.pm' ],
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/mlawren/p5-OptArgs2/issues',
            repository => 'git://github.com/mlawren/p5-OptArgs2.git',
            homepage   => 'https://github.com/mlawren/p5-OptArgs2',
        },
        keywords => [],
    },
);

$builder->create_build_script();

# I prefer to use make when developing so lets built the Makefile here
# as well
Module::Build::Compat->write_makefile( build_class => 'Module::Build' );

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
