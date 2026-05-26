# Copyright (c) 2013-2026 by Martin Becker, Blaubeuren.
# This script is free software; you can redistribute it and/or modify it
# under the terms of the Artistic License 2.0 (see the LICENSE file).
#
# The license grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the license.

BEGIN {
    $ENV{'NYTPROF'} = 'start=no';
}

use strict;
use warnings;
use File::Spec;
use ExtUtils::MakeMaker 6.64;

my $DN              = 'Task-Devel-Essentials';
my $module_name     = 'Task::Devel::Essentials';
my $module_filename = 'lib/Task/Devel/Essentials.pm';
my $module_pathname = File::Spec->catfile(split m{/}, $module_filename);
my $module_version  = MM->parse_version($module_pathname);

my %requires      = ();
my %recommends    = ();
my %conf_requires = ();
my %test_requires = ();

sub requires ($$) {
    my ($module, $version) = @_;
    $requires{$module} = $version;
}

sub recommends ($$) {
    my ($module, $version) = @_;
    $recommends{$module} = $version;
}

sub conf_requires ($$) {
    my ($module, $version) = @_;
    $conf_requires{$module} = $version;
}

sub test_requires ($$) {
    my ($module, $version) = @_;
    $test_requires{$module} = $version;
}

requires        'App::CPANTS::Lint'                    => '0.05';
requires        'Archive::Tar'                         => '3.04';
requires        'Archive::Zip'                         => '1.68';
requires        'Assert::Conditional'                  => '0.010000';
requires        'CPAN'                                 => '2.38';
requires        'CPAN::DistnameInfo'                   => '0.12';
requires        'CPAN::Reporter'                       => '1.2020';
requires        'Contextual::Return'                   => '0.004014';
requires        'Data::Dumper'                         => '2.183';
requires        'Data::Dumper::Simple'                 => '0.11';
requires        'Data::Printer'                        => '1.002001';
requires        'DateTime'                             => '1.66';
requires        'Devel::Cover'                         => '1.52';
requires        'Devel::NYTProf'                       => '6.15';
requires        'Devel::StackTrace'                    => '2.05';
requires        'Digest::SHA'                          => '6.04';
requires        'Dist::Zilla'                          => '6.037';
requires        'Encode'                               => '3.24';
requires        'ExtUtils::CBuilder'                   => '0.280236';
requires        'ExtUtils::MakeMaker'                  => '7.78';
requires        'File::HomeDir'                        => '1.006';
requires        'File::ShareDir'                       => '1.118';
requires        'File::Spec'                           => '3.75';
requires        'File::Temp'                           => '0.2312';
requires        'File::Which'                          => '1.27';
requires        'Getopt::Long'                         => '2.58';
requires        'IO::Compress::Base'                   => '2.219';
requires        'IO::Zlib'                             => '1.15';
requires        'Inline'                               => '0.87';
requires        'Iterator::Diamond'                    => '1.01';
requires        'JSON'                                 => '4.11';
requires        'Kwalify'                              => '1.24';
requires        'LWP'                                  => '6.82';
requires        'List::MoreUtils'                      => '0.430';
recommends      'List::MoreUtils::XS'                  => '0.430';
requires        'MIME::Base64'                         => '3.16';
requires        'MIME::Lite'                           => '3.038';
requires        'Modern::Perl'                         => '1.20250607';
requires        'Module::CPANTS::Analyse'              => '1.02';
requires        'Module::CoreList'                     => '5.20260420';
requires        'Module::Install'                      => '1.21';
requires        'Module::Signature'                    => '0.96';
requires        'Module::Starter'                      => '1.82';
requires        'Module::Version'                      => '0.201';
requires        'Moo'                                  => '2.005005';
requires        'Moose'                                => '2.4000';
requires        'Mouse'                                => '2.006002';
requires        'Net::FTP'                             => '3.15';
requires        'Params::Check'                        => '0.38';
requires        'Parse::CPAN::Meta'                    => '2.150013';
requires        'Perl6::Form'                          => '0.090';
requires        'Perl6::Slurp'                         => '0.051005';
requires        'Perl::Critic'                         => '1.156';
requires        'Readonly'                             => '2.05';
requires        'Regexp::Common'                       => '2024080801';
requires        'Role::Basic'                          => '0.16';
requires        'Scalar::Util'                         => '1.70';
requires        'Term::ReadKey'                        => '2.38';
requires        'Term::ReadLine'                       => '1.14';
recommends      'Term::ReadLine::Gnu'                  => '1.47';
requires        'Test2::Suite'                         => '1.302219';
requires        'Test::Class'                          => '0.52';
requires        'Test::Differences'                    => '0.72';
requires        'Test::Exception'                      => '0.43';
requires        'Test::Fatal'                          => '0.018';
requires        'Test::Harness'                        => '3.52';
requires        'Test::MinimumVersion'                 => '0.101083';
recommends      'Test::MinimumVersion::Fast'           => '0.04';
requires        'Test::MockModule'                     => '0.183.0';
requires        'Test::More'                           => '1.302219';
requires        'Test::NoWarnings'                     => '1.06';
requires        'Test::Output'                         => '1.036';
requires        'Test::Pod'                            => '1.52';
requires        'Test::Pod::Coverage'                  => '1.10';
requires        'Test::Portability::Files'             => '0.10';
requires        'Test::Regexp'                         => '2017040101';
requires        'Test::Reporter::Transport::Metabase'  => '1.999010';
requires        'Test::Requires'                       => '0.11';
requires        'Test::Signature'                      => '1.11';
requires        'Test::Simple'                         => '1.302219';
requires        'Test::Strict'                         => '0.54';
requires        'Test::Warn'                           => '0.37';
requires        'Text::Glob'                           => '0.11';
requires        'Try::Tiny'                            => '0.32';
requires        'Type::Tiny'                           => '2.010001';
requires        'YAML'                                 => '1.31';
requires        'YAML::Syck'                           => '1.45';

conf_requires   'File::Spec'                           => '0';
conf_requires   'ExtUtils::MakeMaker'                  => '6.64';
test_requires   'Test::More'                           => '0.82';

WriteMakefile(
    NAME               => $module_name,
    VERSION            => $module_version,
    ABSTRACT_FROM      => $module_filename,
    LICENSE            => 'artistic_2',
    AUTHOR             => 'Martin Becker <mhasch at cpan.org>',
    NO_META            => 0,
    CONFIGURE_REQUIRES => \%conf_requires,
    TEST_REQUIRES      => \%test_requires,
    MIN_PERL_VERSION   => '5.006',
    PREREQ_PM          => \%requires,
    SIGN               => 1,
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        provides => {
            $module_name => {
                file    => $module_filename,
                version => $module_version,
            },
        },
        prereqs => {
            runtime => {
                recommends => \%recommends,
            },
        },
        no_index => {
            directory => [
                'maint',
            ],
        },
        resources      => {
            bugtracker => {
                web => "https://codeberg.org/mhasch/perl-$DN/issues",
            },
            license => [
                'https://www.perlfoundation.org/artistic-license-20.html'
            ],
            repository => {
                url  => "git://codeberg.org/mhasch/perl-$DN.git",
                web  => "https://codeberg.org/mhasch/perl-$DN",
                type => 'git',
            },
        },
    },
);
