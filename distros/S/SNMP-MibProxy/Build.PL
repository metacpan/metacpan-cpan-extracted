use Module::Build;
my $build = Module::Build->new(
     module_name => 'SNMP::MibProxy',
     sign => 1,
     license => 'perl',
     dist_author => 'Nito Martinez <nito@qindel.es>',
     create_makefile_pl => 'small',
     dist_version_from => 'lib/SNMP/MibProxy.pm',
     script_files => ['bin/mibProxy'],
     install_path => { 'etc' => '/etc/mibProxy',
                       'log' => '/var/log/mibProxy' },
     etc_files => { 'etc/mibProxy.conf' => 'etc/mibProxy.conf' },
     log_files => { 'log/mibProxy.log' => 'log/mibProxy.log' },
     configure_requires => {
        'Module::Build' => 0,
     },
     build_requires => {
        'Test::More' => 0,
        'IPC::Open2' => 0,
        'File::Temp' => 0,
        'Test::Pod::Coverage' => 1.04,
        'Test::Pod' => 1.14,
     },
     requires => {
        'Data::Dumper' => 0,
        'Getopt::Std' => 0,
        'Log::Log4perl' => 0,
        'Log::Dispatch::FileRotate' => 0,
        'Pod::Usage' => 0,
        'Config::Properties::Simple' => 0.14,
        'Config::Properties' => 0,
        'SNMP' => 0,
     },
);
$build->create_makefile_pl;
$build->add_build_element('etc');
$build->add_build_element('log');
$build->create_build_script;

