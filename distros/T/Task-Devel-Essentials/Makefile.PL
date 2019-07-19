# Copyright (c) 2013-2019 Martin Becker.  All rights reserved.
# This script is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    $ENV{'NYTPROF'} = 'start=no';
}

use ExtUtils::MakeMaker 6.64;

my $module_filename = 'lib/Task/Devel/Essentials.pm';

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
requires        'Archive::Tar'                         => '2.32';
requires        'Archive::Zip'                         => '1.64';
requires        'Assert::Conditional'                  => '0.009';
requires        'CPAN'                                 => '2.27';
requires        'CPAN::Reporter'                       => '1.2018';
requires        'Contextual::Return'                   => '0.004014';
requires        'Data::Dumper'                         => '2.173';
requires        'Data::Dumper::Simple'                 => '0.11';
requires        'Data::Printer'                        => '0.40';
requires        'DateTime'                             => '1.51';
requires        'Devel::Cover'                         => '1.33';
requires        'Devel::NYTProf'                       => '6.06';
requires        'Devel::StackTrace'                    => '2.04';
requires        'Digest::SHA'                          => '6.02';
requires        'Dist::Zilla'                          => '6.012';
requires        'Encode'                               => '3.01';
requires        'ExtUtils::CBuilder'                   => '0.280231';
requires        'ExtUtils::MakeMaker'                  => '7.36';
requires        'File::HomeDir'                        => '1.004';
requires        'File::ShareDir'                       => '1.116';
requires        'File::Spec'                           => '3.75';
requires        'File::Temp'                           => '0.2309';
requires        'File::Which'                          => '1.23';
requires        'Getopt::Long'                         => '2.5';
requires        'IO::Compress::Base'                   => '2.086';
requires        'IO::Zlib'                             => '1.10';
requires        'Inline'                               => '0.83';
requires        'Iterator::Diamond'                    => '1.01';
requires        'JSON'                                 => '4.02';
requires        'Kwalify'                              => '1.22';
requires        'LWP'                                  => '6.39';
requires        'List::MoreUtils'                      => '0.428';
recommends      'List::MoreUtils::XS'                  => '0.428';
requires        'MIME::Base64'                         => '3.15';
requires        'MIME::Lite'                           => '3.030';
requires        'Modern::Perl'                         => '1.20190601';
requires        'Module::CPANTS::Analyse'              => '1.00';
requires        'Module::CoreList'                     => '5.20190620';
requires        'Module::Install'                      => '1.19';
requires        'Module::Signature'                    => '0.83';
requires        'Module::Starter'                      => '1.76';
requires        'Module::Version'                      => '0.201';
requires        'Moo'                                  => '2.003004';
requires        'Moose'                                => '2.2011';
requires        'Mouse'                                => '2.005006';
requires        'Net::FTP'                             => '3.11';
requires        'Params::Check'                        => '0.38';
requires        'Parse::CPAN::Meta'                    => '2.150010';
requires        'Perl6::Form'                          => '0.090';
requires        'Perl6::Slurp'                         => '0.051005';
requires        'Perl::Critic'                         => '1.134';
requires        'Readonly'                             => '2.05';
requires        'Regexp::Common'                       => '2017060201';
requires        'Role::Basic'                          => '0.13';
requires        'Scalar::Util'                         => '1.50';
requires        'Term::ReadKey'                        => '2.38';
requires        'Term::ReadLine'                       => '1.14';
recommends      'Term::ReadLine::Gnu'                  => '1.36';
requires        'Test2::Suite'                         => '0.000122';
requires        'Test::Class'                          => '0.50';
requires        'Test::Differences'                    => '0.67';
requires        'Test::Exception'                      => '0.43';
requires        'Test::Fatal'                          => '0.014';
requires        'Test::Harness'                        => '3.42';
requires        'Test::MinimumVersion'                 => '0.101082';
recommends      'Test::MinimumVersion::Fast'           => '0.04';
requires        'Test::MockModule'                     => '0.170.0';
requires        'Test::More'                           => '1.302164';
requires        'Test::NoWarnings'                     => '1.04';
requires        'Test::Output'                         => '1.031';
requires        'Test::Pod'                            => '1.52';
requires        'Test::Pod::Coverage'                  => '1.10';
requires        'Test::Portability::Files'             => '0.10';
requires        'Test::Regexp'                         => '2017040101';
requires        'Test::Reporter::Transport::Metabase'  => '1.999010';
requires        'Test::Requires'                       => '0.10';
requires        'Test::Signature'                      => '1.11';
requires        'Test::Simple'                         => '1.302164';
requires        'Test::Strict'                         => '0.52';
requires        'Test::Warn'                           => '0.36';
requires        'Text::Glob'                           => '0.11';
requires        'Try::Tiny'                            => '0.30';
requires        'Type::Tiny'                           => '1.004004';
requires        'YAML'                                 => '1.29';
requires        'YAML::Syck'                           => '1.31';

conf_requires   'ExtUtils::MakeMaker'                  => '6.64';
test_requires   'Test::More'                           => '0.82';

WriteMakefile(
    NAME               => 'Task::Devel::Essentials',
    VERSION_FROM       => $module_filename,
    ABSTRACT_FROM      => $module_filename,
    LICENSE            => 'perl_5',
    AUTHOR             => 'Martin Becker <mhasch at cpan.org>',
    NO_META            => 0,
    CONFIGURE_REQUIRES => \%conf_requires,
    TEST_REQUIRES      => \%test_requires,
    MIN_PERL_VERSION   => '5.006',
    PREREQ_PM          => \%requires,
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => \%recommends,
            },
        },
        no_index => {
            directory => [
                'maint',
            ],
        }
    },
);
