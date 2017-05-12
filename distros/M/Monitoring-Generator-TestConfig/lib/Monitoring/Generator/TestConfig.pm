package Monitoring::Generator::TestConfig;

use 5.005;
use strict;
use warnings;
use Carp;
use POSIX qw(ceil);
use File::Which;
use Data::Dumper;
use Monitoring::Generator::TestConfig::ServiceCheckData;
use Monitoring::Generator::TestConfig::HostCheckData;
use Monitoring::Generator::TestConfig::InitScriptData;
use Monitoring::Generator::TestConfig::P1Data;
use Monitoring::Generator::TestConfig::Modules::Shinken;
use Monitoring::Generator::TestConfig::ShinkenInitScriptData;

our $VERSION = '0.46';

=head1 NAME

Monitoring::Generator::TestConfig - generate monitoring configurations (nagios/icinga/shinken)

=head1 SYNOPSIS

  use Monitoring::Generator::TestConfig;
  my $ngt = Monitoring::Generator::TestConfig->new( 'output_dir' => '/tmp/test_monitoring' );
  $ngt->create();

=head1 DESCRIPTION

This modul generates test configurations for your monitoring. This can be useful if you
want for doing load tests or testing addons and plugins.

=head1 CONSTRUCTOR

=over 4

=item new ( [ARGS] )

Creates an C<Monitoring::Generator::TestConfig> object. C<new> takes at least the output_dir.
Arguments are in key-value pairs.

    verbose                     verbose mode
    output_dir                  export directory
    overwrite_dir               overwrite contents of an existing directory. Default: false
    layout                      which config should be generated, valid options are "nagios", "icinga", "shinken" and "omd"
    user                        user, defaults to the current user
    group                       group, defaults to the current users group
    prefix                      prefix to all hosts / services
    binary                      path to your nagios/icinga bin
    hostcount                   amount of hosts to export, Default 10
    hostcheckcmd                use custom hostcheck command line
    servicecheckcmd             use custom servicecheck command line
    routercount                 amount of router to export, Default 5 ( exported as host and used as parent )
    services_per_host           amount of services per host, Default 10
    host_settings               key/value settings for use in the define host
    service_settings            key/value settings for use in the define service
    main_cfg                    overwrite/add settings from the nagios.cfg/icinga.cfg
    hostfailrate                chance of a host to fail, Default 2%
    servicefailrate             chance of a service to fail, Default 5%
    host_types                  key/value settings for percentage of hosttypes, possible keys are up,down,flap,random,block
    router_types                key/value settings for percentage of hosttypes for router
    service_types               key/value settings for percentage of servicetypes, possible keys are ok,warning,critical,unknown,flap,random,block
    skip_dependencys            no service dependencys will be exported

=back

=cut

########################################
sub new {
    my($class,%options) = @_;
    my $self = {
                    'verbose'             => 0,
                    'output_dir'          => undef,
                    'layout'              => undef,
                    'user'                => undef,
                    'group'               => undef,
                    'prefix'              => '',
                    'overwrite_dir'       => 0,
                    'binary'              => undef,
                    'routercount'         => 5,
                    'hostcount'           => 10,
                    'hostcheckcmd'        => undef,
                    'servicecheckcmd'     => undef,
                    'services_per_host'   => 10,
                    'main_cfg'            => {},
                    'host_settings'       => {},
                    'service_settings'    => {},
                    'servicefailrate'     => 5,
                    'hostfailrate'        => 2,
                    'skip_dependencys'    => 0,
                    'fixed_length'        => 0,
                    'router_types'        => {
                                    'down'         => 10,
                                    'up'           => 50,
                                    'flap'         => 10,
                                    'random'       => 20,
                                    'pending'      => 10,
                                    'block'        => 0,
                        },
                    'host_types'          => {
                                    'down'         => 5,
                                    'up'           => 50,
                                    'flap'         => 5,
                                    'random'       => 35,
                                    'pending'      => 5,
                                    'block'        => 0,
                        },
                    'service_types'       => {
                                    'ok'           => 50,
                                    'warning'      => 5,
                                    'unknown'      => 5,
                                    'critical'     => 5,
                                    'pending'      => 5,
                                    'flap'         => 5,
                                    'random'       => 25,
                                    'block'        => 0,
                        },
                };
    bless $self, $class;

    for my $opt_key (keys %options) {
        if(exists $self->{$opt_key}) {
            # set option to scalar because getopt now uses objects instead of scalars
            if(!defined $self->{$opt_key} and ref $options{$opt_key} eq '' and defined $options{$opt_key}) {
                $self->{$opt_key} = ''.$options{$opt_key};
            }
            elsif(ref $self->{$opt_key} eq ref $options{$opt_key}) {
                $self->{$opt_key} = $options{$opt_key};
            }
            elsif(ref $options{$opt_key} eq 'Getopt::Long::CallBack') {
                $self->{$opt_key} = ''.$options{$opt_key};
            }
            else {
                 croak('unknown type for option '.$opt_key.': '.(ref $options{$opt_key}));
            }
        }
        else {
            croak("unknown option: $opt_key");
        }
    }

    if(!defined $self->{'layout'}) {
        if(defined $ENV{'OMD_ROOT'}) {
            $self->{'layout'} = "omd";
        } else {
            $self->{'layout'} = "nagios";
        }
    }

    if($self->{'layout'} ne 'nagios' and $self->{'layout'} ne 'icinga' and $self->{'layout'} ne 'shinken' and $self->{'layout'} ne 'omd') {
        croak('valid layouts are: nagios, icinga, shinken and omd');
    }

    # set some defaults for OMD
    if($self->{'layout'} eq "omd") {
        if(!defined $ENV{'OMD_ROOT'}) {
            croak('please use omd layout only as OMD siteuser');
        }
        $self->{'output_dir'}       = $ENV{'OMD_ROOT'};
        $self->{'overwrite_dir'}    = 1;
        $self->{'binary'}           = $ENV{'OMD_ROOT'}."/bin/nagios";
        $self->{'user'}             = $ENV{'OMD_SITE'};
        $self->{'group'}            = $ENV{'OMD_SITE'};
        $self->{'prefix'}           = $ENV{'OMD_SITE'}."_";
    }

    if(!defined $self->{'output_dir'}) {
        croak('no output_dir given');
    }

    # strip off last slash
    $self->{'output_dir'} =~ s/\/$//mx;

    if(-e $self->{'output_dir'} and !$self->{'overwrite_dir'}) {
        croak('output_dir '.$self->{'output_dir'}.' does already exist and overwrite_dir not set');
    }

    # set some defaults
    my($user, $group);
    if($^O eq "MSWin32") {
        $user           = getlogin();
        $group          = "nagios";
    } else {
        $user           = getpwuid($<);
        my @userinfo    = getpwnam($user);
        my @groupinfo   = getgrgid($userinfo[3]);
        $group          = $groupinfo[0];
    }

    $self->{'user'}  = $user  unless defined $self->{'user'};
    $self->{'group'} = $group unless defined $self->{'group'};

    # we dont want the root user to run the core
    if($self->{'user'} eq 'root') {
        print STDERR "warning: root user is not recommended, using user '".$self->{'layout'}."' instead!\n";
        $self->{'user'}  = $self->{'layout'};
        $self->{'group'} = $self->{'layout'};
    }

    # try to find a binary in path
    if(!defined $self->{'binary'}) {
        my @possible_bin_locations;
        if($self->{'layout'} eq 'nagios') {
            $self->{'binary'} = which('nagios3') || which('nagios') || undef;
            @possible_bin_locations = qw|/usr/sbin/nagios3 /usr/bin/nagios3 /usr/local/bin/nagios3 /usr/sbin/nagios /usr/bin/nagios /usr/local/bin/nagios|;
        } elsif($self->{'layout'} eq 'icinga' ) {
            $self->{'binary'} = which('icinga') || undef;
            @possible_bin_locations = qw|/usr/sbin/icinga /usr/bin/icinga /usr/local/bin/icinga|;
        } elsif($self->{'layout'} eq 'shinken' ) {
            $self->{'binary'} = which('shinken-arbiter') || '/usr/local/shinken/bin/shinken-arbiter';
        }

        # still not defined?
        if(!defined $self->{'binary'}) {
            for my $loc (@possible_bin_locations) {
                if(-x $loc) {
                    $self->{'binary'} = $loc;
                    last;
                }
            }
        }
    }

    if(!defined $self->{'binary'}) {
        #carp('found no monitoring binary in path and none defined by the \'binary\' option, using fallback /usr/bin/nagios');
        $self->{'binary'} = '/usr/bin/nagios';
    }

    return $self;
}


########################################

=head1 METHODS

=over 4

=item create

 create()

 generates and writes the configuration
 Returns true on success or undef on errors.

=cut
sub create {
    my $self = shift;

    # set open umask, so the webserver can read those files
    umask(0022);

    if(!-d $self->{'output_dir'}."/.") {
        mkdir($self->{'output_dir'}) or croak('failed to create output_dir '.$self->{'output_dir'}.':'.$!);
    }

    # write out main config file
    unless($self->{'layout'} eq 'omd') {
        my $mainconfigfilename = $self->{'layout'}.'.cfg';
        open(my $fh, '>', $self->{'output_dir'}.'/'.$mainconfigfilename) or die('cannot write: '.$!);
        print $fh $self->_get_main_cfg();
        close $fh;
    }

    # create some missing dirs
    unless($self->{'layout'} eq 'omd') {
        for my $dir (qw{etc etc/conf.d var var/checkresults var/tmp plugins archives init.d}) {
            if(!-d $self->{'output_dir'}.'/'.$dir) {
                mkdir($self->{'output_dir'}.'/'.$dir)
                    or croak('failed to create dir ('.$self->{'output_dir'}.'/'.$dir.') :' .$!);
            }
        }
    }

    # export config files and plugins
    my $init = $self->{'layout'};
    my $objects = {};
    $objects = $self->_set_hosts_cfg($objects);
    $objects = $self->_set_hostgroups_cfg($objects);
    $objects = $self->_set_services_cfg($objects);
    $objects = $self->_set_servicegroups_cfg($objects);
    $objects = $self->_set_contacts_cfg($objects);
    $objects = $self->_set_commands_cfg($objects);
    $objects = $self->_set_timeperiods_cfg($objects);
    my $obj_prefix = '/etc/conf.d';
    my $plg_prefix = '/plugins';
    if($self->{'layout'} eq 'omd') {
        $obj_prefix = '/etc/nagios/conf.d/generated';
        $plg_prefix = '/local/lib/nagios/plugins';
    }
    my $exportedFiles = [
        { file => $obj_prefix.'/hosts.cfg',            data => $self->_create_object_conf('host',          $objects->{'host'})              },
        { file => $obj_prefix.'/hostgroups.cfg',       data => $self->_create_object_conf('hostgroup',     $objects->{'hostgroup'})         },
        { file => $obj_prefix.'/services.cfg',         data => $self->_create_object_conf('service',       $objects->{'service'})           },
        { file => $obj_prefix.'/servicegroups.cfg',    data => $self->_create_object_conf('servicegroup',  $objects->{'servicegroup'})      },
        { file => $obj_prefix.'/contacts.cfg',         data => $self->_create_object_conf('contactgroup',  $objects->{'contactgroup'})
                                                              .$self->_create_object_conf('contact',       $objects->{'contact'})           },
        { file => $obj_prefix.'/commands.cfg',         data => $self->_create_object_conf('command',       $objects->{'command'})           },
        { file => $plg_prefix.'/test_servicecheck.pl', data => Monitoring::Generator::TestConfig::ServiceCheckData->get_test_servicecheck() },
        { file => $plg_prefix.'/test_hostcheck.pl',    data => Monitoring::Generator::TestConfig::HostCheckData->get_test_hostcheck()       },
        { file => '/recreate.pl',                      data => $self->_get_recreate_pl($self->_get_used_libs($self->{'output_dir'}.'/recreate.pl')) },
    ];

    if($self->{'layout'} ne 'omd') {
        push(@{$exportedFiles}, { file => $obj_prefix.'/timeperiods.cfg',   data => $self->_create_object_conf('timeperiod',    $objects->{'timeperiod'})   });
        push(@{$exportedFiles}, { file => '/etc/resource.cfg',              data => '$USER1$='.$self->{'output_dir'}."/plugins\n" });
    }

    if ($self->{'layout'} eq 'nagios' or $self->{'layout'} eq 'icinga') {
        push(@{$exportedFiles}, { file => '/plugins/p1.pl',  data => Monitoring::Generator::TestConfig::P1Data->get_p1_script() });
        push(@{$exportedFiles}, { file => '/init.d/'.$init,  data => Monitoring::Generator::TestConfig::InitScriptData->get_init_script(
                            $self->{'output_dir'},
                            $self->{'binary'},
                            $self->{'user'},
                            $self->{'group'},
                            $self->{'layout'}
                  )});
    }
    if ($self->{'layout'} eq 'shinken') {
        push(@{$exportedFiles}, { file => '/etc/shinken-specific.cfg',  data => Monitoring::Generator::TestConfig::Modules::Shinken::_get_shinken_specific_cfg($self) });
        push(@{$exportedFiles}, { file => '/etc/schedulerd.cfg',        data => Monitoring::Generator::TestConfig::Modules::Shinken::_get_shinken_schedulerd_cfg($self) });
        push(@{$exportedFiles}, { file => '/etc/pollerd.cfg',           data => Monitoring::Generator::TestConfig::Modules::Shinken::_get_shinken_pollerd_cfg($self) });
        push(@{$exportedFiles}, { file => '/etc/brokerd.cfg',           data => Monitoring::Generator::TestConfig::Modules::Shinken::_get_shinken_brokerd_cfg($self) });
        push(@{$exportedFiles}, { file => '/etc/reactionnerd.cfg',      data => Monitoring::Generator::TestConfig::Modules::Shinken::_get_shinken_reactionnerd_cfg($self) });
        push(@{$exportedFiles}, { file => '/init.d/'.$init,             data => Monitoring::Generator::TestConfig::ShinkenInitScriptData->get_init_script(
                            $self->{'output_dir'},
                            $self->{'binary'},
        ) });
    }

    # export service dependencies
    my $servicedependency = "";
    unless ($self->{'skip_dependencys'} ) {
        $objects = $self->_set_servicedependency_cfg($objects);
        $servicedependency = $self->_create_object_conf('servicedependency', $objects->{'servicedependency'});
    }
    push(@{$exportedFiles}, { file => $obj_prefix.'/dependencies.cfg', data => $servicedependency });

    if( !-d $self->{'output_dir'}."/".$obj_prefix ) {
        mkdir($self->{'output_dir'}."/".$obj_prefix) or croak('failed to create output_dir '.$self->{'output_dir'}."/".$obj_prefix.':'.$!);
    }

    for my $exportFile (@{$exportedFiles}) {
        open(my $fh, '>', $self->{'output_dir'}.$exportFile->{'file'}) or die('cannot write '.$self->{'output_dir'}.$exportFile->{'file'}.': '.$!);
        print $fh $exportFile->{'data'};
        close $fh;
    }

    chmod 0755, $self->{'output_dir'}.$plg_prefix.'/test_servicecheck.pl' or die("cannot change modes: $!");
    chmod 0755, $self->{'output_dir'}.$plg_prefix.'/test_hostcheck.pl'    or die("cannot change modes: $!");
    chmod 0755, $self->{'output_dir'}.'/plugins/p1.pl';
    chmod 0755, $self->{'output_dir'}.'/init.d/'.$init;
    chmod 0755, $self->{'output_dir'}.'/recreate.pl';

    # check user/group
    if( $^O ne "MSWin32" and $< == 0 ) {
        `chown -R $self->{'user'}:$self->{'group'} $self->{'output_dir'}`;
    }

    if($self->{'layout'} eq 'omd') {
        print "exported omd test config to: ".$self->{'output_dir'}.$obj_prefix."\n";
        print "check your configuration with: ~/etc/init.d/nagios checkconfig\n";
    } else {
        print "exported ".$self->{'layout'}." test config to: $self->{'output_dir'}\n";
        print "check your configuration with: $self->{'output_dir'}/init.d/".$init." checkconfig\n";
    }
    print "configuration can be adjusted and recreated with $self->{'output_dir'}/recreate.pl\n";

    return 1;
}


########################################
sub _set_hosts_cfg {
    my $self    = shift;
    my $objects = shift;

    $objects->{'host'} = [] unless defined $objects->{'host'};

    my $hostconfig = {
        'name'                           => 'generic-mgt-test-host',
        'notifications_enabled'          => 1,
        'event_handler_enabled'          => 1,
        'flap_detection_enabled'         => 1,
        'failure_prediction_enabled'     => 1,
        'process_perf_data'              => 1,
        'retain_status_information'      => 1,
        'retain_nonstatus_information'   => 1,
        'max_check_attempts'             => 5,
        'check_interval'                 => 1,
        'retry_interval'                 => 1,
        'check_period'                   => '24x7',
        'notification_interval'          => 0,
        'notification_period'            => '24x7',
        'notification_options'           => 'd,u,r',
        'contact_groups'                 => 'test_contact',
        'register'                       => 0,
    };

    my $merged = $self->_merge_config_hashes($hostconfig, $self->{'host_settings'});
    push @{$objects->{'host'}}, $merged;
    my @router;

    # router
    if($self->{'routercount'} > 0) {
        my @routertypes = @{$self->_fisher_yates_shuffle($self->_get_types($self->{'routercount'}, $self->{'router_types'}))};

        my $nr_length = $self->{'fixed_length'} || length($self->{'routercount'});
        for(my $x = 0; $x < $self->{'routercount'}; $x++) {
            my $hostgroup = "router";
            my $nr        = sprintf("%0".$nr_length."d", $x);
            my $type      = shift @routertypes;
            push @router, $self->{'prefix'}."router_$nr";

            my $host = {
                'host_name'     => $self->{'prefix'}."router_".$nr,
                'alias'         => $self->{'prefix'}.$type."_".$nr,
                'use'           => 'generic-mgt-test-host',
                'address'       => '127.0.'.$x.'.1',
                'hostgroups'    => $hostgroup,
                'check_command' => 'test-check-host-alive!'.$type,
                'icon_image'    => '../../docs/images/switch.png',
            };
            $host->{'active_checks_enabled'} = '0' if $type eq 'pending';

            # first router gets additional infos
            if($x == 0) {
                $host->{'notes_url'}      = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/README';
                $host->{'notes'}          = 'just a notes string';
                $host->{'icon_image_alt'} = 'icon alt string';
                $host->{'action_url'}     = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/';
            }
            if($x == 1) {
                $host->{'notes_url'}      = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/README';
                $host->{'action_url'}     = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/';
            }
            if($x == 2) {
                $host->{'notes_url'}      = 'http://google.com/?q=$HOSTNAME$';
                $host->{'action_url'}     = 'http://google.com/?q=$HOSTNAME$';
            }

            $host = $self->_merge_config_hashes($host, $self->{'host_settings'});
            push @{$objects->{'host'}}, $host;
        }
    }

    # hosts
    my @hosttypes = @{$self->_fisher_yates_shuffle($self->_get_types($self->{'hostcount'}, $self->{'host_types'}))};

    my $nr_length = $self->{'fixed_length'} || length($self->{'hostcount'});
    for(my $x = 0; $x < $self->{'hostcount'}; $x++) {
        my $hostgroup = "hostgroup_01";
        $hostgroup    = "hostgroup_02" if $x%5 == 1;
        $hostgroup    = "hostgroup_03" if $x%5 == 2;
        $hostgroup    = "hostgroup_04" if $x%5 == 3;
        $hostgroup    = "hostgroup_05" if $x%5 == 4;
        my $nr        = sprintf("%0".$nr_length."d", $x);
        my $type      = shift @hosttypes;
        my $num_router = scalar @router + 1;
        my $cur_router = $x % $num_router;
        my $host = {
            'host_name'     => $self->{'prefix'}."host_".$nr,
            'alias'         => $self->{'prefix'}.$type."_".$nr,
            'use'           => 'generic-mgt-test-host',
            'address'       => '127.0.'.$cur_router.'.'.($x + 1),
            'hostgroups'    => $hostgroup.','.$type,
            'check_command' => 'test-check-host-alive!'.$type,
        };
        if(defined $router[$cur_router]) {
            $host->{'parents'}       = $router[$cur_router];
            $host->{'check_command'} = 'test-check-host-alive-parent!'.$type.'!$HOSTSTATE:'.$router[$cur_router].'$';
        }
        $host->{'active_checks_enabled'} = '0' if $type eq 'pending';

        $host = $self->_merge_config_hashes($host, $self->{'host_settings'});
        push @{$objects->{'host'}}, $host;
    }

    return($objects);
}

########################################
sub _set_hostgroups_cfg {
    my $self    = shift;
    my $objects = shift;

    $objects->{'hostgroup'} = [] unless defined $objects->{'hostgroup'};
    push @{$objects->{'hostgroup'}},
        { hostgroup_name => 'router',          alias => 'All Router Hosts'   },
        { hostgroup_name => 'hostgroup_01',    alias => 'hostgroup_alias_01' },
        { hostgroup_name => 'hostgroup_02',    alias => 'hostgroup_alias_02' },
        { hostgroup_name => 'hostgroup_03',    alias => 'hostgroup_alias_03' },
        { hostgroup_name => 'hostgroup_04',    alias => 'hostgroup_alias_04' },
        { hostgroup_name => 'hostgroup_05',    alias => 'hostgroup_alias_05' },
        { hostgroup_name => 'up',              alias => 'All Up Hosts'       },
        { hostgroup_name => 'down',            alias => 'All Down Hosts'     },
        { hostgroup_name => 'pending',         alias => 'All Pending Hosts'  },
        { hostgroup_name => 'random',          alias => 'All Random Hosts'   },
        { hostgroup_name => 'flap',            alias => 'All Flapping Hosts' },
        { hostgroup_name => 'block',           alias => 'All Blocking Hosts' };

    return($objects);
}

########################################
sub _set_services_cfg {
    my $self = shift;
    my $objects = shift;

    $objects->{'service'} = [] unless defined $objects->{'service'};

    my $serviceconfig = {
        'name'                            => 'generic-mgt-test-service',
        'active_checks_enabled'           => 1,
        'passive_checks_enabled'          => 1,
        'parallelize_check'               => 1,
        'obsess_over_service'             => 1,
        'check_freshness'                 => 0,
        'notifications_enabled'           => 1,
        'event_handler_enabled'           => 1,
        'flap_detection_enabled'          => 1,
        'failure_prediction_enabled'      => 1,
        'process_perf_data'               => 1,
        'retain_status_information'       => 1,
        'retain_nonstatus_information'    => 1,
        'notification_interval'           => 0,
        'is_volatile'                     => 0,
        'check_period'                    => '24x7',
        'check_interval'                  => 1,
        'retry_interval'                  => 1,
        'max_check_attempts'              => 3,
        'notification_period'             => '24x7',
        'notification_options'            => 'w,u,c,r',
        'contact_groups'                  => 'test_contact',
        'register'                        => 0,
    };

    my $merged = $self->_merge_config_hashes($serviceconfig, $self->{'service_settings'});
    push @{$objects->{'service'}}, $merged;

    my @servicetypes = @{$self->_fisher_yates_shuffle($self->_get_types($self->{'hostcount'} * $self->{'services_per_host'}, $self->{'service_types'}))};

    my $hostnr_length    = $self->{'fixed_length'} || length($self->{'hostcount'});
    my $servicenr_length = $self->{'fixed_length'} || length($self->{'services_per_host'});
    for(my $x = 0; $x < $self->{'hostcount'}; $x++) {
        my $host_nr = sprintf("%0".$hostnr_length."d", $x);
        for(my $y = 0; $y < $self->{'services_per_host'}; $y++) {
            my $service_nr   = sprintf("%0".$servicenr_length."d", $y);
            my $servicegroup = "servicegroup_01";
            $servicegroup    = "servicegroup_02" if $y%5 == 1;
            $servicegroup    = "servicegroup_03" if $y%5 == 2;
            $servicegroup    = "servicegroup_04" if $y%5 == 3;
            $servicegroup    = "servicegroup_05" if $y%5 == 4;
            my $type         = shift @servicetypes;

            my $service = {
                'host_name'             => $self->{'prefix'}."host_".$host_nr,
                'service_description'   => $self->{'prefix'}.$type."_".$service_nr,
                'check_command'         => 'check_service!'.$type,
                'use'                   => 'generic-mgt-test-service',
                'servicegroups'         => $servicegroup.','.$type,
            };

            $service->{'active_checks_enabled'} = '0' if $type eq 'pending';

            # first router gets additional infos
            if($y == 0) {
                $service->{'notes_url'}      = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/README';
                $service->{'notes'}          = 'just a notes string';
                $service->{'icon_image_alt'} = 'icon alt string';
                $service->{'icon_image'}     = 'tux.png';
                $service->{'action_url'}     = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/';
            }
            if($y == 1) {
                $service->{'notes_url'}      = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/README';
                $service->{'action_url'}     = 'http://search.cpan.org/dist/Monitoring-Generator-TestConfig/';
            }
            if($y == 2) {
                $service->{'notes_url'}      = 'http://google.com/?q=$HOSTNAME$';
                $service->{'action_url'}     = 'http://google.com/?q=$HOSTNAME$';
            }

            $service = $self->_merge_config_hashes($service, $self->{'service_settings'});
            push @{$objects->{'service'}}, $service;
        }
    }

    return($objects);
}

########################################
sub _set_servicegroups_cfg {
    my $self = shift;
    my $objects = shift;

    $objects->{'servicegroup'} = [] unless defined $objects->{'servicegroup'};
    push @{$objects->{'servicegroup'}},
        { servicegroup_name => 'servicegroup_01', alias => 'servicegroup_alias_01' },
        { servicegroup_name => 'servicegroup_02', alias => 'servicegroup_alias_02' },
        { servicegroup_name => 'servicegroup_03', alias => 'servicegroup_alias_03' },
        { servicegroup_name => 'servicegroup_04', alias => 'servicegroup_alias_04' },
        { servicegroup_name => 'servicegroup_05', alias => 'servicegroup_alias_05' },
        { servicegroup_name => 'ok',              alias => 'All Ok Services'       },
        { servicegroup_name => 'warning',         alias => 'All Warning Services'  },
        { servicegroup_name => 'unknown',         alias => 'All Unknown Services'  },
        { servicegroup_name => 'critical',        alias => 'All Critical Services' },
        { servicegroup_name => 'pending',         alias => 'All Pending Services'  },
        { servicegroup_name => 'random',          alias => 'All Random Services'   },
        { servicegroup_name => 'flap',            alias => 'All Flapping Services' },
        { servicegroup_name => 'block',           alias => 'All Blocking Services' };

    return($objects);
}

########################################
sub _set_servicedependency_cfg {
    my $self = shift;
    my $objects = shift;

    $objects->{'servicedependency'} = [] unless defined $objects->{'servicedependency'};

    my $service_size = scalar @{$objects->{'service'}};
    for(my $x = 2; $x < $service_size; $x+=5) {
        my $dependent = $objects->{'service'}->[$x];
        my $master    = $objects->{'service'}->[$x-1];
        next unless defined $dependent->{'host_name'};
        next unless defined $master->{'host_name'};

        push @{$objects->{'servicedependency'}}, {
            'dependent_host_name'           => $dependent->{'host_name'},
            'dependent_service_description' => $dependent->{'service_description'},
            'host_name'                     => $master->{'host_name'},
            'service_description'           => $master->{'service_description'},
            'execution_failure_criteria'    => 'w,u,c',
            'notification_failure_criteria' => 'w,u,c',
        };
    }

    return $objects;
}

########################################
sub _set_contacts_cfg {
    my $self    = shift;
    my $objects = shift;

    $objects->{'contactgroup'} = [] unless defined $objects->{'contactgroup'};
    push @{$objects->{'contactgroup'}}, {
        'contactgroup_name'  => 'test_contact',
        'alias'              => 'test_contacts_alias',
        'members'            => 'test_contact',
    };

    $objects->{'contact'} = [] unless defined $objects->{'contact'};
    push @{$objects->{'contact'}}, {
        'contact_name'                  => 'test_contact',
        'alias'                         => 'test_contact_alias',
        'service_notification_period'   => '24x7',
        'host_notification_period'      => '24x7',
        'service_notification_options'  => 'w,u,c,r',
        'host_notification_options'     => 'd,r',
        'service_notification_commands' => 'notify-service',
        'host_notification_commands'    => 'notify-host',
        'email'                         => 'nobody@localhost',
    };

    return($objects);
}

########################################
sub _set_commands_cfg {
    my $self    = shift;
    my $objects = shift;

    my $usr_macro = "USER1";
    if($self->{'layout'} eq 'omd') {
        $usr_macro = "USER2";
    }

    $objects->{'command'} = [] unless defined $objects->{'command'};
    push @{$objects->{'command'}}, {
        'command_name' => 'test-check-host-alive',
        'command_line' => (defined $self->{'hostcheckcmd'} ? $self->{'hostcheckcmd'} : '$'.$usr_macro.'$/test_hostcheck.pl --type=$ARG1$ --failchance='.$self->{'hostfailrate'}.'% --previous-state=$HOSTSTATE$ --state-duration=$HOSTDURATIONSEC$ --hostname $HOSTNAME$'),
    }, {
        'command_name' => 'test-check-host-alive-parent',
        'command_line' => (defined $self->{'hostcheckcmd'} ? $self->{'hostcheckcmd'} : '$'.$usr_macro.'$/test_hostcheck.pl --type=$ARG1$ --failchance='.$self->{'hostfailrate'}.'% --previous-state=$HOSTSTATE$ --state-duration=$HOSTDURATIONSEC$ --parent-state=$ARG2$ --hostname $HOSTNAME$'),
    }, {
        'command_name' => 'notify-host',
        'command_line' => 'sleep 1 && /bin/true',
    }, {
        'command_name' => 'notify-service',
        'command_line' => 'sleep 1 && /bin/true',
    }, {
        'command_name' => 'check_service',
        'command_line' => (defined $self->{'servicecheckcmd'} ? $self->{'servicecheckcmd'} : '$'.$usr_macro.'$/test_servicecheck.pl --type=$ARG1$ --failchance='.$self->{'servicefailrate'}.'% --previous-state=$SERVICESTATE$ --state-duration=$SERVICEDURATIONSEC$ --total-critical-on-host=$TOTALHOSTSERVICESCRITICAL$ --total-warning-on-host=$TOTALHOSTSERVICESWARNING$ --hostname $HOSTNAME$ --servicedesc $SERVICEDESC$'),
    };

    return($objects);
}

########################################
sub _set_timeperiods_cfg {
    my $self    = shift;
    my $objects = shift;

    $objects->{'timeperiod'} = [] unless defined $objects->{'timeperiod'};
    push @{$objects->{'timeperiod'}}, {
        'timeperiod_name' => '24x7',
        'alias'           => '24 Hours A Day, 7 Days A Week',
        'sunday'          => '00:00-24:00',
        'monday'          => '00:00-24:00',
        'tuesday'         => '00:00-24:00',
        'wednesday'       => '00:00-24:00',
        'thursday'        => '00:00-24:00',
        'friday'          => '00:00-24:00',
        'saturday'        => '00:00-24:00',
    };

    return($objects);
}

########################################
sub _get_main_cfg {
    my $self = shift;

    my $main_cfg = {
        'log_file'                                      => $self->{'output_dir'}.'/var/'.$self->{'layout'}.'.log',
        'cfg_dir'                                       => $self->{'output_dir'}.'/etc/conf.d',
        'object_cache_file'                             => $self->{'output_dir'}.'/var/objects.cache',
        'precached_object_file'                         => $self->{'output_dir'}.'/var/objects.precache',
        'resource_file'                                 => $self->{'output_dir'}.'/etc/resource.cfg',
        'status_file'                                   => $self->{'output_dir'}.'/var/status.dat',
        'status_update_interval'                        => 30,
        $self->{'layout'}.'_user'                       => $self->{'user'},
        $self->{'layout'}.'_group'                      => $self->{'group'},
        'check_external_commands'                       => 1,
        'command_check_interval'                        => -1,
        'command_file'                                  => $self->{'output_dir'}.'/var/'.$self->{'layout'}.'.cmd',
        'external_command_buffer_slots'                 => 4096,
        'lock_file'                                     => $self->{'output_dir'}.'/var/'.$self->{'layout'}.'.pid',
        'temp_file'                                     => $self->{'output_dir'}.'/var/tmp/'.$self->{'layout'}.'.tmp',
        'temp_path'                                     => $self->{'output_dir'}.'/var/tmp',
        'event_broker_options'                          =>-1,
        'log_rotation_method'                           =>'d',
        'log_archive_path'                              => $self->{'output_dir'}.'/archives',
        'use_syslog'                                    => 0,
        'log_notifications'                             => 1,
        'log_service_retries'                           => 1,
        'log_host_retries'                              => 1,
        'log_event_handlers'                            => 1,
        'log_initial_states'                            => 0,
        'log_external_commands'                         => 1,
        'log_passive_checks'                            => 1,
        'service_inter_check_delay_method'              => 's',
        'max_service_check_spread'                      => 30,
        'service_interleave_factor'                     => 's',
        'host_inter_check_delay_method'                 => 's',
        'max_host_check_spread'                         => 30,
        'max_concurrent_checks'                         => 0,
        'check_result_reaper_frequency'                 => 10,
        'max_check_result_reaper_time'                  => 30,
        'check_result_path'                             => $self->{'output_dir'}.'/var/checkresults',
        'max_check_result_file_age'                     => 3600,
        'cached_host_check_horizon'                     => 15,
        'cached_service_check_horizon'                  => 15,
        'enable_predictive_host_dependency_checks'      => 1,
        'enable_predictive_service_dependency_checks'   => 1,
        'soft_state_dependencies'                       => 0,
        'auto_reschedule_checks'                        => 0,
        'auto_rescheduling_interval'                    => 30,
        'auto_rescheduling_window'                      => 180,
        'sleep_time'                                    => 0.25,
        'service_check_timeout'                         => 60,
        'host_check_timeout'                            => 30,
        'event_handler_timeout'                         => 30,
        'notification_timeout'                          => 30,
        'ocsp_timeout'                                  => 5,
        'perfdata_timeout'                              => 5,
        'retain_state_information'                      => 1,
        'state_retention_file'                          => $self->{'output_dir'}.'/var/retention.dat',
        'retention_update_interval'                     => 60,
        'use_retained_program_state'                    => 1,
        'use_retained_scheduling_info'                  => 1,
        'retained_host_attribute_mask'                  => 0,
        'retained_service_attribute_mask'               => 0,
        'retained_process_host_attribute_mask'          => 0,
        'retained_process_service_attribute_mask'       => 0,
        'retained_contact_host_attribute_mask'          => 0,
        'retained_contact_service_attribute_mask'       => 0,
        'interval_length'                               => 60,
        'use_aggressive_host_checking'                  => 0,
        'execute_service_checks'                        => 1,
        'accept_passive_service_checks'                 => 1,
        'execute_host_checks'                           => 1,
        'accept_passive_host_checks'                    => 1,
        'enable_notifications'                          => 1,
        'enable_event_handlers'                         => 1,
        'process_performance_data'                      => 0,
        'obsess_over_services'                          => 0,
        'obsess_over_hosts'                             => 0,
        'translate_passive_host_checks'                 => 0,
        'passive_host_checks_are_soft'                  => 0,
        'check_for_orphaned_services'                   => 1,
        'check_for_orphaned_hosts'                      => 1,
        'check_service_freshness'                       => 1,
        'service_freshness_check_interval'              => 60,
        'check_host_freshness'                          => 0,
        'host_freshness_check_interval'                 => 60,
        'additional_freshness_latency'                  => 15,
        'enable_flap_detection'                         => 1,
        'low_service_flap_threshold'                    => 5.0,
        'high_service_flap_threshold'                   => 20.0,
        'low_host_flap_threshold'                       => 5.0,
        'high_host_flap_threshold'                      => 20.0,
        'date_format'                                   => 'iso8601',
        'p1_file'                                       => $self->{'output_dir'}.'/plugins/p1.pl',
        'enable_embedded_perl'                          => 1,
        'use_embedded_perl_implicitly'                  => 1,
        'illegal_object_name_chars'                     => '`~!\\$%^&*|\'"<>?,()=',
        'illegal_macro_output_chars'                    => '`~\\$&|\'"<>',
        'use_regexp_matching'                           => 0,
        'use_true_regexp_matching'                      => 0,
        'admin_email'                                   => $self->{'user'}.'@localhost',
        'admin_pager'                                   => $self->{'user'}.'@localhost',
        'daemon_dumps_core'                             => 0,
        'use_large_installation_tweaks'                 => 0,
        'enable_environment_macros'                     => 1,
        'debug_level'                                   => 0,
        'debug_verbosity'                               => 1,
        'debug_file'                                    => $self->{'output_dir'}.'/var/'.$self->{'layout'}.'.debug',
        'max_debug_file_size'                           => 1000000,
    };

    $main_cfg->{'use_large_installation_tweaks'} = 1 if ($self->{'hostcount'} * $self->{'services_per_host'} > 2000);

    my $merged     = $self->_merge_config_hashes($main_cfg, $self->{'main_cfg'});
    my $confstring = $self->_config_hash_to_string($merged);
    return($confstring);
}

########################################

sub _merge_config_hashes {
    my $self    = shift;
    my $conf1   = shift;
    my $conf2   = shift;
    my $merged;

    for my $key (keys %{$conf1}) {
        $merged->{$key} = $conf1->{$key};
    }
    for my $key (keys %{$conf2}) {
        $merged->{$key} = $conf2->{$key};
    }

    return($merged);
}


########################################
sub _config_hash_to_string {
    my $self = shift;
    my $conf = shift;
    my $confstring;

    for my $key (sort keys %{$conf}) {
        my $value = $conf->{$key};
        if(ref($value) eq 'ARRAY') {
            for my $newval (@{$value}) {
                $confstring .= $key."=".$newval."\n";
            }
        } else {
            $confstring .= $key."=".$value."\n";
        }
    }

    return($confstring);
}


########################################
sub _create_object_conf {
    my $self    = shift;
    my $type    = shift;
    my $objects = shift;

    my $cfg = "";
    return $cfg unless defined $objects;

    for my $obj (@{$objects}) {
        $cfg .= 'define '.$type."{\n";
        for my $key (sort _sort_object_key keys %{$obj}) {
            my $value = $obj->{$key};
            $cfg .= '  '.sprintf("%-30s", $key)." ".$value."\n";
        }
        $cfg .= "}\n\n";
    }

    return($cfg);
}


########################################
sub _fisher_yates_shuffle {
    my $self  = shift;
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
    return($array);
}


########################################
sub _get_types {
    my $self  = shift;
    my $count = shift;
    my $types = shift;

    my $total = 0;
    for my $type (keys %{$types}) {
        $total += $types->{$type};
    }

    my @types;
    for my $type (keys %{$types}) {
        my $perc = $types->{$type};
        for(1..ceil($count/$total*$perc)) {
            push @types, $type;
        }
    }
    if(scalar @types < $count) {
        warn("got only ".scalar @types." types, expected ".$count);
    }
    return(\@types);
}

########################################
sub _get_recreate_pl {
    my $self  = shift;
    my $libs  = shift || '';
    my $pl;

    $Data::Dumper::Sortkeys = 1;
    my $conf =  Dumper($self);
    $conf    =~ s/^\$VAR1\ =\ bless\(\ \{//mx;
    $conf    =~ s/},\ 'Monitoring::Generator::TestConfig'\ \);$//mx;

    $pl  = <<EOT;
#!$^X
$libs
use Monitoring::Generator::TestConfig;
my \$ngt = Monitoring::Generator::TestConfig->new(
$conf
);
\$ngt->create();
EOT

    return $pl;
}


########################################
sub _sort_object_key {
    return -7 if $a eq 'dependent_service_description';
    return -6 if $a eq 'dependent_host_name';
    return -5 if $a eq 'name';
    return -4 if $a =~ m/_name$/mx;
    return -3 if $a =~ m/_description$/mx;
    return -2 if $a eq 'use';

    return 7 if $b eq 'dependent_service_description';
    return 6 if $b eq 'dependent_host_name';
    return 5 if $b eq 'name';
    return 4 if $b =~ m/_name$/mx;
    return 3 if $b =~ m/_description$/mx;
    return 2 if $b eq 'use';

    return $a cmp $b;
}

########################################
sub _get_used_libs {
    my($self, $file) = @_;
    my $libs = '';
    return $libs unless -r $file;
    open(my $fh, '<', $file) or die('cannot read file '.$file.': '.$!);
    while(my $line = <$fh>) {
        next unless $line =~ m/^\s*use\s+lib\s+/gmx;
        $libs .= $line;
    }
    close($fh);
    return $libs;
}

1;

__END__

=back

=head1 EXAMPLE

=head2 OMD Users

Using OMD makes generating test configs really easy:

    #> create site test
    #> su - test
    OMD[test]:~$ cpan
    ...
    Would you like me to configure as much as possible automatically? [yes] <enter>
    ...
    cpan[1]> install Monitoring::Generator::TestConfig
    ...
    cpan[2]> exit
    OMD[test]:~$ ./local/lib/perl5/bin/create_monitoring_test_config.pl

After the first installation, configuration can be adjusted in the recreate.pl in your SITE directory.

=head2 Sample Script

Create a sample config with manually overriden host/service settings:

    use Monitoring::Generator::TestConfig;
    my $mgt = Monitoring::Generator::TestConfig->new(
                        'output_dir'                => '/tmp/test-conf',
                        'verbose'                   => 1,
                        'overwrite_dir'             => 1,
                        'user'                      => 'testuser',
                        'group'                     => 'users',
                        'hostcount'                 => 50,
                        'services_per_host'         => 20,
                        'main_cfg'                  => {
                                'debug_level'     => 1,
                                'debug_verbosity' => 1,
                            },
                        'hostfailrate'              => 2, # percentage (only for the random ones)
                        'servicefailrate'           => 5, # percentage (only for the random ones)
                        'host_settings'             => {
                                'normal_check_interval' => 10,
                                'retry_check_interval'  => 1,
                            },
                        'service_settings'          => {
                                'normal_check_interval' => 10,
                                'retry_check_interval'  => 2,
                            },
                        'host_types'                => {
                                        'down'         => 5, # percentage
                                        'up'           => 50,
                                        'flap'         => 5,
                                        'pending'      => 5,
                                        'random'       => 30,
                                        'block'        => 5,
                            },
                        'service_types'             => {
                                        'ok'           => 50, # percentage
                                        'warning'      => 5,
                                        'unknown'      => 5,
                                        'critical'     => 5,
                                        'pending'      => 5,
                                        'flap'         => 5,
                                        'random'       => 20,
                                        'block'        => 5,
                            },
    );
    $mgt->create();


=head1 AUTHOR

Sven Nierlein, <nierlein@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Sven Nierlein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
