package Provision::Unix::VirtualOS::Linux::OpenVZ;
# ABSTRACT: provision a linux VPS using openvz
$Provision::Unix::VirtualOS::Linux::OpenVZ::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use File::Copy;
use Params::Validate qw(:all);
use URI;

use lib 'lib';
use Provision::Unix::User;

sub new {
    my $class = shift;
    my %p = validate( @_, { vos => { type => OBJECT } } );

    my $vos   = $p{vos};
    my $log = my $prov = $vos->{prov};
    my $util  = $vos->{util};
    my $linux = $vos->{linux};

    my $self = {
        vos   => $vos,
        prov  => $prov,
        util  => $util,
        linux => $linux,
    };
    bless $self, $class;

    $prov->audit( $class . sprintf( " loaded by %s, %s, %s", caller ) );

    $prov->{etc_dir} ||= '/etc/vz/conf';    # define a default

    return $self;
}

sub create {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $EUID == 0
        or $prov->error( "Create function requires root privileges." );

    my %std_opts = ( fatal => $vos->{fatal}, debug => $vos->{debug} );
    my $ctid = $vos->{name};

    # do not create if it exists already
    return $prov->error( "ctid $ctid already exists", %std_opts) 
        if $self->is_present();

    # make sure $ctid is within accepable ranges
    my $err;
    my $min = $prov->{config}{VirtualOS}{id_min};
    my $max = $prov->{config}{VirtualOS}{id_max};
    if ( $ctid =~ /^\d+$/ ) {
        $err = "ctid must be greater than $min" if ( $min && $ctid < $min );
        $err = "ctid must be less than $max"    if ( $max && $ctid > $max );
    };
    return $prov->error( $err, %std_opts) if ( $err && $err ne '' );

    $prov->audit("\tctid '$ctid' does not exist, creating...");

    # build the shell create command 
    my $cmd = $util->find_bin( 'vzctl', %std_opts );

    $cmd .= " create $ctid";
    if ( $vos->{disk_root} ) {
        my $disk_root = "$vos->{disk_root}/root/$ctid";
        if ( -e $disk_root ) {
            return $prov->error( "the root directory for $ctid ($disk_root) already exists!",
                %std_opts
            );
        };
        $cmd .= " --root $disk_root";
        $cmd .= " --private $vos->{disk_root}/private/$ctid";
    };

    if ( $vos->{config} ) {
        $cmd .= " --config $vos->{config}";
    }
    else {
        $self->gen_config();
#        $self->set_config_default();
#        $cmd .= " --config default";
    };

    return $prov->error( "template required but not specified", fatal => 0)
        if ! $vos->{template};

    my $template = $self->_is_valid_template( $vos->{template} ) or return;
    $cmd .= " --ostemplate $template";

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};

    my $r = $util->syscmd( $cmd, debug => 0, fatal => 0 );
    if ( ! $r ) {
        $prov->error( "VPS creation failed, unknown error", %std_opts);
    };

    $self->set_hostname()    if $vos->{hostname};
    sleep 1;
    $self->set_ips();
    sleep 1;
    $vos->set_nameservers()  if $vos->{nameservers};
    sleep 1;
    $self->set_password()    if $vos->{password};
    sleep 1;
    $self->start() if ! $vos->{skip_start};
    return $prov->audit("\tvirtual os created and launched");
}

sub destroy {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $EUID == 0
        or $prov->error( "Destroy function requires root privileges." );

    my $name = $vos->{name};

    # make sure VE name/ID exists
    return $prov->error( "VE $name does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present();

    # if disabled, enable it, else vzctl pukes when it attempts to destroy
    my $config = $self->get_ve_config_path();
    if ( ! -e $config ) {
        my $suspended_config = "$config.suspend";
# humans often rename the config file to .suspended instead of our canonical '.suspend'
        $suspended_config = "$config.suspended" if ! -e $suspended_config;
        if ( ! -e $suspended_config ) {
            return $prov->error( "config file for VE $name is missing",
                fatal   => $vos->{fatal},
                debug   => $vos->{debug},
            );
        };
        move( $suspended_config, $config )
            or return $prov->error( "unable to move file '$suspended_config' to '$config': $!",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
            );
    };

    # if VE is running, shut it down
    if ( $self->is_running( refresh => 0 ) ) {
        $prov->audit("\tVE '$name' is running, stopping...");
        $self->stop() 
            or return
            $prov->error( "shut down failed. I cannot continue.",
                fatal   => $vos->{fatal},
                debug   => $vos->{debug},
            );
    };

    # if VE is mounted, unmount it
    if ( $self->is_mounted( refresh => 0 ) ) {
        $prov->audit("\tVE '$name' is mounted, unmounting...");
        $self->unmount() 
            or return
            $prov->error( "unmount failed. I cannot continue.",
                fatal   => $vos->{fatal},
                debug   => $vos->{debug},
            );
    };

# TODO: optionally back it up
    if ( $vos->{safe_delete} ) {
        my $timestamp = localtime( time );
    };

    $prov->audit("\tdestroying $name...");

    my $vzctl = $util->find_bin( 'vzctl', debug => 0 );
    $vzctl .= " destroy $name";

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};

    $util->syscmd( $vzctl, debug => 0, fatal => 0 );

    # we have learned better than to trust the return codes of vzctl
    return $prov->audit("\tdestroyed VE") if ! $self->is_present();

    # vzctl failed, try to nuke it manually
    my $rm      = $util->find_bin( 'rm', debug => 0 );
    my $ve_home = $self->get_ve_home();  # "/vz/private/$ctid"
    $util->syscmd( "$rm -rf $ve_home", debug => 0, fatal => 0 );
    move( $config, "$config.destroyed" );
    return $prov->audit("\tdestroyed VE manually") if ! $self->is_present();

    return $prov->error( "destroy failed, unknown error",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    );
}

sub start {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});
    my $ctid = $vos->{name};

    $prov->audit("starting $ctid");

    if ( !$self->is_present() ) {
        return $prov->error( "VE $ctid does not exist",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        ) 
    };

    if ( $self->is_running() ) {
        $prov->audit("$ctid is already running.");
        return 1;
    };

    my $cmd = $util->find_bin( 'vzctl', debug => 0 );

    $cmd .= ' start';
    $cmd .= " $vos->{name}";
    $cmd .= " --force" if $vos->{force};
    $cmd .= " --wait" if $vos->{'wait'};

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};
    $util->syscmd( $cmd, debug => 0, fatal => 0 );

# the results of vzctl start are not reliable. Use vzctl to
# check the VE status and see if it actually started.

    foreach ( 1..8 ) {
        return 1 if $self->is_running();
        sleep 1;   # the xm start create returns before the VE is running.
    };
    return 1 if $self->is_running();

    return $prov->error( "unable to start VE",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    );
}

sub stop {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    
    $prov->audit("stopping $ctid");

    if ( !$self->is_present() ) {
        return $prov->error( "$ctid does not exist",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        ) 
    };

    if ( ! $self->is_running( refresh => 0 ) ) {
        $prov->audit("$ctid is already shutdown.");
        return 1;
    };

    my $cmd = $util->find_bin( 'vzctl', debug => 0 );
    $cmd .= " stop $vos->{name}";

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};
    $util->syscmd( $cmd, debug => 0, fatal => 0 );

    foreach ( 1..8 ) {
        return 1 if ! $self->is_running();
        sleep 1;
    };
    return 1 if ! $self->is_running();

    return $prov->error( "unable to stop VE",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    );
}

sub restart {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $self->stop()
        or
        return $prov->error( "unable to restart virtual $vos->{name}, failed to stop VE",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        );

    return $self->start();
}

sub disable {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    $prov->audit("disabling $ctid");

    # make sure CTID exists
    return $prov->error( "$ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present();

    # is it already disabled?
    my $config = $self->get_ve_config_path();
    if ( ! -e $config && ( -e "$config.suspend" || -e "$config.suspended" ) ) {
        $prov->audit( "VE is already disabled." );
        return 1;
    };

    # make sure config file exists
    if ( !-e $config ) {
        return $prov->error( "configuration file ($config) for $ctid does not exist.",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );
    }

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};

    # see if VE is running, and if so, stop it
    $self->stop()    if $self->is_running( refresh => 0 );
    $self->unmount() if $self->is_mounted( refresh => 0 );

    move( $config, "$config.suspend" )
        or return $prov->error( "unable to move file '$config' to '$config.suspend': $!",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
        );

    $prov->audit( "virtual $ctid is disabled." );

    return 1;
}

sub enable {

    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    $prov->audit("enabling $ctid");

    # make sure CTID exists 
    return $prov->error( "$ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if ! $self->is_present();

    # see if VE is currently enabled
    my $config = $self->get_ve_config_path();
    if ( -e $config ) {
        $prov->audit("\t$ctid is already enabled");
        return $self->start();
    };

    # make sure config file exists
    my $suspended_config = "$config.suspend";
    $suspended_config = "$config.suspended" if ! -e $suspended_config;
    if ( !-e $suspended_config ) {
        return $prov->error( "configuration file ($config.suspend) for $ctid does not exist",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );
    }

    # make sure VE directory exists
    my $ct_dir = $self->get_ve_home();  # "/vz/private/$ctid";
    if ( !-e $ct_dir ) {
        return $prov->error( "VE directory '$ct_dir' for $ctid does not exist",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );
    }

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};

    $self->enable_config( $prov, $vos, $config ) or return;

    return $self->start();
}

sub enable_config {
    my $self = shift;
    my ( $prov, $vos, $config ) = @_;

    my $suspended_config = "$config.suspend";

    move( $suspended_config, $config )
        or return $prov->error( "unable to move file '$config': $!",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
        );


};


sub migrate {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    my $new_node = $vos->{new_node};

    if ( $vos->{connection_test} ) {
        $vos->do_connectivity_test() or return;
        return 1;
    };

    my $running = $self->is_running();

# rsync disk contents to new node
    my $fs_root = $self->get_fs_root();
    my $rsync = $util->find_bin( 'rsync', debug => 0 );
    $util->syscmd( "$rsync -a --delete $fs_root/ $new_node:$fs_root/", 
        debug => $vos->{debug}, fatal => 0 ) or return;

    $self->stop() if $running;

    $util->syscmd( "$rsync -aHAX --delete $fs_root/ $new_node:$fs_root/",
        debug => $vos->{debug}, fatal => 0 ) or return;

# start up remote VPS
    if ( $running ) {
        my $ssh = $util->find_bin( 'ssh', debug => 0 );
        my $r_cmd = "$ssh $new_node /usr/bin/prov_virtual --name=$ctid";
        $util->syscmd( "$r_cmd --action=start", debug => 1 );
    };

#   $vos->{archive} = 1;   # tell disable to archive the VPS
    $self->disable();

    $prov->audit( "all done" );
    return 1;
};

sub modify {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $EUID == 0
        or $prov->error( "Modify function requires root privileges." );

    my $ctid = $vos->{name};

    $self->stop() or return;

    $prov->audit("\tVE '$ctid' exists and shut down, making changes");

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};

    $self->gen_config();
    $self->set_hostname()   if $vos->{hostname};
    $self->set_password()   if $vos->{password};
    $vos->set_nameservers() if $vos->{nameservers};
    $self->set_ips();

    $prov->audit("\tVE modified");
    $self->start() or return;
    return 1;
}

sub reinstall {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $self->destroy()
        or
        return $prov->error( "unable to destroy virtual $vos->{name}",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        );

    return $self->create();
}

sub console {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    my $cmd = $util->find_bin( 'vzctl', debug => 0 );
    exec "$cmd enter $ctid";
};

sub unmount {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid = $vos->{name};
    $prov->audit("unmounting virtual $ctid");

    # make sure CTID exists
    return $prov->error( "VE $ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present();

    # see if VE is mounted
    if ( !$self->is_mounted( refresh => 0 ) ) {
        return $prov->error( "VE $ctid is not mounted",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        );
    }

    my $cmd = $util->find_bin( 'vzctl', debug => 0 );
    $cmd .= " umount $vos->{name}";

    return $prov->audit("\ttest mode early exit") if $vos->{test_mode};
    $util->syscmd( $cmd, debug => 0, fatal => 0 );

    foreach ( 1..8 ) {
        return 1 if ! $self->is_mounted();
        sleep 1;
    };
    return 1 if ! $self->is_mounted();

    return $prov->error( "unable to unmount VE",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    );
}

sub gen_config {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});
# most of this method was written by Max Vohra - 2009

    my $ram  = $vos->{ram} or return $prov->error( "unable to determine RAM" );
    my $disk = $vos->{disk_size} or 
        return $prov->error( "unable to determine disk size" );

    my $MAX_ULONG = "2147483647";
    if( ($CHILD_ERROR>>8) == 0 ){
        $MAX_ULONG = "9223372036854775807"
    };

    # UBC parameters (in form of barrier:limit)
    my $config = {
        NUMPROC      => [ int($ram*5),   int($ram*5)   ],
        AVNUMPROC    => [ int($ram*2.5), int($ram*2.5) ],
        NUMTCPSOCK   => [ int($ram*5),   int($ram*5)   ],
        NUMOTHERSOCK => [ int($ram*5),   int($ram*5)   ],
        VMGUARPAGES  => [ int($ram*256), $MAX_ULONG    ],
    };

    # Secondary parameters
    $config->{KMEMSIZE} = [ $config->{NUMPROC}[0]*45*1024, $config->{NUMPROC}[0]*45*1024 ];
    $config->{TCPSNDBUF} = [ int($ram*2*23819), int($ram*2*23819)+$config->{NUMTCPSOCK}[0]*4096 ];
    $config->{TCPRCVBUF} = [ int($ram*2*23819), int($ram*2*23819)+$config->{NUMTCPSOCK}[0]*4096 ];
    $config->{OTHERSOCKBUF} = [ int(23819*$ram), int(23819*$ram)+$config->{NUMOTHERSOCK}[0]*4096 ];
    $config->{DGRAMRCVBUF} = [ int(23819*$ram), int(23819*$ram) ];
    $config->{OOMGUARPAGES} = [ int(23819*$ram), $MAX_ULONG ];
    $config->{PRIVVMPAGES} = [ int(256*$ram), int(256*$ram) ];

    # Auxiliary parameters
    $config->{LOCKEDPAGES} = [ int($config->{NUMPROC}[0]*2), int($config->{NUMPROC}[0]*2) ];
    $config->{SHMPAGES} = [ int($ram*100), int($ram*100) ]; 
    $config->{PHYSPAGES} = [ 0, $MAX_ULONG ];
    $config->{NUMFILE} = [ 16*$config->{NUMPROC}[0], 16*$config->{NUMPROC}[0] ];
    $config->{NUMFLOCK} = [ 1000, 1000 ];
    $config->{NUMPTY} = [ 256, 256 ];
    $config->{NUMSIGINFO} = [ 1024, 1024 ];
    $config->{DCACHESIZE} = [ int($config->{NUMFILE}[1]*576*0.95), $config->{NUMFILE}[1]*576 ];

    $config->{NUMIPTENT}  = $ram < 513  ? [ 1536, 1536 ]
                          : $ram < 1025 ? [ 3072, 3072 ]
                          : [ 6144, 6144 ];

    # Disk Resource Limits
    $config->{DISKSPACE}  = [ int($disk*1024*0.95), int($disk*1024) ]; 
    $config->{DISKINODES} = [ int($disk*114000), int($disk*120000) ];
    $config->{QUOTAUGIDLIMIT} = [ 3000 ];
    $config->{QUOTATIME}  = [ 0 ];

    # CPU Resource Limits
    $config->{CPUUNITS}   = [ 1000 ];
    $config->{RATE}       = [ 'eth0', 1, 6000 ];

    $config->{IPTABLES}   = [ join(" ", qw(
        ipt_REJECT ipt_tos ipt_limit ipt_multiport
        iptable_filter iptable_mangle ipt_TCPMSS 
        ipt_tcpmss ipt_ttl ipt_length ip_conntrack 
        ip_conntrack_ftp ipt_LOG ipt_conntrack 
        ipt_helper ipt_state iptable_nat ip_nat_ftp 
        ipt_TOS ipt_REDIRECT ) ) ];
    $config->{DEVICES} = [ "c:10:229:rw c:10:200:rw" ];
    $config->{ONBOOT}  = [ "yes" ]; 
    my $time_dt = $prov->get_datetime_from_epoch();
    
    my $result = <<EO_MAX_CONFIG
# This config file generated by Provision::Unix at $time_dt
# The config parameters are: $ram RAM, and $disk disk space
#
EO_MAX_CONFIG
;
    for my $var ( sort keys %$config ){
        #print $var, '="', join(":",@{$config->{$var}}),"\"\n";
        $result .= $var . '="' . join(":",@{$config->{$var}}) . "\"\n";
    };

    my $disk_root = $vos->{disk_root} || '/vz';
    my $template  = $vos->{template}  || '';
    my @ips       = @{ $vos->{ip} };
    my $ip_string = shift @ips;
    foreach ( @ips ) { $ip_string .= " $_"; }

    $result .= <<EO_VE_CUSTOM
\n# Provision::Unix Custom VE Additions
VE_ROOT="$disk_root/root/\$VEID"
VE_PRIVATE="$disk_root/private/\$VEID"
OSTEMPLATE="$template"
IP_ADDRESS="$ip_string"
EO_VE_CUSTOM
;

    my $conf_file = $self->get_ve_config_path();

# install config file
    $util->file_write( $conf_file, lines => [ $result ], debug => 0 );
    $prov->audit("updated config file $conf_file");
};

sub get_config {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $config_file = $self->get_ve_config_path();

    return $util->file_read( $config_file, debug => 0, fatal => 0,) 
        or return $prov->error("unable to read VE config file", fatal => 0);
};

sub get_ve_config_path {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $ctid   = $vos->{name} or return;
    my $etc_dir = $prov->{etc_dir} || '/etc/vz/conf';
    my $config = "$etc_dir/$ctid.conf";
    return $config;
};

sub get_disk_usage {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    $EUID == 0
        or return $prov->error( "Sorry, getting disk usage requires root.",
        fatal   => 0,
        );

    my $name = $vos->{name};
    my $vzquota = $util->find_bin( 'vzquota', debug => 0, fatal => 0 );
    $vzquota or return $prov->error( "Cannot find vzquota.", fatal => 0 );

    $vzquota .= " show $name";
    my $r = `$vzquota 2>/dev/null`;
# VEID 1002362 exist mounted running
# VEID 1002362 exist unmounted down
    if ( $r =~ /usage/ ) {
        my ($usage) = $r =~ /1k-blocks\s+(\d+)\s+/;
        if ( $usage ) {
            $prov->audit("found disk usage of $usage 1k blocks");
            return $usage;
        };
    };
    $prov->audit("encounted error while trying to get disk usage");
    return;

#    my $homedir = $self->get_ve_home();
#    $cmd .= " -s $homedir";
#    my $r = `$cmd`;
#    my ($usage) = split /\s+/, $r;
#    if ( $usage =~ /^\d+$/ ) {
#        return $usage;
#    };
#    return $prov->error( "du returned unknown result: $r", fatal => 0 );
}

sub get_os_template {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $config = $self->get_ve_config_path();
    return if ! -f $config;
    my $grep = $util->find_bin( 'grep', debug => 0, fatal => 0);
    my $r = `$grep OSTEMPLATE $config*`;
    my ($template) = $r =~ /OSTEMPLATE="(.+)"/i;
    return $template;
}

sub get_status {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $name = $vos->{name};
    my %ve_info = ( name => $name );
    my $exists;

    $self->{status}{$name} = undef;  # reset this

    $EUID == 0
        or return $prov->error( "Status function requires root privileges.",
        fatal   => 0
        );

    my $vzctl = $util->find_bin( 'vzctl', debug => 0, fatal => 0 );
    $vzctl or 
        return $prov->error( "Cannot find vzctl.", fatal => 0 );

# VEID 1002362 exist mounted running
# VEID 1002362 exist unmounted down
# VEID 100236X deleted unmounted down

    $vzctl .= " status $name";
    my $r = `$vzctl`;
    if ( $r =~ /deleted/i ) {
        my $config = $self->get_ve_config_path();
        if ( -e "$config.suspend" || -e "$config.suspended" ) {
            $exists++;
            $ve_info{state} = 'suspended';
        }
        else {
            $ve_info{state} = 'non-existent';
        };
    }
    elsif ( $r =~ /exist/i ) {
        $exists++;
        if    ( $r =~ /running/i ) { $ve_info{state} = 'running'; }
        elsif ( $r =~ /down/i    ) { $ve_info{state} = 'shutdown'; };

        if    ( $r =~ /unmounted/ ) { $ve_info{mount} = 'unmounted'; }
        elsif ( $r =~ /mounted/   ) { $ve_info{mount} = 'mounted';   };
    }
    else {
        return $prov->error( "unknown output from vzctl status.", fatal => 0 );
    };

    return \%ve_info if ! $exists;
    $prov->audit("found VE in state $ve_info{state}");

    if ( $ve_info{state} =~ /running|shutdown/ ) {
        my $vzlist = $util->find_bin( 'vzlist', debug => 0, fatal => 0 );
        if ( $vzlist ) {
            my $vzs = `$vzlist --all`;

            if ( $vzs =~ /NPROC/ ) {

            # VEID      NPROC STATUS  IP_ADDR         HOSTNAME
            # 10          -   stopped 64.79.207.11    lbox-bll

                $self->{status} = {};
                foreach my $line ( split /\n/, $vzs ) {
                    my ( undef, $ctid, $proc, $state, $ip, $hostname ) = 
                        split /\s+/, $line;
                    next if $ctid eq 'VEID';  # omit header
                    next unless ($ctid && $ctid eq $name);
                    $ve_info{proc}  = $proc;
                    $ve_info{ip}    = $ip;
                    $ve_info{host}  = $hostname;
                    $ve_info{state} ||= _run_state($state);
                }
            };
        };
    }

    $ve_info{disk_use} = $self->get_disk_usage();
    $ve_info{os_template} = $self->get_os_template();

    $self->{status}{$name} = \%ve_info;
    return \%ve_info;
}

sub _run_state {
    my $raw = shift;
    return $raw =~ /running/ ? 'running'
            : $raw =~ /stopped/ ? 'shutdown'
            :                     $raw;
}

sub get_fs_root {
    my $self = shift;  
    return $self->get_ve_home(@_);  # same thing for OpenVZ
};

sub get_ve_home {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $name = $vos->{name} || shift || die "missing VE name";
    my $disk_root = $vos->{disk_root} || '/vz';
    my $homedir = "$disk_root/private/$name";
    return $homedir;
};

sub set_config {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $config = shift || _default_config();
    my $ctid = $vos->{name};
    my $config_file = $prov->{etc_dir} . "/$ctid.conf";

    return $util->file_write( $config_file,
        lines => [ $config ],
        debug => 0,
    );
};

sub set_config_default {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $config_file = $prov->{etc_dir} . "/ve-default.conf-sample";
    return if -f $config_file;

    return $util->file_write( $config_file,
        lines => [ _default_config() ],
        debug => 0,
        fatal => 0,
    );
};

sub set_ips {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});
    my $linux = $self->{linux};

    my @ips = @{ $vos->{ip} };

    my (undef,undef,undef,$calling_sub) = caller(1);
    if ( $calling_sub =~ /modify/ ) {
        $prov->audit("using linux method to set ips");
        $linux->set_ips( 
            ips     => \@ips,
            fs_root => $self->get_fs_root(),
            device  => 'venet0',
        );
        return;
    };

    my $cmd = $util->find_bin( 'vzctl', debug => 0 );
    $cmd .= " set $vos->{name}";

    @ips > 0
        or return $prov->error( 'set_ips called but no valid IPs were provided',
        fatal   => $vos->{fatal},
        );

    foreach my $ip ( @ips ) {
        $cmd .= " --ipadd $ip";
    }
    $cmd .= " --save";

    return $util->syscmd( $cmd, debug => 0, fatal => $vos->{fatal} );
}

sub set_password {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $cmd = $util->find_bin( 'vzctl', debug => 0 );
    $cmd .= " set $vos->{name}";

    my $username = $vos->{user} || 'root';
    my $password = $vos->{password}
        or return $prov->error( 'set_password function called but password not provided',
        fatal   => $vos->{fatal},
        );

    $cmd .= " --userpasswd '$username:$password'";

    # not sure why but this likes to return gibberish, regardless of succeess or failure
    # $r = $util->syscmd( $cmd, debug => 0, fatal => 0 );

    # so we do it this way, with no error handling
    system( $cmd );
    # has the added advantage that we don't log the VPS password in the audit log

    $self->set_ssh_key();
    return 1;
}

sub set_ssh_key {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    return 1 if ! $vos->{ssh_key};

    my $user = Provision::Unix::User->new( prov => $prov );
    my $ve_home = $self->get_ve_home();  # "/vz/private/$ctid"

    eval {
        $user->install_ssh_key(
            homedir => "$ve_home/root",
            ssh_key => $vos->{ssh_key},
            debug   => $vos->{debug},
        );
    };
    return $prov->error( $@, fatal => 0 ) if $@;
    $prov->audit("installed ssh key");
    return 1;
}

sub set_hostname {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $hostname = $vos->{hostname}
        or return $prov->error( 'no hostname defined',
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
        );

    my $vzctl = $util->find_bin( 'vzctl', debug => 0 );
    $vzctl .= " set $vos->{name}";
    $vzctl .= " --hostname $hostname --save";

    return $util->syscmd( $vzctl, debug => 0, fatal => $vos->{fatal});
}

sub pre_configure {

    # create /var/log/VZ (1777) and /vz/DELETED_VZ (0755)
    # get lock
    # do action(s)
    # release lock

}

sub is_mounted {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my %p = validate(
        @_,
        {   name   => { type => SCALAR,  optional => 1 },
            refresh=> { type => BOOLEAN, optional => 1, default => 1 },
            debug  => { type => BOOLEAN, optional => 1, default => 1 },
            fatal  => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $name = $p{name} || $vos->{name} or
        return $prov->error( 'is_mounted was called without a CTID' );

    $self->get_status() if $p{refresh};
    my $mount_status = $self->{status}{$name}{mount};
    return 1 if ( $mount_status && $mount_status eq 'mounted');
    return;
};

sub is_present {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my %p = validate(
        @_,
        {   'name'    => { type => SCALAR, optional => 1 },
            'refresh' => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR | UNDEF, optional => 1 },
            'debug' => { type => BOOLEAN, optional => 1, default => 1 },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $name = $p{name} || $vos->{name} or
        $prov->error( 'is_present was called without a CTID' );

    $self->get_status() if $p{refresh};
    return 1 if $self->{status}{ $name };
    return;
}

sub is_running {
    my $self = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my %p = validate(
        @_,
        {   'name'    => { type => SCALAR, optional => 1 },
            'refresh' => { type => SCALAR, optional => 1, default => 1 },
            'test_mode' => { type => SCALAR, optional => 1 },
            'debug' => { type => BOOLEAN, optional => 1, default => 1 },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $name = $p{name} || $vos->{name} or
         $prov->error( 'is_running was called without a CTID' );

    $self->get_status() if $p{refresh};
    return 1 if $self->{status}{$name}{state} eq 'running';
    return;
}

sub _is_valid_template {
    my $self     = shift;
    my $template = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    my $template_dir = $self->{prov}{config}{ovz_template_dir} || '/vz/template/cache';

    if ( $template =~ /^http/ ) {
        # EXAMPLE: http://templates.example.com/centos-5-i386-default.tar.gz
        my $uri = URI->new($template);
        my @segments = $uri->path_segments;
        my @path_bits = grep { /\w/ } @segments;  # ignore empty fields
        my $file = $segments[-1];

        $prov->audit("fetching $file from " . $uri->host);

        $util->get_url( $template,
            dir   => $template_dir,
            fatal => 0,
            debug => 0,
        );
        if ( -f "$template_dir/$file" ) {
            ($file) = $file =~ /^(.*)\.tar\.gz$/;
            return $file;
        };
    }
    else {
        # EXAMPLE:   centos-5-i386-default
        return $template if -f "$template_dir/$template.tar.gz";
    }

    return $prov->error( "template '$template' does not exist and is not a valid URL",
        debug => $vos->{debug},
        fatal => $vos->{fatal},
    );
}

sub _is_valid_name {
    my $self = shift;
    my $name = shift;
    my ($prov, $vos, $util) = ($self->{prov}, $self->{vos}, $self->{util});

    if ( $name !~ /^[0-9]+$/ ) {
        return $prov->error( "OpenVZ requires the name (VEID/CTID) to be numeric",
            fatal   => $vos->{fatal},
            debug   => $vos->{debug},
        );
    }
    return 1;
}

sub _default_config {

    return <<'EOCONFIG'
ONBOOT="yes"
NUMPROC="2550:2550"
AVNUMPROC="1275:1275"
NUMTCPSOCK="2550:2550"
NUMOTHERSOCK="2550:2550"
VMGUARPAGES="131072:9223372036854775807"

# Secondary parameters
KMEMSIZE="104506470:114957117"
TCPSNDBUF="24390690:34835490"
TCPRCVBUF="24390690:34835490"
OTHERSOCKBUF="12195345:22640145"
DGRAMRCVBUF="12195345:12195345"
OOMGUARPAGES="75742:9223372036854775807"
PRIVVMPAGES="128000:131072"

# Auxiliary parameters
LOCKEDPAGES="5102:5102"
SHMPAGES="45445:45445"
PHYSPAGES="0:9223372036854775807"
NUMFILE="40800:40800"
NUMFLOCK="1000:1100"
NUMPTY="255:255"
NUMSIGINFO="1024:1024"
DCACHESIZE="22816310:23500800"
NUMIPTENT="1536:1536"

# Disk Resource Limits
DISKINODES="2280000:2400000"
DISKSPACE="19922944:20971520"

# Quota Resource Limits
QUOTATIME="0"
QUOTAUGIDLIMIT="3000"

# CPU Resource Limits
CPUUNITS="1000"
RATE="eth0:1:6000"

# IPTables config
IPTABLES="ipt_REJECT ipt_tos ipt_limit ipt_multiport iptable_filter iptable_mangle ipt_TCPMSS ipt_tcpmss ipt_ttl ipt_length ip_conntrack ip_conntrack_ftp ipt_LOG ipt_conntrack ipt_helper ipt_state iptable_nat ip_nat_ftp ipt_TOS ipt_REDIRECT"

# Default Devices
DEVICES="c:10:229:rw c:10:200:rw "
EOCONFIG
;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::Linux::OpenVZ - provision a linux VPS using openvz

=head1 VERSION

version 1.08

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
