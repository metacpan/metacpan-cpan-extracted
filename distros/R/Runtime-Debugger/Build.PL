#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

my $class = Module::Build->subclass(
    code => q{
        use ExtUtils::MakeMaker;
        use Cwd qw( cwd );

        #---------------------------------
        #             new
        #---------------------------------

        # Detect and fix prerequisite issues.
        sub prereq_failures {
            my ($s) = @_;
            my $err = $s->SUPER::prereq_failures;

            if ( $err and ref($err) eq "HASH" ) {
                if ( $err->{requires} ) {
                    if ( $err->{requires}{"Term::ReadLine::Gnu"} ) {
                        $s->_install_readline_dev();
                    }
                }
            }

            $err;
        }

        sub _install_readline_dev {
            print "\nInstalling readline-dev\n";
            my $os_name;

            # Determine OS name.
            my $os_file = "/etc/os-release";
            if (-e $os_file){
                my $is_ID_line = qr{
                    ^ ID = (?:
                        " (?<id> \S+ ) "
                        |
                        ' (?<id> \S+ ) '
                        |
                        (?<id> \S+ )
                    )
                }x;
                open my $fh, "<", $os_file or warn $!;
                while (<$fh>) {
                    chomp;
                    next unless /$is_ID_line/;
                    $os_name = lc($+{id} // "");
                    last;
                }
                close $fh;
            }
            elsif( $ENV{PREFIX} ){
                return if $ENV{PREFIX} !~ / \b termux \b /xi;
                $os_name = "termux";
            }
            $os_name //= "Not Sure";

            # Generate installation command.
            my %commands = (
                centos => 'sudo dnf install -y readline-devel',
                gentoo => 'sudo emerge --ask sys-libs/readline',
                debian => 'sudo apt install -y libreadline-dev',
                ubuntu => 'sudo apt install -y libreadline-dev',
                termux => 'pkg install readline ncurses && cpanm -v --notest Term::ReadLine::Gnu',
            );
            my $install_command = $commands{$os_name};
            if (!$install_command){
                print "Not install command detected for os: $os_name\n";
                return;
            }

            print "Installing readline-dev for '$os_name' via '$install_command'\n";
            system "$install_command";
        }

        #---------------------------------
        #            Build
        #---------------------------------

        sub ACTION_build {
            my ($s) = @_;
            $s->_readme();
            $s->SUPER::ACTION_build;
        }

        # Only for the maintainer on "Build build".
        sub _readme {
            my ($s) = @_;
            return if cwd() !~ m{ / git / perlmy / [^/]+ $ }x;

            my ($installed) =
                grep { -x "$_/pod2markdown" }
                split /:/, $ENV{PATH};
            return if !$installed;

            print "Building README\n";
            my $lib = $s->{properties}{dist_version_from};
            system "pod2markdown $lib > README.md";
        }

        #---------------------------------
        #             Deps
        #---------------------------------

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

        #---------------------------------
        #           Install
        #---------------------------------

        sub ACTION_install {
            my ($s) = @_;
            $s->_remove_old_history();
            $s->SUPER::ACTION_install;
        }

        sub _remove_old_history {
            my $old = "$ENV{HOME}/.runtime_debugger.info";
            unlink $old if -e $old;
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
