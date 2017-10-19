# Copyright (c) 2013-2017 Martin Becker.  All rights reserved.
# This script is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    $ENV{'NYTPROF'} = 'start=no';
}

use inc::Module::Install;

name            'Task-Devel-Essentials';
license         'perl';
all_from        'lib/Task/Devel/Essentials.pm';

test_requires   'Test::More'                     =>  '0.82';

requires        'App::CPANTS::Lint'              =>  '0.05';
requires        'Archive::Tar'                   =>  '2.26';
requires        'Archive::Zip'                   =>  '1.59';
requires        'Contextual::Return'             =>  '0.004014';
requires        'CPAN'                           =>  '2.18';
requires        'CPAN::Reporter'                 =>  '1.2018';
requires        'Data::Dumper'                   =>  '2.167';
requires        'Data::Dumper::Simple'           =>  '0.11';
requires        'Data::Printer'                  =>  '0.40';
requires        'DateTime'                       =>  '1.44';
requires        'Devel::Cover'                   =>  '1.29';
requires        'Devel::NYTProf'                 =>  '6.04';
requires        'Devel::StackTrace'              =>  '2.02';
requires        'Digest::SHA'                    =>  '5.98';
requires        'Encode'                         =>  '2.93';
requires        'ExtUtils::CBuilder'             =>  '0.280226';
requires        'ExtUtils::MakeMaker'            =>  '7.30';
requires        'File::HomeDir'                  =>  '1.002';
requires        'File::ShareDir'                 =>  '1.104';
requires        'File::Spec'                     =>  '3.67';
requires        'File::Temp'                     =>  '0.2304';
requires        'File::Which'                    =>  '1.22';
requires        'Getopt::Long'                   =>  '2.5';
requires        'Inline'                         =>  '0.80';
requires        'IO::Compress::Base'             =>  '2.074';
requires        'IO::Zlib'                       =>  '1.10';
requires        'Iterator::Diamond'              =>  '1.01';
requires        'JSON'                           =>  '2.94';
requires        'Kwalify'                        =>  '1.22';
requires        'List::MoreUtils'                =>  '0.426';
requires        'LWP'                            =>  '6.27';
requires        'MIME::Base64'                   =>  '3.15';
requires        'MIME::Lite'                     =>  '3.030';
requires        'Modern::Perl'                   =>  '1.20170117';
requires        'Module::CoreList'               =>  '5.20170923';
requires        'Module::CPANTS::Analyse'        =>  '0.96';
requires        'Module::Install'                =>  '1.18';
requires        'Module::Signature'              =>  '0.81';
requires        'Module::Starter'                =>  '1.73';
requires        'Module::Version'                =>  '0.12';
requires        'Moo'                            =>  '2.003002';
requires        'Moose'                          =>  '2.2006';
requires        'Net::FTP'                       =>  '3.10';
requires        'Params::Check'                  =>  '0.38';
requires        'Parse::CPAN::Meta'              =>  '2.150010';
requires        'Perl::Critic'                   =>  '1.130';
requires        'Regexp::Common'                 =>  '2017060201';
requires        'Role::Basic'                    =>  '0.13';
requires        'Scalar::Util'                   =>  '1.49';
requires        'Term::ReadKey'                  =>  '2.37';
requires        'Term::ReadLine'                 =>  '1.16';
recommends      'Term::ReadLine::Gnu'            =>  '1.34';
requires        'Test::Class'                    =>  '0.50';
requires        'Test::Differences'              =>  '0.64';
requires        'Test::Exception'                =>  '0.43';
requires        'Test::Harness'                  =>  '3.39';
requires        'Test::MockModule'               =>  '0.13';
requires        'Test::More'                     =>  '1.302103';
requires        'Test::Output'                   =>  '1.031';
requires        'Test::Pod'                      =>  '1.51';
requires        'Test::Pod::Coverage'            =>  '1.10';
requires        'Test::Portability::Files'       =>  '0.07';
requires        'Test::Regexp'                   =>  '2017040101';
requires        'Test::Reporter::Transport::Metabase' => '1.999010';
requires        'Test::Signature'                =>  '1.11';
requires        'Text::Glob'                     =>  '0.11';
requires        'Try::Tiny'                      =>  '0.28';
requires        'YAML'                           =>  '1.23';
requires        'YAML::Syck'                     =>  '1.30';

no_index        'directory'                      => 'maint';

WriteAll;

