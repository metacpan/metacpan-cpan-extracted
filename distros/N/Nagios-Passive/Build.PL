use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    meta_merge => {
        resources =>
          { repository => 'http://github.com/datamuc/Nagios-Passive', },
    },

    module_name       => 'Nagios::Passive',
    license           => 'perl',
    dist_author       => 'Danijel Tasov <data@cpan.org>',
    dist_version_from => 'lib/Nagios/Passive.pm',
    dist_abstract     => 'drop check results into nagios\' spool dir',
    create_license    => 1,
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires    => {
        'Test::More'    => 0,
        'Test::TempDir::Tiny' => 0,
    },
    requires => {
        'File::Temp'           => 0,
        'version'              => 0,
        'Moo'                  => 0,
        'MooX::late'           => 0,
        'Monitoring::Plugin'   => 0,
        'Class::Load'          => 0,
        'Crypt::Rijndael'      => 0,
        'MIME::Base64'         => 0,
        'Gearman::Client'      => 0,
        'Types::Standard'      => 0,
        'MooX::HandlesVia'     => 0,
        'perl'                 => '5.010',
    },
    add_to_cleanup => ['Nagios-Passive-*'],
);

$builder->create_build_script();
