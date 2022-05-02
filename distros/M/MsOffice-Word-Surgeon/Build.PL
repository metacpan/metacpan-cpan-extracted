use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'MsOffice::Word::Surgeon',
    license             => 'artistic_2',
    dist_author         => q{DAMI <dami@cpan.org>},
    dist_version_from   => 'lib/MsOffice/Word/Surgeon.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
      perl                        => '5.24.0',
      'Archive::Zip'              => undef,
      'Carp'                      => undef,
      'Encode'                    => undef,
      'List::Util'                => undef,
      'Moose'                     => undef,
      'MooseX::StrictConstructor' => undef,
      'XML::LibXML'               => undef,
      'namespace::clean'          => undef,
      'POSIX'                     => undef,
      'Exporter'                  => undef,
    },
    add_to_cleanup     => [ 'MsOffice-Word-Surgeon-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/MsOffice-Word-Surgeon',
       }
     },
);


$builder->add_build_element('docx');
$builder->create_build_script();
