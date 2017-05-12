#!/usr/bin/perl -wT
use strict;
use warnings;

use Proc::Safetynet;
use Proc::Safetynet::RpcServer::Unix;
use Proc::Safetynet::Program::Storage::TextFile;

use Fcntl ':flock';
use Config::General;
use Data::Dumper;

my $usage = <<EOF;
Usage: $0 <path/to/config_file>
EOF

my $lockfh;
my $config;
{
    # validate config file
    my $config_file = shift @ARGV || '';
    (-e $config_file)
        or die $usage;
    # lock config file or die
    open $lockfh, $config_file
        or die "unable to open config file: $config_file: $!";
    flock($lockfh, LOCK_EX|LOCK_NB)
        or exit(2); # unable to lock
    my $rc = Config::General->new( $config_file );
    $config = { $rc->getall() };
}

my $programs;
{
    # validate programs storage
    my $programs_storagefile = $config->{programs} || '';
    eval {
        $programs = Proc::Safetynet::Program::Storage::TextFile->new(
            file        => $programs_storagefile,
        );
        $programs->reload;
    };
    if ($@) {
        die $@;
    }
}

# ---------

my $supervisor = Proc::Safetynet::Supervisor->spawn(
    alias           => q{SUPERVISOR},
    binpath         => $config->{binpath},
    programs        => $programs,
    stderr_logpath  => $config->{stderr_logpath},
    stderr_logext   => $config->{stderr_logext},
);
if (exists $config->{unix_server}) {
    Proc::Safetynet::RpcServer::Unix->spawn(
        alias           => q{UNIXSERVER},
        supervisor      => $supervisor->alias,
        session_class   => 'Proc::Safetynet::RpcSession::Simple',
        socket          => $config->{unix_server}->{socket},
    );
}

POE::Kernel->run();

__END__
