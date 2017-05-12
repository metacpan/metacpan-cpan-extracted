#!/usr/bin/perl -w

use Danga::Socket;
use ParaDNS;
use NetAddr::IP;
use Time::HiRes qw(time);

use strict;
use warnings;

# control concurrency
use constant LOW_WATER_MARK  => 100;
use constant HIGH_WATER_MARK => 10_000;

sub Usage {
    print STDERR <<EOT;
usage: $0 [-q] [-t <secs>] [-f <N>] Network/Prefix
        network/prefix example: 192.168.0.0/24 will scan 192.168.0.0 - 192.168.0.255
        -q : do not print errors like SERVFAIL or TIMEOUT
        -f <N> : will look up every Nth \(default:1\) IP, only
EOT
}

sub main {
    use Getopt::Long qw(GetOptions);
    
    my $quiet   = 0;
    my $skip    = 1;
    my $verbose = 0;
    my $timeout_block = 0;
    
    GetOptions(
        "q|quiet+" => \$quiet,
        "t|timeout=i" => \$timeout_block,
        "f|skip=i" => \$skip,
        "h|help" => \&Usage,
        "v|verbose" => \$verbose,
        );
        
    return Usage() unless @ARGV;

    if ($timeout_block) {
        $ParaDNS::TIMEOUT = $timeout_block;
    }
    
    my $start = time;
    my @start = times;
    
    print STDERR "Expanding IP ranges...\n" if $verbose;
    my @IPs = map { expand_block($_) } @ARGV;
    print STDERR "Done.\n" if $verbose;
    
    Danga::Socket->AddTimer(0, sub { pump(\@IPs, $quiet, $skip, $verbose) });

    Danga::Socket->SetPostLoopCallback(
        sub {
            my $dmap = shift;
            for my $fd (keys %$dmap) {
                my $pob = $dmap->{$fd};
                if ($pob->isa('ParaDNS::Resolver')) {
                    return 1 if $pob->pending;
                }
            }
            if (ParaDNS::XS_AVAILABLE) {
                return 1 if ParaDNS::XS::num_queries();
            }
            return 1 if @IPs;
            return 0;
        });
            
    Danga::Socket->EventLoop;
    
    my $end = time;
    my @end = times;
    
    printf("# Took %0.2f / %0.2f / %0.2f seconds (Real/User/Sys) to scan %s with stepsize %d\n",
            ($end - $start), ($end[0] - $start[0]), ($end[1] - $start[1]),
            join(', ', @ARGV), $skip) if $verbose;

    return 0;
}

exit(main());

##############

sub output_host {
    my ($quiet, $result, $host, $ttl) = @_;
    
    if ($result =~ /^[A-Z]*$/) {
        print "$host  (ERROR:$result)\n" unless $quiet;
    }
    else {
        print "$host  $result ($ttl)\n";
    }
}

sub expand_block {
    my $block = shift;
    
    my ($network, $prefix) = split ('/', $block, 2);
    
    if ($prefix < 9) {
        die "Won't scan a /8 or less.";
    }
    
    my $net = NetAddr::IP->new($block);
    return map { s/\/32$//; $_ } @$net;
}

sub pump {
    my ($IPs, $quiet, $skip, $verbose) = @_;
    
    my $pending = 0;
    my $descriptors = Danga::Socket->DescriptorMap;
    for my $fd (keys %$descriptors) {
        my $pob = $descriptors->{$fd};
        if ($pob->isa("ParaDNS::Resolver")) {
            $pending = $pob->pending;
        }
    }
    
    print STDERR "pumping more IPs\n" if $verbose;
    while (@$IPs && $pending++ <= HIGH_WATER_MARK) {
        my $ip = shift @$IPs;
        ParaDNS->new(
            callback => sub { output_host($quiet, @_) },
            host     => $ip,
        );
    }

    Danga::Socket->AddTimer(1, sub { pump($IPs, $quiet, $skip, $verbose) });
}
