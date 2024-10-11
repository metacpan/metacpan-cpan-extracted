#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub _remove_old_history {
    my $old = "$ENV{HOME}/.runtime_debugger.info";
    unlink $old if -e $old;
}

sub _readme {
    print "\nBuilding README\n";
    my ($installed) = grep { -e "$_/pod2markdown" } split /:/, $ENV{PATH};
    return if !$installed;
    system "pod2markdown lib/Runtime/Debugger.pm > README.md";
}

sub _install_readline_dev {
    print "\nInstalling readline-dev\n";
    my $os_name;

    my $os_file = "/etc/os-release";
    if (-e $os_file){
        open my $fh, "<", $os_file or warn $!;
        while (<$fh>) {
            next unless / ^ ID = "(\S+)" /x;
            $os_name = lc($1 // "");
            last;
        }
        close $fh;
        return if !$os_name;
    }
    elsif( $ENV{PREFIX} ){
        return if $ENV{PREFIX} !~ / \b termux \b /xi;
        $os_name = "termux";
    }

    my %commands = (
        centos => 'sudo dnf install -y readline-devel',
        gentoo => 'sudo emerge --ask sys-libs/readline',
        debian => 'sudo apt install -y libreadline-dev',
        ubuntu => 'sudo apt install -y libreadline-dev',
        termux => 'pkg install readline',
    );
    my $install_command = $commands{$os_name};
    return if !$install_command;

    print "Installing readline-dev for '$os_name' via '$install_command'\n";
    system "$install_command";
}

_remove_old_history();
_readme();
_install_readline_dev();

my $class = Module::Build->subclass(
    code => q{
        use ExtUtils::MakeMaker;
        sub ACTION_installdeps {
            my ($s) = @_;
            print "Checking if our version of ExtUtils::MakeMaker is ok\n";
            my $minimum = "7.6502";
            my $version = ExtUtils::MakeMaker->VERSION;
            print "Need ExtUtils::MakeMaker $minimum (have $version)\n";
            if ( $version < $minimum ) {
                print "Fetching version $minimum from repo\n";
                system "cpanm https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/archive/refs/tags/v7.65_02.tar.gz";
            }
            $s->SUPER::ACTION_installdeps;
        }
    },
);

my $builder = $class->new(
    module_name        => 'Runtime::Debugger',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Runtime/Debugger.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'                => '5.018',
        'Class::Tiny'         => '1.008',
        'Data::Printer'       => '1.002001',
        'PadWalker'           => '2.5',
        'Term::ReadLine::Gnu' => '1.44',
        'YAML::XS'            => '0',
    },
    add_to_cleanup => [
        'Runtime-Debugger-*', 'build_dir/', 'MANIFEST*.bak', 'README*',
        'blib/', "$ENV{HOME}/.runtime_debugger.info",
        'pod2htmd.tmp',
    ],
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/poti1/runtime-debugger/issues',
            repository => 'https://github.com/poti1/runtime-debugger',
        },
    },
);

$builder->create_build_script();
