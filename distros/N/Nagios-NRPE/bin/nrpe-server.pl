#!/usr/bin/perl

=pod

=head1 NAME

nrpe-server - A Nagios NRPE Server

=head1 SYNOPSIS

 ./nrpe-server --conf ./nrpe-server.conf --pid /var/run/pid --listen 127.0.0.1 --port 5666

=head1 DESCRIPTION

This is a simple perl implementation of the nagios-nrpe server you can see SYNOPSIS for how to start it.

After it is started it will listen on a given port (either by config or on the commandline) and run checks
as defined in your config.

NOTE: Options set on the commandline can overwrite options defined in the config file.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marschke <andreas.marschke@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.010_000;

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use IO::File;
use Pod::Usage;
use Config::File;
use IPC::Cmd qw(run);
use Nagios::NRPE::Daemon;
use Nagios::NRPE::Packet;
use threads;

our $VERSION = '1.0.3';

use constant { NRPE_CONF_DIR => '/etc/nagios' };
my ( $listen_cmd, $port_cmd, $config_cmd, $pid_cmd, $ssl_cmd );

my $result = GetOptions(
    "l|listen=s" => \$listen_cmd,
    "p|port=s"   => \$port_cmd,
    "c|config=s" => \$config_cmd,
    "P|pid=s"    => \$pid_cmd,
    "s|ssl"      => \$ssl_cmd,
    "h|help"     => sub {
        pod2usage(
            -exitval   => 0,
            -verbose   => 99,
            -noperldoc => 1
        );
    }
);

my (
    $listen,          $port,               $log_facillity,
    $pid,             $user,               $ssl,
    $nrpe_group,      $allowed_hosts,      $debug,
    $command_timeout, $connection_timeout, $commandlist
);

my $config_hash;

if ( defined $config_cmd ) {
    $config_hash = Config::File::read_config_file($config_cmd)
      or die "ERROR: Can't open config. Reason: $!";
}
elsif ( -e NRPE_CONF_DIR . "/nrpe.cfg" ) {
    $config_hash = Config::File::read_config_file( NRPE_CONF_DIR . "/nrpe.cfg" )
      or die "ERROR: Can't open config. Reason: $!";
}

$commandlist = $config_hash->{command};

$listen = $listen_cmd || $config_hash->{server_address} || "127.0.0.1";
$port   = $port_cmd   || $config_hash->{server_port}    || "5666";
$pid = $pid_cmd || $config_hash->{pid_file} || "/var/run/nagios/nrpe.pid";
$ssl = 1 if defined $ssl_cmd;
$allowed_hosts      = $config_hash->{allowed_hosts}      || "0.0.0.0";
$command_timeout    = $config_hash->{command_timeout}    || "60";
$connection_timeout = $config_hash->{connection_timeout} || 300;

die "No Commands to execute given." if ( not defined $commandlist );

foreach ( keys %$commandlist ) {
    my @args = split /\ /, $commandlist->{$_};
    my $hashref = {};
    $hashref->{bin} = $args[0];
    my $length = scalar @args;
    my $argstr = "";
    for ( my $i = 1 ; $i < $length ; $i++ ) {
        $argstr .= " " . $args[$i];
    }

    $hashref->{args} = $argstr;
    $commandlist->{$_} = $hashref;
}

my $daemon = Nagios::NRPE::Daemon->new(
    listen      => $listen,
    port        => $port,
    pid_dir     => $pid,
    ssl         => $ssl,
    commandlist => $commandlist,
    callback    => sub {
        my ( $self, $check, @options ) = @_;
        my $commandlist = $self->commandlist();
        if ( $commandlist->{$check} ) {
            my $args = $commandlist->{$check}->{args};
            my $i    = 0;
            foreach (@options) {
                $i++;
                $args =~ "s/\$ARG$i\$/$_/";
            }
            my $buffer;
            if (
                scalar run(
                    command => $commandlist->{$check}->{bin} . " " . $args,
                    verbose => 0,
                    buffer  => \$buffer,
                    timeout => 20
                )
              )
            {
                chomp $buffer;
                return $buffer;
            }
        }
    }
);

threads->new( $daemon->start() );
