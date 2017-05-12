package Provision::Unix::VirtualOS::Linux::Xen;
# ABSTRACT: provision a linux VPS using Xen
$Provision::Unix::VirtualOS::Linux::Xen::VERSION = '1.08';
use strict;
use warnings;

#use Data::Dumper;
use English qw( -no_match_vars );
use File::Copy;
use File::Path;
use Params::Validate qw(:all);

use lib 'lib';
use Provision::Unix::User;

my ( $prov, $log, $vos, $linux, $user, $util );

sub new {
    my $class = shift;

    my %p = validate( @_, { 'vos' => { type => OBJECT }, } );

    $vos   = $p{vos};
    $log = $prov = $vos->{prov};
    $linux = $vos->{linux};
    $util  = $vos->{util};

    my $self = { 
        'prov'     => $prov,
        'status'   => undef,
        'exists'   => undef,
        'xen_conf' => undef,
    };
    bless( $self, $class );

    $log->audit( $class . sprintf( " loaded by %s, %s, %s", caller ) );

    $vos->{disk_root} ||= '/home/xen';    # xen default

    return $self;
}

sub create {
    my $self = shift;

    $EUID == 0
        or $log->error( "Create function requires root privileges." );

    my $ctid = $vos->{name} or return $log->error( "VE name missing in request!");

    return $log->error( "VE $ctid already exists", fatal => 0 ) 
        if $self->is_present();

    my $template = $self->is_valid_template() or 
        return $log->error( "no valid template specified", fatal => 0 );

    my $err_count_before = @{ $prov->{errors} };
    my $xm = $util->find_bin( 'xm', debug => 0, fatal => 1 );

    return $log->audit("test mode early exit") if $vos->{test_mode};

    $self->create_swap_image() or return;
    $self->create_disk_image() or return;
    $self->mount() or return;

# make sure we trap any errors here and clean up after ourselves.
    my $r;
    $self->extract_template() or $self->unmount() and return;

    my $fs_root  = $self->get_fs_root();
    eval {
        $linux->install_kernel_modules( 
            fs_root => $fs_root, 
            version => $self->get_kernel_version(),
        );
    };
    $log->error( $@, fatal => 0 ) if $@;

    $self->set_ips();

    eval { $linux->set_rc_local( fs_root => $fs_root ); };
    $log->error( $@, fatal => 0 ) if $@;

    eval { 
        $linux->set_hostname(
            host    => $vos->{hostname},
            fs_root => $fs_root,
            distro  => $template,
        );
    };
    $log->error( $@, fatal => 0 ) if $@;

    $vos->set_nameservers() if $vos->{nameservers};

    eval { $self->create_console_user(); };
    $log->error( $@, fatal => 0 ) if $@;

    if ( $vos->{password} ) {
        eval { $self->set_password('setup');  };
        $log->error( $@, fatal=>0) if $@;
    };

    eval { $self->set_fstab(); };
    $log->error( $@, fatal=>0) if $@;

    eval { $self->set_libc(); };
    $log->error( $@, fatal=>0) if $@;

    eval { $linux->setup_inittab( fs_root => $fs_root, template => $template ); };
    $log->error( $@, fatal=>0) if $@;

    eval { $vos->setup_ssh_host_keys( fs_root => $fs_root ); };
    $log->error( $@, fatal=>0) if $@;
   
    eval { $vos->setup_log_files( fs_root => $fs_root ); };
    $log->error( $@, fatal=>0) if $@;

    $self->unmount();

    $self->gen_config()
        or return $log->error( "unable to install config file", fatal => 0 );

    my $err_count_after = @{ $prov->{errors} };
    $self->start() if ! $vos->{skip_start};

    return if $err_count_after > $err_count_before;
    return 1;

}

sub destroy {

    my $self = shift;

    $EUID == 0
        or $log->error( "Destroy function requires root privileges." );

    my $ctid = $vos->{name};

    return $log->error( "VE $ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present( debug => 0 );

    return $log->audit("\ttest mode early exit") if $vos->{test_mode};

    $self->stop() or return;

# sometimes Xen leaves a disk volume marked as in use, this clears that, so
# the unmount can succeed.
    $self->stop_forcefully();  
    $self->unmount() or return $log->error("could not unmount disk image");

    $log->audit("\tctid '$ctid' is stopped. Nuking it...");
    $self->destroy_snapshot() or return;
    $self->destroy_disk_image() or return;
    $self->destroy_swap_image() or return;

    my $ve_home = $self->get_ve_home() or
        $log->error( "could not deduce the VE home dir" );

    return 1 if ! -d $ve_home;

    $self->destroy_console_user();
    if ( -d $ve_home ) {
        my $rm = $util->find_bin( 'rm', debug => 0 );
        $util->syscmd( "$rm -rf $ve_home",
            debug => 0,
            fatal => $vos->{fatal},
        );
        if ( -d $ve_home ) {
            $log->error( "failed to delete $ve_home" );
        }
    };

    my $ve_name = $self->get_ve_name();
    my $startup = "/etc/xen/auto/$ve_name.cfg";
    unlink $startup if -e $startup;

    return 1;
}

sub start {
    my $self = shift;

    my $ctid  = $vos->{name} or die "name of VE missing!\n";
    my $debug = $vos->{debug};
    my $fatal = $vos->{fatal};

    $log->audit("starting $ctid");

    return $log->error( "ctid $ctid does not exist",
        fatal => $fatal,
        debug => $debug,
    )
    if !$self->is_present( debug => 0 );

    if ( $self->is_running() ) {
        $log->audit("$ctid is already running.");
        return 1;
    };

# disk images often get left mounted, preventing a VE from starting. 
# Try unmounting them, just in case.
    $self->unmount( 'quiet' );

    my $config_file = $self->get_ve_config_path();
    return $log->error( "config file for $ctid at $config_file is missing.")
        if !-e $config_file;

# -c option to xm create will start the vm in a console window. Could be useful
# when doing test VEs to look for errors
    my $cmd = $util->find_bin( 'xm', debug => 0 );
    $cmd .= " create $config_file";
    $util->syscmd( $cmd, debug => 0, fatal => $fatal )
        or $log->error( "unable to start $ctid" );

    foreach ( 1..15 ) {
        return 1 if $self->is_running();
        sleep 1;   # the xm start create returns before the VE is running.
    };
    return 1 if $self->is_running();
    return;
}

sub stop {
    my $self = shift;

    my $ctid = $vos->{name} or die "name of VE missing!\n";

    return $log->error( "$ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) 
    if !$self->is_present( debug => 0 );

    return $log->audit("$ctid is already shutdown.")
        if ! $self->is_running();

    $log->audit("shutting down $ctid");

    $self->stop_nicely();
    $self->stop_forcefully();

    system "sync";
    foreach ( 1..5 ) {
        last if ! $self->lvm_in_use();  # give the lvm time to sync and detach
        sleep 1;
    };

    return 1 if !$self->is_running();
    $log->error( "failed to stop virtual $ctid", fatal => 0 );
    return;
}

sub stop_nicely {
    my $self = shift;

    my $ve_name = $self->get_ve_name();
    my $xm = $util->find_bin( 'xm', debug => 0 );

    # try a 'friendly' shutdown for 15 seconds
    $util->syscmd( "$xm shutdown -w $ve_name",
        timeout => 15,
        debug   => 0,
        fatal   => 0,
    );

    # xm shutdown may exit before the VE is stopped.
    # wait up to 15 more seconds for VE to shutdown
    foreach ( 1..15 ) {
        last if ! $self->is_running( debug => 0 );
        sleep 1;   
    };
};

sub stop_forcefully {
    my $self = shift;

    my $ctid = $vos->{name} or die "name of VE missing!\n";

    $log->audit("shutting down $ctid");

    my $ve_name = $self->get_ve_name();
    my $xm = $util->find_bin( 'xm', debug => 0 );

    $util->syscmd( "$xm destroy $ve_name",
        timeout => 20,
        fatal => 0,
        debug => 0,
    );

    # xm destroy may exit before the VE is stopped.
    # wait 15 more seconds for it to finish shutting down
    foreach ( 1..15 ) {
        last if ! $self->is_running( debug => 0 );
        sleep 1;   
    };
}

sub restart {
    my $self = shift;

    my $ve_name = $self->get_ve_name();

    $self->stop() or return;
    return $self->start();
}

sub disable {
    my $self = shift;

    my $ctid = $vos->{name};
    $log->audit("disabling $ctid");

    # make sure CTID exists
    return $log->error( "$ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present( debug => 0 );

    # is it already disabled?
    my $config = $self->get_ve_config_path();
    if ( !-e $config && -e "$config.suspend" ) {
        $log->audit( "VE is already disabled." );
        return 1;
    };

    # make sure config file exists
    if ( !-e $config ) {
        return $log->error( "configuration file ($config) for $ctid does not exist",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );
    }

    return $log->audit("\ttest mode early exit") if $vos->{test_mode};

    # see if VE is running, and if so, stop it
    if ( $self->is_running() ) {
        $self->stop() or return; 
    };

    move( $config, "$config.suspend" )
        or return $log->error( "\tunable to move file '$config': $!",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
        );

    if ( $vos->{archive} ) {
        my $tar = $util->find_bin( 'tar' );
        my $ve_home = $self->get_ve_home();
        my $fs_root = $self->get_fs_root();
        $self->mount();
        system "$tar -czPf $ve_home/$ctid.tar.gz $fs_root";
        $self->unmount();
        $self->destroy_disk_image();
        $self->destroy_swap_image();
    };

    $log->audit("\tdisabled $ctid.");
    return 1;
}

sub enable {

    my $self = shift;

    my $ctid = $vos->{name};
    $log->audit("enabling $ctid");

    # make sure CTID exists
    return $log->error( "$ctid does not exist",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
    ) if !$self->is_present( debug => 0 );

    # is it already enabled?
    if ( $self->is_enabled() ) {
        $log->audit("\t$ctid is already enabled");
        return $self->start();
    };

    # make sure config file exists
    my $config = $self->get_ve_config_path();
    if ( !-e "$config.suspend" ) {
        return $log->error( "configuration file ($config.suspend) for $ctid does not exist",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );
    }

    return $log->audit("\ttest mode early exit") if $vos->{test_mode};

    move( "$config.suspend", $config )
        or return $log->error( "\tunable to move file '$config': $!",
        fatal   => $vos->{fatal},
        debug   => $vos->{debug},
        );

    if ( $vos->{archive} ) {
#        my $tar = $util->find_bin( 'tar' );
#        my $ve_home = $self->get_ve_home();
#        my $fs_root = $self->get_fs_root();
#        $self->create_disk_image() or return;
#        $self->create_swap_image() or return;
#        $self->mount() or return;
#        system "$tar -xzf $ve_home/$ctid.tar.gz -C $fs_root";
#        $self->unmount();
    };

    return $self->start();
}

sub migrate {
    my $self = shift;

    my $ctid = $vos->{name};
    my $new_node = $vos->{new_node};

    if ( $vos->{connection_test} ) {
        $vos->do_connectivity_test() or return;
        return 1;
    };

    my $status  = $self->get_status();
    my $state   = $status->{state};
    my $running = $state eq 'running' ? 1 : 0;

# mount disk or snapshot
    if ( $running ) {
        $self->create_snapshot() or return;
        $self->mount_snapshot() or do {
            $self->destroy_snapshot();
            return $log->error("failed to mount snapshot", fatal => 0);
        };
    }
    else {
        $self->mount();
    };

# mount remote disk image
    my $ssh = $util->find_bin( 'ssh', debug => 0 );
    my $r_cmd = "$ssh $new_node /usr/bin/prov_virtual --name=$ctid";
    $util->syscmd( "$r_cmd --action=mount", debug => 1 );

# rsync disk contents to new node
    my $fs_root = $self->get_fs_root();
    my $rsync = $util->find_bin( 'rsync', debug => 0 );
    $util->syscmd( "$rsync -a --delete $fs_root/ $new_node:$fs_root/", 
        debug => $vos->{debug}, fatal => 0 ) or return;

    if ( $running ) {
        $self->destroy_snapshot();
        $self->stop();
        $self->mount();
    };

    $util->syscmd( "$rsync -aHAX --delete $fs_root/ $new_node:$fs_root/",
        debug => $vos->{debug}, fatal => 0 ) or return;

# copy over xen config file if it doesn't exist
# TODO: test this before enabling (not used in our environment).
#    my $config  = $self->get_ve_config_path();
#    my $ve_home = $self->get_ve_home();
#    $util->syscmd( "$rsync -av --ignore-existing $config $new_node:$ve_home/",
#        debug => $vos->{debug}, fatal => 0 ) or return;

# restore state to new VE
    if ( $state eq 'running' ) {
        $util->syscmd( "$r_cmd --action=start", debug => 0 );
    }
    elsif ( $state eq 'disabled' ) {
        $util->syscmd( "$r_cmd --action=disable", debug => 0 );
    }
    else {
        $util->syscmd( "$r_cmd --action=unmount", debug => 0 );
    };

    $self->migrate_arp_update();
    $self->unmount();

#   $vos->{archive} = 1;   # tell disable to archive the VPS
    $self->disable();

    $log->audit( "all done" );
    return 1;
};

sub migrate_arp_update {
    my $self = shift;

    my $ctid = $vos->{name};
    my $new_node = $vos->{new_node};

    my $ssh = $util->find_bin( 'ssh', debug => 0 );
    my @ips = grep { /vif$ctid/ } `netstat -rn`;
    my $r_cmd = "$ssh $new_node /usr/bin/prov_virtual";
    foreach my $ip ( @ips ) {
        $util->syscmd( "$r_cmd --name=$ctid --action=publish_arp --ip=$ip" );
    };
};

sub modify {
    my $self = shift;

    my $ctid = $vos->{name};
    $log->audit("modifying $ctid");

    # hostname ips nameservers searchdomain disk_size ram config 

    $self->stop() or return;
    $self->mount() or return;

    my $fs_root = $self->get_fs_root();
    my $hostname = $vos->{hostname};

    $self->set_ips() if $vos->{ip};
    $linux->set_hostname( host => $hostname, fs_root => $fs_root ) 
        if $hostname && ! $vos->{ip};

    $user ||= Provision::Unix::User->new( prov => $prov );

    if ( $user ) {
        $self->set_password_root();
        $self->set_ssh_key();
    };

    $self->gen_config();
    $self->unmount() or return;
    $self->resize_disk_image();
    $self->start() or return;
    return 1;
}

sub reinstall {
    my $self = shift;

    $self->get_xen_config();  # cache value from config file (like mac address)

    $self->destroy()
        or
        return $log->error( "unable to destroy virtual $vos->{name}",
            fatal => $vos->{fatal},
            debug => $vos->{debug},
        );

    return $self->create();
}

sub console {
    my $self = shift;
    my $ve_name = $self->get_ve_name();
    my $cmd = $util->find_bin( 'xm', debug => 0 );
    exec "$cmd console $ve_name";
};

sub create_console_user {
    my $self = shift;

    $user ||= Provision::Unix::User->new( prov => $prov );
    my $username = $self->get_console_username();
    my $ve_home = $self->get_ve_home();
    my $ve_name = $self->get_ve_name();
    my $debug   = $vos->{debug};

    if ( ! $user->exists( $username ) ) { # see if user exists
        $user->create_group( group => $username, debug => $debug );
        $user->create(
            username => $username,
            password => $vos->{password},
            homedir  => $ve_home,
            shell    => -x '/usr/bin/lxxen' ? '/usr/bin/lxxen' : '',
            debug    => $debug,
            gecos    => "System User for $ve_name",
        )
        or return $log->error( "unable to create console user $username", fatal => 0 ); 
        $log->audit("created console user account");
    };   

    my $uid = getpwnam $username;
    if ( $uid ) {
        $util->chown( dir => $ve_home, uid => $uid, fatal => 0 );
    };

    foreach ( qw/ .bashrc .bash_profile / ) {
        $util->file_write( "$ve_home/$_", 
            lines => [ "/usr/bin/sudo /usr/sbin/xm console $ve_name", 'exit' ],
            fatal => 0,
            debug => 0,
        )
        or $log->error( "failed to configure console login script", fatal => 0 );
    }
    $log->audit("installed console login script");

    if ( ! `grep '^$username' /etc/sudoers` ) {
        $util->file_write( '/etc/sudoers',
            lines  => [ "$username  ALL=(ALL) NOPASSWD: /usr/sbin/xm console $ve_name" ],
            append => 1,
            mode   => '0440',
            fatal  => 0,
            debug  => 0
        )
        or $log->error( "failed to update sudoers for console login");

        $util->file_write( '/etc/sudoers.local',
            lines  => [ "$username  ALL=(ALL) NOPASSWD: /usr/sbin/xm console $ve_name" ],
            append => 1,
            fatal  => 0,
            debug  => 0
        )
        or $log->error( "failed to update sudoers for console login");
        $log->audit("updated sudoers for console account $username");
    };

    $log->audit( "configured remote SSH console" );
    return 1;
};

sub create_disk_image {
    my $self = shift;

    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);
    my $size = $self->get_disk_size();
    my $ram  = $self->get_ve_ram();

    # create the disk image
    my $cmd = $util->find_bin( 'lvcreate', debug => 0, fatal => 0 ) or return;
    $cmd .= " --size=${size}M --name=${image_name} vol00";
    $util->syscmd( $cmd, debug => 0, fatal => 0 )
        or return $log->error( "unable to create $image_name with: $cmd", fatal => 0 );

    # format as ext3 file system
    my $mkfs = $util->find_bin( 'mkfs.ext3', debug => 0, fatal => 0 ) or return;
    $util->syscmd( "$mkfs $image_path", debug => 0, fatal => 0 )
        or return $log->error( "unable for format disk image", fatal => 0);

    $log->audit("disk image for $vos->{name} created");
    return 1;
}

sub create_snapshot {
    my $self = shift;
    my $ve_name = $self->get_ve_name();

    return $log->error( "VE $ve_name does not exist" )
        if !$self->is_present( debug => 0 );
    my $is_running = $self->is_running();

    my $err;
    my $vol  = $self->get_disk_image();
    my $snap = $vol . '_snap';

    my $xm_bin   = $util->find_bin('xm');
    my $lvremove = $util->find_bin('lvremove');
    my $lvcreate = $util->find_bin('lvcreate');

    # cleanup
    my $snapimg = "/dev/vol00/$snap";
    if ( -e $snapimg ) {
        $self->destroy_snapshot() or return;
    };

    if ( $is_running ) {
        # Sync and pause domain
        my $sync_cmd = "$xm_bin sysrq $ve_name s";
        $log->audit( "syncing domain with: $sync_cmd");
        system $sync_cmd;
        return $log->error( "unable to sync dom $ve_name: $!" ) if $CHILD_ERROR;

        my $pause_cmd = "$xm_bin pause $ve_name";
        $log->audit( "pause VE with: $pause_cmd");
        system $pause_cmd;
        return $log->error( "unable to pause dom $ve_name: $!" ) if $CHILD_ERROR;
    };
    
    # create the snapshot
    my $vol_create = "$lvcreate -l 32 -s -n $snap /dev/vol00/$vol";
    $log->audit( "$vol_create");
    system "$vol_create" and do {
        system "$xm_bin unpause $ve_name";
        return $log->error( "unable to create snapshot of /dev/vol00/$vol: $!" );
    };

    if ( $is_running ) {
        # Unpause domain
        my $resume_cmd = "$xm_bin unpause $ve_name";
        $log->audit( "$resume_cmd" );
        system "$resume_cmd" and $log->error( "unable to unpause domain $ve_name: $!" );
    };
    return 1;
};

sub create_swap_image {
    my $self = shift;

    my $swap_name = $self->get_swap_image();
    my $swap_path = $self->get_swap_image(1);
    my $ram       = $self->get_ve_ram();
    my $size      = $ram * 2;

    # create the swap image
    my $cmd = $util->find_bin( 'lvcreate', debug => 0, fatal => 0 ) or return;
    $cmd .= " --size=${size}M --name=${swap_name} vol00";
    $util->syscmd( $cmd, debug => 0, fatal => 0 )
        or return $log->error( "unable to create $swap_name", fatal => 0 );

    # format the swap file system
    my $mkswap = $util->find_bin( 'mkswap', debug => 0, fatal => 0) or return;
    $util->syscmd( "$mkswap $swap_path", debug => 0, fatal => 0 )
        or return $log->error( "unable to format $swap_name", fatal => 0 );

    $log->audit( "created a $size MB swap partition" );
    return 1;
}

sub destroy_console_user {
    my $self = shift;

    $user ||= Provision::Unix::User->new( prov => $prov );
    my $username = $self->get_console_username();
    my $ve_home = $self->get_ve_home();
    my $ve_name = $self->get_ve_name();

    if ( $user->exists( $username ) ) { # see if user exists
        $user->destroy(
            username => $username,
            homedir  => $ve_home,
            debug    => 0,
            fatal    => 0,
        )
        or return $log->error( "unable to destroy console user $username", fatal => 0 ); 
        $log->audit( "deleted system user $username" );

        $user->destroy_group( group => $username, fatal => 0, debug => 0 );
    };   

    $log->audit( "deleted system user $username" );
    return 1;
};

sub destroy_disk_image {
    my $self = shift;

    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);

    #$log->audit("checking for presense of disk image $image_name");
    if ( ! -e $image_path ) {
        $log->audit("disk image does not exist: $image_name");
        return 1;
    };

    $log->audit("My name is Inigo Montoya. You killed my father. Prepare to die!");

    my $lvrm  = $util->find_bin( 'lvremove', debug => 0 );
       $lvrm .= " -f vol00/${image_name}";
    my $r = $util->syscmd( $lvrm, debug => 0, fatal => 0 );
    if ( ! $r ) {
        $log->audit("My name is Inigo Montoya. You killed my father. Prepare to die!");
        sleep 3;  # wait a few secs and try again
        $r = $util->syscmd( $lvrm, debug => 0, fatal => 0 )
            and pop @{ $prov->{errors} };  # clear the last error
    };
    $r or return $log->error( "unable to destroy disk image: $image_name" );
    return 1;
}

sub destroy_snapshot {
    my $self = shift;
    my $ve_name = $self->get_ve_name();

    my $vol  = $self->get_disk_image();
    my $snap = $vol . '_snap';

    if ( $self->is_mounted( $snap ) ) {
        # a mounted snapshot cannot be destroyed
        $self->unmount_snapshot() or return;  
    };

    # cleanup
    my $snapimg = "/dev/vol00/$snap";
    if ( -e $snapimg ) {
        my $lvremove = $util->find_bin('lvremove', debug => 0);
        system "$lvremove -f $snapimg";
        return $log->error("could not remove $snapimg") if $CHILD_ERROR;
    }
    return 1;
};

sub destroy_swap_image {
    my $self = shift;

    my $img_name = $self->get_swap_image();
    my $img_path = $self->get_swap_image(1);

    if ( ! -e $img_path ) {
        $log->audit("swap image $img_name does not exist");
        return 1;
    };

    my $lvrm = $util->find_bin( 'lvremove', debug => 0 );
    $util->syscmd( "$lvrm -f vol00/$img_name", debug => 0, fatal => 0 )
        or return $log->error( "unable to destroy swap $img_name", fatal => 0 );
    return 1;
}

sub do_fsck {
    my $self = shift;
    my $image_path = $self->get_disk_image(1);

    my $fsck  = $util->find_bin( 'e2fsck', debug => 0 );
    $util->syscmd( "$fsck -y -f $image_path", debug => 0, fatal => 0 ) or return;
    return 1;
};

sub extract_template {
    my $self = shift;

    my $template = $self->is_valid_template()
        or return $log->error( "no valid template specified", fatal => 0 );

    my $ve_name = $self->get_ve_name();
    my $fs_root = $self->get_fs_root();
    my $template_dir = $self->get_template_dir();

    #tar -zxf $template_dir/$OSTEMPLATE.tar.gz -C /home/xen/$ve_name/mnt

    # untar the template
    my $tar = $util->find_bin( 'tar', debug => 0, fatal => 0 ) or return;
    $tar .= " -zxf $template_dir/$template.tar.gz -C $fs_root";
    $util->syscmd( $tar, debug => 0, fatal => 0 )
        or return $log->error( "unable to extract template $template. Do you have enough disk space?",
            fatal => 0
        );
    return 1;
}

sub gen_config {
    my $self = shift;

    my $ctid        = $vos->{name};
    my $ve_name     = $self->get_ve_name();
    my $config_file = $self->get_ve_config_path();
    #warn "config file: $config_file\n" if $vos->{debug};

    my $ram      = $self->get_ve_ram();
    my $hostname = $vos->{hostname} || $ctid;

    my @ips      = @{ $vos->{ip} };
    my $ip_list  = shift @ips;
    foreach ( @ips ) { $ip_list .= " $_"; };
    my $mac      = $self->get_mac_address();

    my $image_path = $self->get_disk_image(1);
    my $swap_path  = $self->get_swap_image(1);
    my $kernel_dir = $self->get_kernel_dir();
    my $kernel_version = $self->get_kernel_version();

    my ($kernel) = glob("$kernel_dir/vmlinuz*$kernel_version*");
    my ($ramdisk) = glob("$kernel_dir/initrd*$kernel_version*");
    ($kernel) ||= glob("/boot/vmlinuz-*xen");
    ($ramdisk) ||= glob("/boot/initrd-*xen.img");
    my $cpu = $vos->{cpu} || 1;
    my $time_dt = $prov->get_datetime_from_epoch();

    my $config = <<"EOCONF"
# Config file generated by Provision::Unix at $time_dt
kernel     = '$kernel'
ramdisk    = '$ramdisk'
memory     = $ram
name       = '$ve_name'
hostname   = '$hostname'
vif        = ['ip=$ip_list, vifname=vif${ctid},  mac=$mac']
vnc        = 0
vncviewer  = 0
serial     = 'pty'
disk       = ['phy:$image_path,sda1,w', 'phy:$swap_path,sda2,w']
root       = '/dev/sda1 ro'
extra      = 'console=xvc0'
vcpus      = $cpu
EOCONF
;

    # These can also be set in the config file.
    #console    =
    #nics       =
    #dhcp       =

    $util->file_write( $config_file, 
        lines => [$config],
        debug => 0,
        fatal => 0,
    ) or return $log->error("unable to install VE config file", fatal => 0);

    link $config_file, "/etc/xen/auto/$ve_name.cfg";
    return 1;
}

sub get_config {
    my $self = shift;

    my $config_file = $self->get_ve_config_path();

    return $util->file_read( $config_file, debug => 0, fatal => 0 ) 
    or return $log->error("unable to read VE config file", fatal => 0);
};

sub get_console_username {
    my $self = shift;
    my $ctid = $vos->{name};
       $ctid .= 'vm';
    return $ctid;
};

sub get_disk_image {
    my $self = shift;
    my $path = shift;
    my $name = $vos->{name} or die "missing VE name!";
    my $image_name = $name . '_rootimg';
    $image_name = '/dev/vol00/' . $image_name if $path;
    return $image_name;
};

sub get_disk_size {
    my $self = shift;
    my $ram = $self->get_ve_ram();
    my $swap = $ram * 2;
    my $allocation = $vos->{disk_size} || 2500;
    return $allocation - $swap; # subtract swap from their disk allotment
};

sub get_disk_usage {
    my $self = shift;
    my $image = shift or return;

    my $cmd = $util->find_bin( 'dumpe2fs', fatal => 0, debug => 0 );
    return if ! -x $cmd;

    $cmd .= " -h $image";
    my $r = `$cmd 2>&1`;
    my ($block_size) = $r =~ /Block size:\s+(\d+)/;
    my ($blocks_tot) = $r =~ /Block count:\s+(\d+)/;
    my ($blocks_free) = $r =~ /Free blocks:\s+(\d+)/; 

    my $disk_total = ( $blocks_tot * $block_size ) / 1024;
    my $disk_free = ( $blocks_free * $block_size ) / 1024;
    my $disk_used = $disk_total - $disk_free;

    return $disk_used;
};

sub get_kernel_dir {
    my $self = shift;
    return '/boot/domU' if -d "/boot/domU";
    return '/boot';
};

sub get_kernel_version {
    my $self = shift;
    return $vos->{kernel_version} if $vos->{kernel_version};
    my $kernel_dir = $self->get_kernel_dir();
    my @kernels = glob("$kernel_dir/vmlinuz-*xen");
    my $kernel = $kernels[0];
    my ($version) = $kernel =~ /-([0-9\.\-]+)\./;
    return $log->error("unable to detect a xen kernel (vmlinuz-*xen) in standard locations (/boot, /boot/domU)", fatal => 0) if ! $version;
    $vos->{kernel_version} = $version;
    return $version;
};

sub get_mac_address {
    my $self = shift;
    my $mac = $vos->{mac_address};   # passed in value
    return $mac if $mac;

    # value from VE config file
    my $xen_conf = $self->get_xen_config();
    if ( $xen_conf ) {
        my $vif = $xen_conf->get('vif');
        if ( ref $vif->[0]->{mac} ) {
            return $vif->[0]->{mac}->[0];
        };
        return $vif->[0]->{mac} if $vif->[0]->{mac};
    };

    # both of the previous methods failed, generate a random MAC
    my $i;
    $mac = '00:16:3E';

    while ( ++$i ) {
        last if $i > 6;
        $mac .= ':' if $i % 2;
        $mac .= sprintf "%" . ( qw (X x) [ int( rand(2) ) ] ),
            int( rand(16) );
    }

    # TODO:
    #   make sure random MAC does not conflict with an existing one.

    return $mac;
}

sub get_status {
    my $self = shift;
    my %p = validate( @_, { debug => { type => BOOLEAN, optional => 1 } } );

    my $debug = defined $p{debug} ? $p{debug} : $vos->{debug};

    my $ve_name = $self->get_ve_name();

    $self->{status} = {};    # reset status

    return $self->{status}{$ve_name} if ! $self->is_present( debug => $debug );

    # get IPs and disks from the VE config file
    my ($ips, $vif, $disks, $disk_usage );
    my $config_file = $self->get_ve_config_path();
    if ( ! -e $config_file ) {
        return { state => 'disabled' } if -e "$config_file.suspend";

        $log->audit( "\tmissing config file $config_file" );
        return { state => 'broken' };
    };

    my $xen_conf = $self->get_xen_config();
    if ( $xen_conf ) {
        $ips   = $xen_conf->get_ips();
        $disks = $xen_conf->get('disk');
        $vif   = $xen_conf->get('vif');
    };
    foreach ( @$disks ) {
        my ($image) = $_ =~ /phy:(.*?),/;
        next if ! -e $image;
        next if $image =~ /swap/i;
        $disk_usage = $self->get_disk_usage($image);
    };

    my $cmd = $util->find_bin( 'xm', debug => 0 );
    $cmd .= " list $ve_name";
    my $r = `$cmd 2>&1`;

    my $exit_code = $? >> 8;
# xm exit codes: 0=success, 1=fail, 2=unknown

    if ( $r =~ /does not exist/ ) {

        # a Xen VE that is shut down won't show up in the output of 'xm list'
        $self->{status}{$ve_name} = {
            ips      => $ips,
            disks    => $disks,
            state    => 'shutdown',
        };
        return $self->{status}{$ve_name};
    };

    $r =~ /VCPUs/ 
        or $log->error( "could not get valid output from '$cmd'", fatal => 0 );

    foreach my $line ( split /\n/, $r ) {

 # Name                               ID Mem(MiB) VCPUs State   Time(s)
 #test1.vm                            20       63     1 -b----     34.1

        my ( $ctid, $dom_id, $mem, $cpus, $state, $time ) = split /\s+/, $line;
        next unless $ctid;
        next if $ctid eq 'Name';
        next if $ctid eq 'Domain-0';
        next if $ctid ne $ve_name;

        $self->{status}{$ctid} = {
            ips      => $ips,
            disks    => $disks,
            disk_use => $disk_usage,
            dom_id   => $dom_id,
            mem      => $mem + 1,
            cpus     => $cpus,
            state    => _run_state($state),
            cpu_time => $time,
            mac      => $vif->[0]->{mac},
        };
        return $self->{status}{$ctid};
    }
}

sub _run_state {
    my $abbr = shift;
    return
          $abbr =~ /r/ ? 'running'
        : $abbr =~ /b/ ? 'running' # blocked is a 'wait' state, poorly named
        : $abbr =~ /p/ ? 'paused'
        : $abbr =~ /s/ ? 'shutdown'
        : $abbr =~ /c/ ? 'crashed'
        : $abbr =~ /d/ ? 'dying'
        :                undef;
};

sub get_swap_image {
    my $self = shift;
    my $path = shift;
    my $name = $vos->{name} or die "missing VE name!";
    my $swap_name = $name . '_vmswap';
    $swap_name = '/dev/vol00/' . $swap_name if $path;
    return $swap_name;
};

sub get_template_dir {
    my $self = shift;

    my $template_dir = $prov->{config}{VirtualOS}{xen_template_dir} || '/templates';
    return $template_dir;
};

sub get_ve_config_path {
    my $self = shift;
    my $ve_name     = $self->get_ve_name();
    my $config_file = "$vos->{disk_root}/$ve_name/$ve_name.cfg";
    return $config_file;
};

sub get_ve_ram {
    my $self = shift;
    return $vos->{ram} if $vos->{ram};  # passed in value

    # value from VE config file
    my $xen_conf = $self->get_xen_config();
    if ( $xen_conf ) {
        my $ram = $xen_conf->get('memory');
        return $ram if $ram;
    };

    return 256;   # default value
};

sub get_fs_root {
    my $self = shift;
    my @caller = caller;
    my $ve_home = $self->get_ve_home( shift )
        or return $log->error( "VE name unset when called by $caller[0] at $caller[2]");
    return "$ve_home/mnt";
};

sub get_snap_root {
    my $self = shift;
    my @caller = caller;
    my $ve_home = $self->get_ve_home( shift )
        or return $log->error( "VE name unset when called by $caller[0] at $caller[2]");
    return "$ve_home/snap";
};

sub get_ve_home {
    my $self = shift;
    my @caller = caller;
    my $ve_name = $self->get_ve_name( shift )
        or return $log->error( "VE name unset when called by $caller[0] at $caller[2]");
    my $homedir = "$vos->{disk_root}/$ve_name";
    return $homedir;
};

sub get_ve_name {
    my $self = shift;
    my @caller = caller;
    my $ctid = shift || $vos->{name}
        or return $log->error( "missing VE name when called by $caller[0] at $caller[2]");
    $ctid .= '.vm';  # TODO: make this a config file option
    return $ctid;
};

sub get_ve_passwd_file {
    my $self = shift;
    my $fs_root = shift || $self->get_fs_root();

    my $pass_file = "$fs_root/etc/shadow";  # SYS 5
    return $pass_file if -f $pass_file;

    $pass_file = "$fs_root/etc/master.passwd";  # BSD
    return $pass_file if -f $pass_file;

    $pass_file = "$fs_root/etc/passwd";
    return $pass_file if -f $pass_file;

    $log->error( "\tcould not find password file", fatal => 0);
    return;
};

sub get_xen_config {
    my $self = shift;
    return $self->{xen_conf} if $self->{xen_conf};   # already got it

    my $config_file = $self->get_ve_config_path();   # no config file, don't bother
    return if ! -f $config_file;

    ## no critic
    eval "require Provision::Unix::VirtualOS::Xen::Config";  # won't load
    return if $@;
    ## use critic

    my $xen_conf = Provision::Unix::VirtualOS::Xen::Config->new();

    eval { $xen_conf->read_config($config_file); };   # parse the config file
    return if $@;

    $self->{xen_conf} = $xen_conf;                    # cache it
    return $xen_conf;
};

sub is_mounted {
    my $self = shift;
    my $image_name = shift || $self->get_disk_image();

    my $found = `/bin/mount | grep $image_name`; chomp $found;
    if ( $found ) {
        $log->audit( "$image_name is mounted" );
        return 1 
    };
    $log->audit( "$image_name is not mounted" );
    return;
};

sub is_present {
    my $self = shift;
    my %p = validate( @_, { debug => { type => BOOLEAN, optional => 1 } } );

    my $debug   = defined $p{debug} ? $p{debug} : $vos->{debug};
    my $name    = $self->get_ve_name();
    my $ve_home = $self->get_ve_home();

    $log->audit("checking if VE $name exists") if $debug;

    my $image_path = $self->get_disk_image(1);
    my $swap_path = $self->get_swap_image(1);

    my @possible_paths = ( $ve_home, $image_path, $swap_path );

    foreach my $path (@possible_paths) {
        #$log->audit("\tchecking at $path") if $debug;
        if ( -e $path ) {
            $log->audit("\tfound $name at $path") if $debug;
            return $path;
        }
    }

    $self->{status}{$name} = { state => 'non-existent' };

    $log->audit("\tVE $name does not exist");
    return;
}

sub is_running {
    my $self = shift;
    my %p = validate(
        @_, 
        {   refresh => { type => SCALAR,  optional => 1, default => 1 }, 
            debug   => { type => BOOLEAN, optional => 1 },
        }
    );

    my $debug = defined $p{debug} ? $p{debug} : $vos->{debug};
    $self->get_status( debug => $debug ) if $p{refresh};

    my $ve_name = $self->get_ve_name();

    if ( $self->{status}{$ve_name} ) {
        my $state = $self->{status}{$ve_name}{state};
        if ( $state && $state eq 'running' ) {
            $log->audit("$ve_name is running") if $debug;
            return 1;
        };
    }
    $log->audit("$ve_name is not running") if $debug;
    return;
}

sub is_enabled {
    my $self = shift;
    my %p = validate(
        @_,
        {   'name'  => { type => SCALAR,  optional => 1, },
            'debug' => { type => BOOLEAN, optional => 1, default => 1 },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $ve_name     = $p{name} || $self->get_ve_name();
    my $config_file = $self->get_ve_config_path();

    $log->audit("testing if virtual VE $ve_name is enabled");

    if ( -e $config_file ) {
        $log->audit("\tfound $ve_name at $config_file") if $p{debug};
        return 1;
    }

    $log->audit("\tdid not find $config_file");
    return;
}

sub is_valid_template {

    my $self = shift;
    my $template = shift || $vos->{template} or return;

    my $template_dir = $self->get_template_dir();
    return $template if -f "$template_dir/$template.tar.gz";

    # is $template a URL?
    if ( $template =~ /http|rsync/ ) {
        $log->audit("fetching $template");
        my $uri = URI->new($template);
        my @segments = $uri->path_segments;
        my @path_bits = grep { /\w/ } @segments;  # ignore empty fields
        my $file = $segments[-1];

        $prov->audit("fetching $file from " . $uri->host);
        $util->get_url( $template, dir => $template_dir, fatal => 0, debug => 0 );

        if ( -f "$template_dir/$file" ) {
            ($file) = $file =~ /^(.*)\.tar\.gz$/;
            return $file;
        };
    }

    return $template if -f "$template_dir/$template.tar.gz";

    return $log->error( "template '$template' does not exist and is not a valid URL",
        debug => $vos->{debug},
        fatal => $vos->{fatal},
    );
}

sub lvm_in_use {
    my $self = shift;
    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);

    my $lvdisplay = $util->find_bin( 'lvdisplay', debug => 0 );
    my $r = `$lvdisplay $image_path`;
    my ($count) = $r =~ m/# open\s+([0-9])\s+/;

    if ($count) {
        $log->audit( "$image_name is in use" );
        return 1 
    };
    $log->audit( "$image_name is not being used" );
    return;
};

sub mount {
    my $self = shift;

    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);
    my $ve_name    = $self->get_ve_name();
    my $fs_root    = $self->get_fs_root();

# returns 2 (true) if image is already mounted
    return 2 if $self->is_mounted();

    mkpath $fs_root if !-d $fs_root;

    return $log->error( "unable to create $fs_root", fatal => 0 )
        if ! -d $fs_root;

    sleep 3 if $self->lvm_in_use();

    return $log->error( "LVM is in use, cannot safely mount", fatal => 0 )
        if $self->lvm_in_use();

    $self->do_fsck();

    # mount /dev/vol00/${VE}_rootimg /home/xen/$VE/mnt
    my $mount = $util->find_bin( 'mount', debug => 0, fatal => 0 ) or return;
    $util->syscmd( "$mount $image_path $fs_root", debug => 0, fatal => 0 )
        or return $log->error( "unable to mount $image_name", fatal => 0 );
    return 1;
}

sub mount_snapshot {
    my $self = shift;

    my $image_path = $self->get_disk_image(1);
    my $snap_root  = $self->get_snap_root();
    my $snap_path  = $image_path . '_snap';

    if ( ! -d $snap_root ) {
        mkpath $snap_root 
            or return $log->error( "unable to create snap dir: $snap_root");
    };

    # mount /dev/vol00/${VE}_rootimg_snap /home/xen/$VE/snap
    my $mount = $util->find_bin( 'mount', debug => 0, fatal => 0 ) or return;
    $util->syscmd( "$mount $snap_path $snap_root", debug => 0, fatal => 0 )
        or return $log->error( "unable to mount snapshot", fatal => 0 );

    return 1;
}

sub resize_disk_image {
    my $self = shift;

    my $name = $vos->{name} or die "missing VE name!";

    $self->destroy_swap_image();
    $self->create_swap_image();

    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);
    my $target_size = $self->get_disk_size();

    # check existing disk size.
    $self->mount() or $log->error( "unable to mount disk image" );
    my $fs_root = $self->get_fs_root();
    my $df_out = qx{/bin/df -m $fs_root | /usr/bin/tail -n1};
    my (undef, $current_size, $df_used, $df_free) = split /\s+/, $df_out;
    $self->unmount();

    my $difference = $target_size - $current_size;

    # return if the same
    return $log->audit( "no disk partition changes required" ) if ! $difference;
    my $percent_diff = abs($difference / $target_size ) * 100;
    return $log->audit( "disk partition is close enough: $current_size vs $target_size" ) 
        if $percent_diff < 5;

    my $pvscan = $util->find_bin( 'pvscan', debug => 0);
    my $resize2fs = $util->find_bin( 'resize2fs', debug => 0 );

    # if new size is bigger
    if ( $target_size > $current_size ) {
# make sure there is sufficient free disk space on the HW node
        my $free = qx{$pvscan};
        $free =~ /(\d+\.\d+)\s+GB\s+free\]/;
        $free = $1 * 1024;
        return $log->error("Not enough disk space on HW node: needs $target_size but only $free MB free. Migrate account and manually increase disk space.") if $free <= $target_size;
        # resize larger
        $log->audit("Extending disk $image_name from $current_size to $target_size");
        my $cmd = "/usr/sbin/lvextend --size=${target_size}M $image_path";
        $log->audit($cmd);
        system $cmd and $log->error( "failed to extend $image_name to $target_size megs");
        $self->do_fsck();
        $cmd = "$resize2fs $image_path";
        $log->audit($cmd);
        system $cmd and $log->error( "unable to resize filesystem $image_name");
        $self->do_fsck();
        return 1;
    }

    if ( $current_size > $target_size ) {
       # see if volume can be safely shrunk - per SA team: Andrew, Ryan, & Ted

# if cannot be safely shrunk, fail.
        return $log->error( "volume has more than $target_size used, failed to shrink" ) 
            if $df_used > $target_size;

        # shrink it
        $log->audit( "Reducing $image_name from $current_size to $target_size MB");
        $self->do_fsck();
        my $cmd = "$resize2fs -f $image_path ${target_size}M";
        $log->audit($cmd);
        system $cmd and $log->error( " Unable to resize filesystem $image_name" );
        $log->audit("reduced file system");

        $cmd  = $util->find_bin( 'lvresize', debug => 0 );
        $cmd .= " --size=${target_size}M $image_path";
        $log->audit($cmd);
        #system $cmd and $log->error( "Error:  Unable to reduce filesystem on $image_name" );
        open(my $FH, '|', $cmd ) or return $log->error("failed to shrink logical volume");
        print $FH "y\n";  # deals with the non-suppressible "Are you sure..." 
        close $FH;        # waits for the open process to exit
        $log->audit("completed shrinking logical volume size");
        $self->do_fsck();
        return 1;
    };
};

sub set_fstab {
    my $self = shift;

    my $contents = <<EOFSTAB
/dev/sda1               /                       ext3    defaults,noatime 1 1
/dev/sda2               none                    swap    sw       0 0
none                    /dev/pts                devpts  gid=5,mode=620 0 0
none                    /dev/shm                tmpfs   defaults 0 0
none                    /proc                   proc    defaults 0 0
none                    /sys                    sysfs   defaults 0 0
EOFSTAB
;

    my $ve_home = $self->get_ve_home();
    $util->file_write( "$ve_home/mnt/etc/fstab", 
        lines => [ $contents ],
        debug => 0,
        fatal => 0,
    ) or return;
    $log->audit("installed /etc/fstab");
    return 1;
};

sub set_hostname {
    my $self = shift;

    $self->stop() or return;
    $self->mount() or return;

    $linux->set_hostname( 
        host    => $vos->{hostname},
        fs_root => $self->get_fs_root(),
    )
    or $log->error("unable to set hostname", fatal => 0);

    $self->unmount();
    $self->start() or return;
    return 1;
};

sub set_ips {
    my $self     = shift;
    my $fs_root  = $self->get_fs_root();
    my $template = $vos->{template};
    my $ctid     = $vos->{name};

    my %request = (
        hostname => $vos->{hostname},
        ips      => $vos->{ip},
        device   => $vos->{net_device} || 'eth0',
        fs_root  => $fs_root,
    );
    $request{distro} = $vos->{template} if $vos->{template};

    eval { $linux->set_ips( %request ); };
    $log->error( $@, fatal => 0 ) if $@;

    # update the config file, if it exists
    my $config_file = $self->get_ve_config_path() or return;
    return if ! -f $config_file;

    my @ips      = @{ $vos->{ip} };
    my $ip_list  = shift @ips;
    foreach ( @ips ) { $ip_list .= " $_"; };
    my $mac      = $self->get_mac_address();

    my @lines = $util->file_read( $config_file, debug => 0, fatal => 0) 
        or return $log->error("could not read $config_file", fatal => 0);

    foreach my $line ( @lines ) {
        next if $line !~ /^vif/;
        $line =~ /mac=([\w\d\:\-]+)\'\]/;
        $mac = $1 if $1;   # use the existing mac if possible
        $line = "vif        = ['ip=$ip_list, vifname=vif${ctid},  mac=$mac']";
    };
    $util->file_write( $config_file, lines => \@lines, fatal => 0 )
        or return $log->error( "could not write to $config_file", fatal => 0);

    return 1;
};

sub set_libc {
    my $self = shift;

    my $fs_root = $self->get_fs_root();
    my $libdir  = "/etc/ld.so.conf.d";
    my $libfile = "/etc/ld.so.conf.d/libc6-xen.conf";

    if ( ! -f "$fs_root/$libfile" ) {
        if ( ! -d "$fs_root/$libdir" ) {
            mkpath "$fs_root/$libdir" or return 
                $log->error("unable to create $libdir", fatal => 0);
            $log->audit("created $libdir");
        };
        return $log->error("could not create $libdir", fatal => 0) 
            if ! -d "$fs_root/$libdir";
        $util->file_write( "$fs_root/$libfile", 
            lines => [ 'hwcap 0 nosegneg' ], 
            debug => 0 , fatal => 0 )
            or return $log->error("could not install $libfile", fatal => 0);
        $log->audit("installed $libfile");
    };

    if ( -d "$fs_root/lib/tls" ) {
        move( "$fs_root/lib/tls", "$fs_root/lib/tls.disabled" );
        $log->audit("disabled /lib/tls");
    };
    return 1;
};

sub set_password {
    my $self = shift;
    my $arg = shift;

    my $ve_name = $self->get_ve_name();
    my $pass    = $vos->{password}
        or return $log->error( 'no password provided', fatal => 0 );

    return $log->error( "VE $ve_name does not exist",
        fatal => $vos->{fatal},
        debug => $vos->{debug},
    )
    if !$self->is_present( debug => 0 );

    $log->audit("setting VPS password");

    my $i_stopped;
    my $i_mounted;

    if ( ! $arg || $arg ne 'setup' ) {
        if ( $self->is_running( debug => 0 ) ) {
            $self->stop() or return;
            $i_stopped++;
        };
    
        my $r = $self->mount();
        $i_mounted++ if $r == 1;
    }

    my $errors;

    # set the VE root password
    $self->set_password_root()    or $errors++;
    $self->set_ssh_key()          or $errors++;
    $self->set_password_console() or $errors++;

    if ( ! $arg || $arg ne 'setup' ) {
        $self->unmount() if $i_mounted;
        $self->start() if $i_stopped;
    };
    return 1 if ! $errors;
    return;
};

sub set_password_console {
    my $self = shift;

    my $pass    = $vos->{password} or return 1;
    my $ve_name = $self->get_ve_name();

    $user ||= Provision::Unix::User->new( prov => $prov );

    $log->audit( "creating the console account and password." );

    my $username = $ve_name;
    $username =~ s/\.//g;  # strip the . out of the veid name: NNNNN.vm

    return if ! $user->exists( $username );

    my %request = ( username => $username, password => $pass );

    if ( $vos->{ssh_key} ) {
        $request{ssh_key} = $vos->{ssh_key};
        $request{ssh_restricted} = "sudo /usr/sbin/xm console $ve_name";
    };

    $user->set_password( %request, fatal => 0, debug => 0 ) or return;
    return 1;
};

sub set_password_root {
    my $self = shift;

    my $pass = $vos->{password} or return 1;  # no change requested
    my $debug = $vos->{debug};

    $user ||= Provision::Unix::User->new( prov => $prov );

    my $pass_file = $self->get_ve_passwd_file() or return;
    my @lines     = $util->file_read( $pass_file, fatal => 0 );

    grep { /^root:/ } @lines 
        or return $log->error( "\tcould not find root password entry in $pass_file!", fatal => 0);

    my $crypted = $user->get_crypted_password($pass);

    foreach ( @lines ) {
        s/root\:.*?\:/root\:$crypted\:/ if m/^root\:/;
    };

    $util->file_write( $pass_file, lines => \@lines, debug => $debug, fatal => 0 ) or return;
    $log->audit( "VE root password set." );
    return 1;
};

sub set_ssh_key {
    my $self = shift;

    return 1 if ! $vos->{ssh_key};

    return $log->error( "VE does not exist" ) 
        if !$self->is_present( debug => 0 );

    $user ||= Provision::Unix::User->new( prov => $prov );

    my $fs_root = $self->get_fs_root();
    eval {
        $user->install_ssh_key(
            homedir => "$fs_root/root",
            ssh_key => $vos->{ssh_key},
            debug   => $vos->{debug},
        );
    };
    return $log->error( $@, fatal => 0 ) if $@;
    $log->audit("installed ssh key");
    return 1;
};

sub unmount {
    my $self = shift;
    my $quiet = shift;

    my $debug = $vos->{debug};
    my $fatal = $vos->{fatal};

    return 1 if ! $self->is_mounted();
    $debug = $fatal = 0 if $quiet;

    # snapshots can interfere with unmount operation, try to remove them
    $self->destroy_snapshot();

    my $image_name = $self->get_disk_image();
    my $image_path = $self->get_disk_image(1);

    my $umount = $util->find_bin( 'umount', debug => 0, fatal => $fatal )
        or return $log->error( "unable to find 'umount' program");

    $util->syscmd( "$umount $image_path", debug => 0, fatal => $fatal );

    sleep 5 if ( $self->is_mounted );
    if ( $self->is_mounted ) { 
        $log->error( "unable to unmount $image_name" ) if ! $quiet;
        return;
    };

    $debug = $fatal = 0 if $quiet;
    $self->do_fsck();
    return 1;
}

sub unmount_snapshot {
    my $self = shift;
    my $image_path = $self->get_disk_image(1);
    my $snap_path  = $image_path . '_snap';

    my $umount = $util->find_bin( 'umount', debug => 0, fatal => 0 ) or return;
    $util->syscmd( "$umount $snap_path", debug => 0, fatal => 0 )
        or return $log->error( "unable to unmount snapshot, is a backup active?", fatal => 0 );
    return 1;
};

sub unmount_inactive_snapshots {
    my $self = shift;

    my $df     = $util->find_bin( 'df', debug => 0, fatal => 0 ) or return;
    my $ps     = $util->find_bin( 'ps', debug => 0, fatal => 0 ) or return;
    my $grep   = $util->find_bin( 'grep', debug => 0, fatal => 0 ) or return;
    my $umount = $util->find_bin( 'umount', debug => 0, fatal => 0 ) or return;

# get a list of snapshots that are mounted and try to unmount them all 
    my @snapshots = `$df | $grep rootimg_snap`; chomp @snapshots;

    foreach my $snap ( @snapshots ) {
        my ($veid) = $snap =~ /\-([0-9]+)_rootimg_snap/;
        if ( ! $veid ) {
            print "unable to parse veid from $snap\n";
            next;
        };
        my @rsync_procs = `$ps ax | $grep rsync | $grep -v grep | $grep $veid`;
        if ( scalar @rsync_procs > 0 ) {
            print "found rsync process for $veid:\n" . join("\t", @rsync_procs) . "\n";
            next;
        };
        system "$umount /dev/vol00/${veid}_rootimg_snap";
    };
};

sub cleanup_inactive_snapshots {
    my $self = shift;

    my $lvremove = $util->find_bin('lvremove', debug => 0) or return;
    my $ps = $util->find_bin('ps',debug=>0);
    my $grep = $util->find_bin('grep',debug=>0);

    foreach my $snap ( glob('/dev/vol00/*_snap') ) {
        my ($veid) = $snap =~ /\/([0-9]+)_rootimg_snap/;
        next if ! $veid;
        my @rsync_procs = `$ps ax | $grep rsync | $grep -v grep | $grep $veid`;
        if ( scalar @rsync_procs > 0 ) {
            print "found rsync process for $veid:\n" . join("\t", @rsync_procs) . "\n";
            next;
        };

        # this will fail if snapshot is in use
        system "$lvremove -f /dev/vol00/${veid}_rootimg_snap";
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::Linux::Xen - provision a linux VPS using Xen

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  use Provision::Unix;
  use Provision::Unix::VirtualOS;

  my $prov = Provision::Unix->new( debug => 0 );
  my $vos  = Provision::Unix::VirtualOS->new( prov => $prov );
 
  $vos->create()

General 

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-virtualos at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::VirtualOS::Linux::Xen

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Provision-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Provision-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Provision-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/Provision-Unix>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
