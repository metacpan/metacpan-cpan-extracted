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
use IPC::Cmd qw(run_forked);
use Nagios::NRPE::Daemon;
use Nagios::NRPE::Packet qw(STATE_UNKNOWN);
use threads;

our $VERSION = '2.0.2';

use constant {NRPE_CONF_DIR => '/etc/nagios'};
my ($listen_cmd, $port_cmd, $config_cmd, $pid_cmd, $ssl_cmd, $adh_cmd);

my $result = GetOptions(
    "l|listen=s"  => \$listen_cmd,
    "p|port=s"    => \$port_cmd,
    "c|config=s"  => \$config_cmd,
    "P|pid=s"     => \$pid_cmd,
    "s|ssl"       => \$ssl_cmd,
    "d|use-adh=i" => \$adh_cmd,
    "h|help"      => sub {
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
    $command_timeout, $connection_timeout, $commandlist,
    $SSL_cert_file,   $SSL_key_file,       $SSL_cipher_list
   );

my $config_hash;

if (defined $config_cmd)
{
    $config_hash = Config::File::read_config_file($config_cmd)
      or die "ERROR: Can't open config. Reason: $!";
}
elsif (-e NRPE_CONF_DIR . "/nrpe.cfg")
{
    $config_hash = Config::File::read_config_file(NRPE_CONF_DIR . "/nrpe.cfg")
      or die "ERROR: Can't open config. Reason: $!";
}

my $include_dir = $config_hash->{include_dir};
if ($include_dir)
{
    opendir(my $dh, $include_dir) || die "Can't opendir $include_dir: $!";
    my @cfgs = grep { /\.cfg$/ && -f "$include_dir/$_" } readdir($dh);
    closedir $dh;
    foreach my $cfg (@cfgs)
    {
        parse_config("$include_dir/$cfg");
    }
}

my $include = $config_hash->{include};
if ($include)
{
    parse_config($include);
}

$commandlist = $config_hash->{command};

$listen = $listen_cmd || $config_hash->{server_address} || "127.0.0.1";
$port   = $port_cmd   || $config_hash->{server_port}    || "5666";
$pid = $pid_cmd || $config_hash->{pid_file} || "/var/run/nagios/nrpe.pid";
$ssl = 1 if defined $ssl_cmd;
$allowed_hosts      = $config_hash->{allowed_hosts}      || "0.0.0.0";
$command_timeout    = $config_hash->{command_timeout}    || "60";
$connection_timeout = $config_hash->{connection_timeout} || 300;
$SSL_cert_file      = $config_hash->{SSL_cert_file}
  || "/etc/ssl/certs/ssl-cert-snakeoil.pem";
$SSL_key_file = $config_hash->{SSL_key_file}
  || "/etc/ssl/private/ssl-cert-snakeoil.key";

die "No Commands to execute given." if (not defined $commandlist);

foreach (keys %$commandlist)
{
    my @args = split /\ /, $commandlist->{$_};
    my $hashref = {};
    $hashref->{bin} = $args[0];
    my $length = scalar @args;
    my $argstr = "";
    for (my $i = 1 ; $i < $length ; $i++)
    {
        $argstr .= " " . $args[$i];
    }

    $hashref->{args} = $argstr;
    $commandlist->{$_} = $hashref;
}
my %dopts = (
    allowed_hosts => $allowed_hosts,
    callback      => sub {
        my ($self, $check, @options) = @_;
        my $commandlist = $self->commandlist();
        if ($commandlist->{$check})
        {
            my $args = $commandlist->{$check}->{args};
            my $i    = 0;
            foreach (@options)
            {
                $i++;
                $args =~ s/\$ARG$i\$/$_/;
            }
            my $result =
              run_forked($commandlist->{$check}->{bin} . " " . $args,
                         {timeout => 20});
            my $stdout = $result->{stdout};
            chomp $stdout;
            return ($result->{exit_code}, $stdout);
        }
        else
        {
            return (STATE_UNKNOWN, sprintf "No such check: '%s'", $check);
        }
    },
    commandlist   => $commandlist,
    listen       => $listen,
    pid_dir      => $pid,
    port         => $port,
    ssl          => $ssl,
);


if (defined($adh_cmd))
{
    $dopts{SSL_cipher_list} = "ADH";
}
else
{
    $dopts{SSL_cert_file} = $SSL_cert_file;
    $dopts{SSL_key_file}  = $SSL_key_file;
}
my $daemon = Nagios::NRPE::Daemon->new(%dopts);

$daemon->start();

sub parse_config
{
    my ($file) = @_;
    my $additional_config_hash = Config::File::read_config_file($file)
      or die "ERROR: Can't open config. Reason: $!";

    my $command_hash = $additional_config_hash->{command};
    if ($command_hash)
    {
        foreach my $key (keys %$command_hash)
        {
            my $value = $additional_config_hash->{command}->{$key};
            $config_hash->{command}->{$key} = $value;
        }
        delete $additional_config_hash->{command};
    }
    $config_hash = {%$config_hash, %$additional_config_hash};
}
