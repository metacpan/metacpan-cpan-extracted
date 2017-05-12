package Pushmi::Config;
use strict;
use warnings;
use YAML::Syck;
use Cache::Memcached;
use Log::Log4perl;

my $config;

sub config {
    return $config if $config;

    my $file = $ENV{PUSHMI_CONFIG} || '/etc/pushmi.conf';
    unless (-e $file) {
	warn "pushmi config $file doesn't exist.\n";
	return $config = {};
    }

    return $config = LoadFile($file);
}

sub logger {
    shift;
    my $file = $ENV{PUSHMI_CONFIG} || '/etc/pushmi.conf';
    $file =~ s/pushmi/pushmi-log/;
    Log::Log4perl::init($file) if -e $file;
    Log::Log4perl::init('/etc/pushmi-log.conf') if -e '/etc/pushmi-log.conf';
    return Log::Log4perl->get_logger(@_);
}

sub memcached {
    return Cache::Memcached->new(
        {   'servers' =>
                [ "127.0.0.1:" . (Pushmi::Config->config->{authproxy_port} || 7123) ],
            'debug' => 0
        }
    );

}

1;
