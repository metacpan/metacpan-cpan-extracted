use 5.006;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_install_system {
      my $self = shift;

      $self->install_path(
	  'etc'  => '/etc/logparser',
	  'work' => '/var/lib/logparser',
	  'log'  => '/var/log/logparser'
	  );
      $self->{etc_files} = {
        'etc/log4perl.conf'  => 'etc/log4perl.conf',
        'etc/logparser.conf' => 'etc/logparser.conf'
	};
      $self->{log_files} = {'log/logparser.log' => 'log/logparser.log'};
      $self->{work_files} = {'work/logparser.properties' => 'work/logparser.properties'};
      $self->SUPER::ACTION_install;
}
SUBCLASS

my $build = $class->new(
#my $build = Module::Build->new(
    module_name        => 'SNMP::LogParser',
    sign               => 1,
    license            => 'perl',
    dist_author        => 'Nito Martinez <nito@qindel.es>',
    create_makefile_pl => 'passthrough',
    dist_version_from  => 'lib/SNMP/LogParser.pm',
    script_files       => ['bin/logparser'],

    configure_requires => {
        'Module::Build'              => 0,
    },
    build_requires => {
        'FindBin'                    => 0,
        'IPC::Run3'                  => 0,
        'Test::More'                 => 0,
        'Test::Pod::Coverage'        => 1.04,
        'Test::Pod'                  => 1.14,
        'Test::SharedFork'           => 0,
    },
    requires => {
        'Config::Properties::Simple' => 0.14,
        'Data::Dumper'               => 0,
        'Fcntl'                      => 0,
        'File::Spec'                 => 0,
        'File::Temp'                 => 0,
        'File::stat'                 => 0,
        'Getopt::Long'               => 0,
        'Log::Log4perl'              => 0,
        'Log::Dispatch::FileRotate'  => 0,
        'Pod::Usage'                 => 0,
        'Proc::ProcessTable'         => 0,
        'Statistics::Descriptive'    => 0,
        'Storable'                   => 0,
        'POSIX'                      => 0,
        'constant'                   => 0,
        'parent'                     => 0,
        'lib'                        => 0,
    },
);


$build->create_makefile_pl('traditional');
# $build->add_build_element('etc');
# $build->add_build_element('log');
# $build->add_build_element('work');
$build->create_build_script;
