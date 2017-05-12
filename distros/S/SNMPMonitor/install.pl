#!/usr/bin/perl
use strict;
use warnings;

#BEGIN PRIVATE GLOBAL CONFIGURATION
my $base_dir = `pwd`;
chomp $base_dir;
my $build_dir = $base_dir . '/build';

print $build_dir . "\n";

my $mod_root_loc = 'http://backpan.perl.org/authors/id/H/HA/HARDAKER/';
my @req_modules = (
    'SNMP-5.0301002.tar.gz',
    'NetSNMP-default_store-5.0301.tar.gz',
    'NetSNMP-OID-5.0301.tar.gz',
    'NetSNMP-agent-5.0301.tar.gz',
    'NetSNMP-ASN-5.0301.tar.gz',

);

my @snmp_packages = (
    'net-snmp',
    'net-snmp-libs',
    'net-snmp-config',
    'net-snmp-devel',
    'net-snmp-utils',
);
    
my @cpan_modules = (
    'Module::Pluggable',
    'parent',
    'common::sense',
);

my $snmp_config = '/etc/snmp/snmpd.conf';
my $perl = get_perl_version();

my $monitor_app_name = 'mail_queue_monitor.pl';
my $monitor_app__install_path = '/usr/share/snmp/';
my $monitor_app = '/usr/share/snmp/mail_queue_monitor.pl';

#set level of comfort messages.  
my $debugging = 2;

#System commands:
my $restart_snmpd = '/etc/init.d/snmpd restart';


make_temp_install_dir();
install_snmp_deps();
download_modules();
extract_modules();
install_modules();
install_cpan_modules();
install_snmp_monitor();
configure_snmp(is_snmp_configured());

#TODO:
#configure_iptables unless iptables_is_configured();
cleanup();

sub get_perl_version {
    my $perl_ver;
    print "Searching for Perl compiled with multithreading\n" if $debugging;
    use Config;
    if ($Config{usethreads}) {
        print "Base Perl version uses threading support\n";
        $perl_ver = 'perl';
    }
    else {
        $_ = `whereis perl`;
        my $perl_ver = $2 if m/(.*)(perl\.\d{2,})(.*)/;
        print "Perl version $perl_ver\n";
        if ($perl_ver) {
            print "Perl found $perl_ver\n" if $debugging;
        }
        else {
            die "Perl with multithreading support not found\n";
        }
    }
    return $perl_ver;
}

sub install_cpan_modules {
    system "cpan $_" foreach @cpan_modules;
}

sub install_snmp_monitor {
    chdir $base_dir;
    print `perl Makefile.PL`;
    print `make`;
    print `make test`;
    print `make install`;
}

sub install_snmp_deps {
    print "Installing net-snmp and dependancies\n" if $debugging;
    my $yum = `yum -y install $_` foreach @snmp_packages;
    print $yum if $debugging > 1;
}

sub make_temp_install_dir {
    print "Making temporary install directory\n" if $debugging > 1;
    mkdir $build_dir, 0755  unless (-d $build_dir);
}

sub download_modules {
    print "Downloading Necessary Modules\n" if $debugging > 1;
    chdir $build_dir;
    foreach (@req_modules) {
        system 'wget ' . $mod_root_loc . $_;
    }
}

sub extract_modules {
    print "Extracting Necessary Modules\n" if $debugging > 1;
    chdir $build_dir;
    foreach (@req_modules) {
        system "tar xzf $_";
    }
}

sub export_env_vars {
    print "Exporting NETSNMP_DONT_CHECK_VERSION=1\n" if $debugging > 1;
    $ENV{NETSNMP_DONT_CHECK_VERSION} = 1;
}

sub install_modules {
    print "Installing Necessary Modules\n" if $debugging > 1;
    export_env_vars;
    foreach (@req_modules) {
        print "returning to $build_dir\n" if $debugging > 1;
        chdir $build_dir;
        s/(.*).tar.gz/$1/mgsx;
        print "entering extracted dir $_\n" if $debugging > 1;
        chdir $_;
        print "Installing $_\n" if $debugging > 1;
        system "$perl Makefile.PL";
        system 'make';
        system 'make test';
        system 'make install';
    }
}

sub is_snmp_configured {
    open my $FHIN, '<', $snmp_config;
    my ($access_found, $monitor_found, @configure);
    foreach (<$FHIN>){
        $access_found += 1 if m/rocommunity IPMONITOR 72.18.140.178/;
        $monitor_found += 1 if m{use SNMPMonitor};
    }
    push @configure, 'access' unless $access_found;
    push @configure, 'monitor' unless $monitor_found;
    return @configure;
}

sub configure_snmp {
    my $access_list = get_access_list();
    my $monitor_directives = get_monitor_directives();
    return unless @_;

    my @to_configure = @_;

    open my $FHOUT, '>>', $snmp_config;
    foreach (@to_configure){
        if ($_ eq 'access'){
            print "Appending $snmp_config with the access_list\n" 
                if $debugging > 1;
            print $FHOUT $access_list;
        }
        elsif ($_ eq 'monitor'){
            print "Appending $snmp_config with the monitor directives\n" 
                if $debugging > 1;
            print $FHOUT $monitor_directives;
        }
    }        
    print "SNMP Configured, restarting snmpd\n";
    my $ret_val = `/etc/init.d/snmpd restart`;
    print $ret_val if $debugging > 1;
}


sub configure_iptables {

}

sub iptables_is_configured {

}

sub install_monitor_application {
    use File::Copy ("cp");
    cp ($monitor_app_name, $monitor_app);
}

sub install_snmp_perl {
    open my $FHOUT, '>', '/usr/share/snmp/snmp_perl.pl';
    my $a =<<'END';
##
## SNMPD perl initialization file.
##

use NetSNMP::agent;
$agent = new NetSNMP::agent('dont_init_agent' => 1,
                            'dont_init_lib' => 1);
END
    print $FHOUT $a;

}

sub cleanup {
    if ($debugging > 2) {
        print "Cleaning up after the installation\n" if $debugging;
        system "rm -vrf $build_dir";
    }
    else {
        system "rm -rf $build_dir";
    }
}



################################################################################
################################################################################
# subs to return file values

sub get_access_list {
    my $access_list = <<'END_ACCESS_LIST';
### 
#  Access List
#  inserted from auto_snmp_monitor_config.pl
###

# Lock access for the community IPMONITOR to ipMonitor's IP address
rocommunity IPMONITOR 72.18.140.178

# create a debug user accessable only from this machine.
rocommunity debug localhost

END_ACCESS_LIST

    return $access_list;

}

sub get_monitor_directives {
    my $monitor_directives = <<'END_MONITOR_DIRECTIVES';
###  
#  Custom Monitor Directives
#  inserted from auto_snmp_monitor_config.pl
###

# Create and register our SMTP monitor

perl use SNMPMonitor;
perl my $monitor = SNMPMonitor->new;

END_MONITOR_DIRECTIVES
    return $monitor_directives;
}
