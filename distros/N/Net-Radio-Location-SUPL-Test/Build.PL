use 5.010;
use strict;
use warnings;

use lib 'inc';
use Config;

use MyBuilder;

my $builder = MyBuilder->new(
    module_name       => 'Net::Radio::Location::SUPL::Test',
    license           => 'perl',
    dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from => 'lib/Net/Radio/Location/SUPL/Test.pm',
    build_requires    => {
                        'ExtUtils::CBuilder' => '0.27',
                        'ExtUtils::ParseXS'  => 0,
                        'Test::Differences'  => 0,        # XXX figure out really required version
                        'Test::More'         => '0.90',
                      },
    configure_requires => { 'Module::Build' => '0.38', },
    requires           => {
                  'perl'                              => 5.010,
                  'Config::Any'                       => 0,
                  'Digest::SHA'                       => 0,
                  'File::ConfigDir'                   => '0.003',
                  'File::Find::Rule'                  => '0.32',
		  'List::Util'                        => '1.19', # bundled with v5.10.0
                  'Log::Any'                          => '0.10',
                  'Log::Any::Adapter'                 => 0,
                  'Net::DBus'                         => '1.0.0',
                  'Net::Radio::Modem::Adapter::oFono' => 0.001,
                  'Params::Util'                      => '0.37',
                },
    auto_features => {
                       log4perl => {
                                     description => "Logging via Log::Log4perl",
                                     requires    => {
                                                   'Log::Log4perl'               => '1.00',
                                                   'Log::Any::Adapter::Log4perl' => 0,
                                                 }
                                   }
                     },
    add_to_cleanup => [ '*.o', 'asn1/*.dylib', 'asn1/*.so', 'asn1/*.dll', 'asn1/*.o', 'ULP_PDU-*' ],
                            );

$builder->create_build_script;

