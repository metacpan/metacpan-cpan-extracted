# Copyright (c) 2013-2018 Martin Becker.  All rights reserved.
# This script is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    $ENV{'NYTPROF'} = 'start=no';
}

use inc::Module::Install;

name            'Task-Devel-Essentials';
license         'perl';
all_from        'lib/Task/Devel/Essentials.pm';

test_requires   'Test::More'                           => '0.82';

requires        'Data::Dumper'                         => '2.161';
requires        'ExtUtils::MakeMaker'                  => '7.34';
requires        'File::Temp'                           => '0.2306';
requires        'Getopt::Long'                         => '2.5';
requires        'Test::More'                           => '1.302136';
requires        'Kwalify'                              => '1.22';
requires        'Params::Check'                        => '0.38';
requires        'Term::ReadKey'                        => '2.37';
requires        'Term::ReadLine'                       => '1.14';
requires        'Test::Harness'                        => '3.42';
requires        'Data::Dumper::Simple'                 => '0.11';
requires        'Role::Basic'                          => '0.13';
requires        'JSON'                                 => '2.97001';
requires        'Encode'                               => '2.98';
requires        'Digest::SHA'                          => '6.02';
requires        'File::Which'                          => '1.22';
requires        'MIME::Base64'                         => '3.15';
requires        'Scalar::Util'                         => '1.50';
requires        'File::Spec'                           => '3.74';
requires        'IO::Compress::Base'                   => '2.081';
requires        'IO::Zlib'                             => '1.10';
requires        'Archive::Tar'                         => '2.30';
recommends      'Term::ReadLine::Gnu'                  => '1.35';
requires        'Text::Glob'                           => '0.11';
requires        'YAML::Syck'                           => '1.30';
requires        'Test::Portability::Files'             => '0.09';
requires        'Test::Requires'                       => '0.10';
requires        'Test::Signature'                      => '1.11';
requires        'Test::Simple'                         => '1.302136';
requires        'Test::NoWarnings'                     => '1.04';
requires        'YAML'                                 => '1.26';
requires        'Contextual::Return'                   => '0.004014';
requires        'Module::CoreList'                     => '5.20180622';
requires        'Devel::StackTrace'                    => '2.03';
requires        'MIME::Lite'                           => '3.030';
requires        'File::HomeDir'                        => '1.004';
requires        'Parse::CPAN::Meta'                    => '2.150010';
requires        'ExtUtils::CBuilder'                   => '0.280230';
requires        'Iterator::Diamond'                    => '1.01';
requires        'Module::Starter'                      => '1.75';
requires        'Readonly'                             => '2.05';
requires        'Module::Signature'                    => '0.81';
requires        'Net::FTP'                             => '3.11';
requires        'Test::Differences'                    => '0.64';
requires        'Devel::NYTProf'                       => '6.06';
requires        'Test::Exception'                      => '0.43';
requires        'Test::MockModule'                     => '0.15';
requires        'Archive::Zip'                         => '1.60';
requires        'Test::Output'                         => '1.031';
requires        'Test::Pod'                            => '1.52';
requires        'Test::Pod::Coverage'                  => '1.10';
requires        'Test::Regexp'                         => '2017040101';
requires        'Regexp::Common'                       => '2017060201';
requires        'Test::Warn'                           => '0.36';
requires        'Inline'                               => '0.80';
requires        'Try::Tiny'                            => '0.30';
requires        'Module::CPANTS::Analyse'              => '0.96';
requires        'App::CPANTS::Lint'                    => '0.05';
requires        'Test::Class'                          => '0.50';
requires        'Test::Fatal'                          => '0.014';
requires        'Data::Printer'                        => '0.40';
requires        'Moo'                                  => '2.003004';
requires        'Type::Tiny'                           => '1.002002';
requires        'Test::Reporter::Transport::Metabase'  => '1.999010';
requires        'Assert::Conditional'                  => '0.008';
requires        'Mouse'                                => '2.005004';
requires        'LWP'                                  => '6.34';
requires        'CPAN'                                 => '2.16';
requires        'CPAN::Reporter'                       => '1.2018';
requires        'Test2::Suite'                         => '0.000114';
requires        'File::ShareDir'                       => '1.116';
recommends      'List::MoreUtils::XS'                  => '0.428';
requires        'List::MoreUtils'                      => '0.428';
requires        'Perl::Critic'                         => '1.132';
requires        'Modern::Perl'                         => '1.20170117';
requires        'Module::Install'                      => '1.19';
requires        'Module::Version'                      => '0.12';
requires        'Devel::Cover'                         => '1.29';
requires        'Moose'                                => '2.2011';
requires        'DateTime'                             => '1.49';
requires        'Dist::Zilla'                          => '6.012';

no_index        'directory'                            => 'maint';

WriteAll;

