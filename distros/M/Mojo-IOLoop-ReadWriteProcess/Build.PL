# =========================================================================
# THIS FILE IS AUTOMATICALLY GENERATED BY MINILLA.
# DO NOT EDIT DIRECTLY.
# =========================================================================

use 5.008_001;

use strict;
use warnings;
use utf8;

BEGIN { push @INC, '.' }
use builder::custom;
use File::Basename;
use File::Spec;

die "OS unsupported\n" if $^O eq "MSWin32";
die "OS unsupported\n" if $^O eq "cygwin";

my %args = (
    license              => 'perl_5',
    dynamic_config       => 0,

    configure_requires => {
        'Module::Build' => '0.4005',
    },

    requires => {
        'IPC::SharedMem' => '0',
        'Mojolicious' => '9.34',
    },

    recommends => {
    },

    suggests => {
    },

    build_requires => {
    },

    test_requires => {
        'Test::Exception' => '0',
        'Test::More' => '0',
        'Test::Pod' => '0',
    },

    name            => 'Mojo-IOLoop-ReadWriteProcess',
    module_name     => 'Mojo::IOLoop::ReadWriteProcess',
    allow_pureperl => 0,

    script_files => [glob('script/*'), glob('bin/*')],
    PL_files => {},

    test_files           => ((-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt') ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    tap_harness_args => {"merge" => 1},

);
if (-d 'share') {
    $args{share_dir} = 'share';
}

my $builder = builder::custom->subclass(
    class => 'MyBuilder',
    code => q{
        sub ACTION_distmeta {
            die "Do not run distmeta. Install Minilla and `minil install` instead.\n";
        }
        sub ACTION_installdeps {
            die "Do not run installdeps. Run `cpanm --installdeps .` instead.\n";
        }
    }
)->new(%args);
$builder->create_build_script();

