package Provision::Unix::VirtualOS::Linux;
# ABSTRACT: a framework for building Linux virtual machines
$Provision::Unix::VirtualOS::Linux::VERSION = '1.08';
use strict;
use warnings;

use File::Copy;
use File::Path;
#use English qw( -no_match_vars );
use Params::Validate qw(:all);

use lib 'lib';
use Provision::Unix;

my ($prov, $vos, $util);
my %std_opts = ( debug => 0, fatal => 0 );

sub new {
    my $class = shift;
    my %p = validate(@_, { vos => { type => OBJECT } } );

    $vos  = $p{vos};
    $prov = $vos->{prov};
    $util = $vos->{util};

    my $self = { 
        vos  => $vos, 
        util => $util,
    };
    bless $self, $class;

    $prov->audit( $class . sprintf( " loaded by %s, %s, %s", caller ) );

    return $self;
}

sub get_distro {
    my $self = shift;
    my $fs_root = shift;
    return if ! $fs_root;
    my $etc = "$fs_root/etc";
    return if ! -d "$fs_root/etc";

# credit to Max Vohra for distro detection logic 
    return 
        -e "$etc/debian_version"    ? 'debian'
      : -e "$etc/redhat-release"    ? 'redhat'      
      : -e "$etc/SuSE-release"      ? 'suse'
      : -e "$etc/slackware-version" ? 'slackware'
      : -e "$etc/gentoo-release"    ? 'gentoo'
      : -e "$etc/arch-release"      ? 'arch'
      : undef;
};

sub get_package_manager {
    my $distro = shift or return;
    return $distro eq 'debian'    ? 'apt'
         : $distro eq 'redhat'    ? 'yum'
         : $distro eq 'suse'      ? 'zypper'
         : $distro eq 'slackware' ? undef
         : $distro eq 'gentoo'    ? 'emerge'
         : $distro eq 'arch'      ? 'packman'
         : return;
};

sub install_kernel_modules {
    my $self = shift;
    my %p = validate(@_,
        {   fs_root   => { type => SCALAR, },
            url       => { type => SCALAR, optional => 1 },
            version   => { type => SCALAR, optional => 1 },
            test_mode => { type => BOOLEAN, optional => 1 },
        },
    );

    my $fs_root = $p{fs_root};
    my $url     = $p{url} || 'http://mirror.vpslink.com/xen';
    my $version = $p{version} = `uname -r`; chomp $version;

    return 1 if $p{test_mode};

    if ( -d "/boot/domU" ) {
        my ($modules) = glob("/boot/domU/modules*$version*");
        $modules or return $prov->error( 
            "unable to find kernel modules in /boot/domU", %std_opts);
        my $module_dir = "$fs_root/lib/modules";
        if ( ! -d $module_dir ) {
            mkpath $module_dir 
                or return $prov->error("unable to create $module_dir", %std_opts);
        };
        my $cmd = "tar -zxpf $modules -C $module_dir";
        $util->syscmd( $cmd, %std_opts ) or return;
    }
    else {
        chdir $fs_root;
        foreach my $mod ( qw/ modules headers / ) {
#    foreach my $mod ( qw/ modules module-fuse headers / ) {
            next if $mod eq 'headers' && ! "$fs_root/usr/src";
            my $file = "xen-$mod-$version.tar.gz";
            $util->get_url( "$url/$file", %std_opts ) or return;
            $util->syscmd( "tar -zxpf $file -C $fs_root", %std_opts ) or return;
            unlink $file;
        };
        chdir "/home/xen";
    };

    # clean up behind template authors
    unlink "$fs_root/.bash_history" if -e "$fs_root/.bash_history";
    unlink "$fs_root/root/.bash_history" if -e "$fs_root/root/.bash_history";
    return 1;
};

sub set_rc_local {
    my $self = shift;
    my %p = validate(@_, { fs_root => { type => SCALAR } } );

    my $fs_root = $p{fs_root};

    my $rc_local = "$fs_root/etc/conf.d/local.start"; # gentoo
    if ( ! -f $rc_local ) {
        $rc_local = "$fs_root/etc/rc.local";  # everything else
    };

    return $util->file_write( $rc_local, 
        lines  => [ 'pkill -9 -f nash', 
                    'ldconfig > /dev/null', 
                    'depmod -a > /dev/null', 
                    'exit 0',
                  ],
        mode   => '0755',
        append => 0,
        %std_opts,
    );
};

sub set_ips {
    my $self = shift;
    my %p = validate(@_,
        {   ips       => { type => ARRAYREF },
            fs_root   => { type => SCALAR },
            distro    => { type => SCALAR,  optional => 1 },
            device    => { type => SCALAR,  optional => 1 },
            hostname  => { type => SCALAR,  optional => 1 },
            test_mode => { type => BOOLEAN, optional => 1 },
        }
    );

    my $distro = delete $p{distro};
    $distro ||= $self->get_distro( $p{fs_root} );

    return 1 if $p{test_mode};

    return $self->set_ips_debian(%p) if $distro =~ /debian|ubuntu/i;
    return $self->set_ips_redhat(%p) if $distro =~ /redhat|fedora|centos/i;
    return $self->set_ips_gentoo(%p) if $distro =~ /gentoo/i;

    $prov->error( "unable to set up networking on distro $distro", %std_opts );
    return;
};

sub set_ips_debian {
    my $self = shift;
    my %p = validate(@_,
        {   ips       => { type => ARRAYREF },
            fs_root   => { type => SCALAR },
            device    => { type => SCALAR,  optional => 1 },
            hostname  => { type => SCALAR,  optional => 1 },
            test_mode => { type => BOOLEAN, optional => 1 },
        }
    );

    my $device = $p{device} || 'eth0';
    my @ips = @{ $p{ips} };
    my $test_mode = $p{test_mode};
    my $hostname = $p{hostname};
    my $fs_root  = $p{fs_root};

    my $ip = shift @ips;
    my @octets = split /\./, $ip;
    my $gw  = "$octets[0].$octets[1].$octets[2].1";
    my $net = "$octets[0].$octets[1].$octets[2].0";

    my $config = <<EO_FIRST_IP
# This configuration file is generated by Provision::Unix.
# WARNING: Do not edit this file, else your changes will be lost.

# Auto generated interfaces
auto $device lo
iface lo inet loopback
iface $device inet static
    address $ip
    netmask 255.255.255.0
    up route add -net $net netmask 255.255.255.0 dev $device
    up route add default gw $gw
EO_FIRST_IP
;

    my $alias_count = 0;
    foreach ( @ips ) {
        $config .= <<EO_ADDTL_IPS

auto $device:$alias_count
iface $device:$alias_count inet static
    address $_
    netmask 255.255.255.255
    broadcast 0.0.0.0
EO_ADDTL_IPS
;
        $alias_count++;
    };
    #return $config;

    my $config_file = "/etc/network/interfaces";
    return $config if $test_mode;

    if ( $util->file_write( "$fs_root/$config_file", 
            lines => [ $config ], 
            %std_opts,
            ) 
        ) 
    {
        $prov->audit( "updated debian $config_file with network settings");
    }
    else {
        $prov->error( "failed to update $config_file with network settings", %std_opts);
    };

    if ( $hostname) {
        $self->set_hostname_debian( host => $hostname, fs_root => $fs_root );
    };
    return $config;
};

sub set_ips_gentoo {
    my $self = shift;
    my %p = validate(@_,
        {   ips       => { type => ARRAYREF },
            fs_root   => { type => SCALAR },
            device    => { type => SCALAR,  optional => 1 },
            gw_octet  => { type => SCALAR,  optional => 1 },
            hostname  => { type => SCALAR,  optional => 1 },
            test_mode => { type => BOOLEAN, optional => 1 },
        }
    );

    my $device   = $p{device} || 'eth0';
    my @ips      = @{ $p{ips} };
    my $test_mode= $p{test_mode};
    my $hostname = $p{hostname};
    my $fs_root  = $p{fs_root};

    my $ip       = shift @ips;
    my @octets   = split /\./, $ip;
    my $gw_octet = $p{gw_octet} || 1;
    my $gw       = "$octets[0].$octets[1].$octets[2].$gw_octet";

    my $conf_dir = "$fs_root/etc/conf.d";
    my $net_conf = "$conf_dir/net";

    my (@lines, @new_lines);
    if ( -r $net_conf ) {
        @lines = $util->file_read( $net_conf, %std_opts )
            or $prov->error("error trying to read /etc/conf.d/net", %std_opts);
    };
    foreach ( @lines ) {
        next if $_ =~ /^config_$device/;
        next if $_ =~ /^routes_$device/;
        push @new_lines, $_;
    };
    my $ip_string = "config_$device=( \n\t\"$ip/24\"";
    foreach ( @ips ) { $ip_string .= "\n\t\"$_/32\""; };
    $ip_string .= ")";
    push @new_lines, $ip_string;
    push @new_lines, "routes_$device=(\n\t\"default via $gw\"\n)";
    $prov->audit("net config: $ip_string");
    $util->file_write( $net_conf, lines => \@new_lines, %std_opts )
        or return $prov->error(
        "error setting up networking, unable to write to $net_conf", %std_opts);

    return 1;
    #my $script = "/etc/runlevels/default/net.$device";
};

sub set_ips_redhat {
    my $self = shift;
    my %p = validate(@_,
        {   ips       => { type => ARRAYREF },
            fs_root   => { type => SCALAR },
            device    => { type => SCALAR,  optional => 1 },
            gw_octet  => { type => SCALAR,  optional => 1 },
            hostname  => { type => SCALAR,  optional => 1 },
            test_mode => { type => BOOLEAN, optional => 1 },
        }
    );

    my $etc       = "$p{fs_root}/etc";
    my $device    = $p{device} || 'eth0';
    my @ips       = @{ $p{ips} };
    my $hostname  = $p{hostname} || 'localhost';
    my $test_mode = $p{test_mode};

    my $ip = shift @ips;
    my @octets = split /\./, $ip;
    my $gw_octet = $p{gw_octet} || 1;
    my $gw  = "$octets[0].$octets[1].$octets[2].$gw_octet";
    my $net = "$octets[0].$octets[1].$octets[2].0";

    my $netfile = "sysconfig/network";
    my $if_file = "sysconfig/network-scripts/ifcfg-$device";
    my $route_f = "sysconfig/network-scripts/route-$device";
    my $errors_before = scalar @{ $prov->{errors} };

    # cleanup any existing files that may no longer be valid
    unlink <$etc/$if_file*>;

    my $contents = <<EO_NETFILE
NETWORKING="yes"
GATEWAY="$gw"
HOSTNAME="$hostname"
EO_NETFILE
;
    return $contents if $test_mode;
    my $r = $util->file_write( "$etc/$netfile", lines => [ $contents ], %std_opts );
    $r ? $prov->audit("updated /etc/$netfile with hostname $hostname and gateway $gw")
       : $prov->error("failed to update $netfile", fatal => 0);

    $contents = <<EO_IF_FILE
DEVICE=$device
BOOTPROTO=static
ONBOOT=yes
IPADDR=$ip
NETMASK=255.255.255.0
EO_IF_FILE
;
    $r = $util->file_write( "$etc/$if_file", lines => [ $contents ], %std_opts );
    $r ? $prov->audit("updated /etc/$if_file with ip $ip")
       : $prov->error("failed to update $if_file", %std_opts);

    $contents = <<EO_ROUTE_FILE
$net/24 dev $device scope host
default via $gw
EO_ROUTE_FILE
;
    $r = $util->file_write( "$etc/$route_f", lines => [ $contents ], %std_opts );
    $r ? $prov->audit("updated /etc/$route_f with net $net and gw $gw")
       : $prov->error("failed to update $route_f", %std_opts);

    my $alias_count = 0;
    foreach ( @ips ) {
        $if_file = "sysconfig/network-scripts/ifcfg-$device:$alias_count";
        $contents = <<EO_IF_FILE
DEVICE=$device:$alias_count
BOOTPROTO=static
ONBOOT=yes
IPADDR=$_
NETMASK=255.255.255.0
EO_IF_FILE
;
        $alias_count++;
        $r = $util->file_write( "$etc/$if_file", lines => [ $contents ], %std_opts );
        $r ? $prov->audit("updated /etc/$if_file with device $device and ip $_")
           : $prov->error("failed to update $if_file", %std_opts);
    };
    return if scalar @{ $prov->{errors}} > $errors_before;
    return 1;
};

sub set_hostname {
    my $self = shift;
    my %p = validate(@_,
        {   host    => { type => SCALAR },
            fs_root => { type => SCALAR },
            distro  => { type => SCALAR, optional => 1 },
        }
    );

    my $distro = delete $p{distro} || $self->get_distro( $p{fs_root} );
    return $self->set_hostname_debian(%p) if $distro =~ /debian|ubuntu/i;
    return $self->set_hostname_redhat(%p) if $distro =~ /redhat|fedora|centos/i;
    return $self->set_hostname_gentoo(%p) if $distro =~ /gentoo/i;

    $prov->error( "unable to set hostname on distro $distro", %std_opts );
    return;
};

sub set_hostname_debian {
    my $self = shift;
    my %p = validate(@_,
        {   host    => { type => SCALAR },
            fs_root => { type => SCALAR },
        }
    );

    my $host    = $p{host};
    my $fs_root = $p{fs_root};

    $util->file_write( "$fs_root/etc/hostname" , 
        lines => [ $host ], 
        %std_opts,
    )
    or return $prov->error("unable to set hostname", %std_opts );

    $prov->audit("wrote hostname to /etc/hostname");
    return 1;
};

sub set_hostname_gentoo {
    my $self = shift;
    my %p = validate(@_,
        {   host    => { type => SCALAR },
            fs_root => { type => SCALAR },
        }
    );

    my $host    = $p{host};
    my $fs_root = $p{fs_root};

    mkpath "$fs_root/etc/conf.d" if ! "$fs_root/etc/conf.d";

    $util->file_write( "$fs_root/etc/conf.d/hostname" , 
        lines => [ "HOSTNAME=$host" ],
        %std_opts,
    )
    or return $prov->error("error setting hostname", %std_opts);

    $prov->audit("updated /etc/conf.d/hostname with $host");
    return 1;
};

sub set_hostname_redhat {
    my $self = shift;
    my %p = validate(@_,
        {   host    => { type => SCALAR },
            fs_root => { type => SCALAR },
        }
    );

    my $fs_root = $p{fs_root};
    my $host    = $p{host};

    my $config = "$fs_root/etc/sysconfig/network";
    my @new;
    if ( -r $config ) {
        my @lines = $util->file_read( $config, %std_opts );
        foreach ( @lines ) {
            next if $_ =~ /^HOSTNAME/;
            push @new, $_;
        };
    };
    push @new, "HOSTNAME=$host";

    $util->file_write( $config, lines => \@new, %std_opts )
    or return $prov->error("failed to update $config with hostname $host", %std_opts);

    $prov->audit("updated $config with hostname $host");
    return 1;
};

sub set_upstart_console {
    my $self = shift;
    my ($fs_root, $getty_cmd) = @_;

    my $contents = <<EO_INITTAB
#
# This service maintains a getty on xvc0 from the point the system is
# started until it is shut down again.

start on runlevel 2
start on runlevel 3

stop on runlevel 0
stop on runlevel 1
stop on runlevel 4
stop on runlevel 5
stop on runlevel 6

respawn
exec $getty_cmd

EO_INITTAB
;

    $util->file_write( "$fs_root/etc/event.d/xvc0", 
        lines => [ $contents ],
        %std_opts,
    ) or return;
    $prov->audit( "installed /etc/event.d/xvc0" );

    my $serial = "$fs_root/etc/event.d/serial";
    return if ! -e $serial;

    my @lines = $util->file_read( $serial, %std_opts );
    my @new;
    foreach my $line ( @lines ) {
        if ( $line =~ /^[start|stop]/ ) {
            push @new, "#$line";
            next;
        };
        push @new, $line;
    }
    $util->file_write( "$fs_root/etc/event.d/serial", 
        lines => \@new,
        %std_opts,
    ) or return;
    $prov->audit("updated /etc/event.d/serial");
    return;
}

sub setup_inittab {
    my $self = shift;
    my %p = validate(@_, 
        {   fs_root  => { type => SCALAR }, 
            template => { type => SCALAR },
        } 
    );

    my $fs_root = $p{fs_root};
    my $template = $p{template};
    my $login;
    my $tty_dev = 'xvc0';
#    $tty_dev = 'console' 
#        if ( -e "$fs_root/dev/console" && ! -e "$fs_root/dev/xvc0" );

    if ( $template !~ /debian|ubuntu/i ) {
        $login = $self->setup_autologin( fs_root => $fs_root );
    };
    if ( $template =~ /redhat|fedora|centos/ ) {
        $tty_dev = 'console';
    };
    $login ||= -e "$fs_root/bin/bash" ? '/bin/bash' : '/bin/sh';

    my $getty_cmd = -e "$fs_root/sbin/getty" ?
        "/sbin/getty -n -l $login 38400 $tty_dev"
                  : -e "$fs_root/sbin/agetty" ?
        "/sbin/agetty -n -i -l $login $tty_dev 38400"
                  : '/bin/sh';

    # check for upstart
    if ( -e "$fs_root/etc/event.d" ) {   
        $self->set_upstart_console( $fs_root, $getty_cmd );
    };

    my $inittab = "$fs_root/etc/inittab";
    my @lines = $util->file_read( $inittab, %std_opts );
    my @new;
    foreach ( @lines ) {
        next if $_ =~ /^1:/;
        push @new, $_;
    }
    push @new, "1:2345:respawn:$getty_cmd";
    copy $inittab, "$inittab.dist";
    $util->file_write( $inittab, lines => \@new, %std_opts )
        or return $prov->error( "unable to write $inittab", %std_opts);

    $prov->audit("updated /etc/inittab ");
    return 1;
};

sub setup_autologin {
    my $self = shift;
    my %p = validate(@_, { fs_root => { type => SCALAR, } } );

    my $fs_root = $p{fs_root};

    my $auto = <<'EO_C_CODE'
#include <unistd.h>
/* 
  http://wiki.archlinux.org/index.php/Automatically_login_some_user_to_a_virtual_console_on_startup
*/
int main() {
    printf( "%s \n", "Logging on to VPS console. Press Ctrl-] to Quit.");
    printf( "%s \n", "Press Enter to start." );
    execlp( "login", "login", "-f", "root", 0);
}
EO_C_CODE
;

    $util->file_write( "$fs_root/tmp/autologin.c", 
        lines => [ $auto ], 
        %std_opts 
    ) or return;

    my $chroot = $util->find_bin( 'chroot', %std_opts ) or return;
    my $gcc = $util->find_bin( 'gcc', %std_opts ) or return;
    my $cmd = "$chroot $fs_root $gcc -m32 -o /bin/autologin /tmp/autologin.c";
    $util->syscmd( $cmd, %std_opts ) or return;
    unlink "$fs_root/tmp/autologin.c";
    return if ! -x "$fs_root/bin/autologin";
    return '/bin/autologin';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::Linux - a framework for building Linux virtual machines

=head1 VERSION

version 1.08

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
