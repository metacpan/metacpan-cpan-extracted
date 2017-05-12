#!/usr/bin/perl -w
use Net::FTP;
use Parallel::ForkManager;
use strict;

# code by delirium @ www.perlmonks.org

my %srvs = ();
my $num_forks = 10;
my $timeout = 30;

my $pm = new Parallel::ForkManager($num_forks);
$pm->run_on_start( sub { print STDERR "Connecting to $_[1], port $srvs{$_[1]}{port}\n"; } );

$pm->run_on_finish
( sub {
    my (undef, $exit_code, $ident) = @_;
    if    ( $exit_code == 0 ) { $srvs{$ident}{stat} = "Good logon to $ident\n"; }
    elsif ( $exit_code == 1 ) { $srvs{$ident}{stat} = "*** Logon to $ident failed\n"; }
    elsif ( $exit_code == 2 ) { $srvs{$ident}{stat} = "*** Connect to $ident failed\n"; }
    else { $srvs{$ident}{stat} = " Script error while connecting to $ident\n"; }
    print STDERR $srvs{$ident}{stat};
}  );

sub ftpcheck {
    my $id = shift;
    my $srv=$srvs{$id};
    my $status = 1;
    my $ftp=Net::FTP->new($$srv{addr}, Timeout=>$timeout, Port=>$$srv{port});
    exit(2) if ! $ftp;
    $status = 0 if $ftp->login($$srv{user},$$srv{pass});
    $ftp->quit();  # Be nice to the server and send QUIT whether or not login worked
    exit ($status);
}

while (<>)  {
    chomp;
    next unless $_;
    my @F = split /,/,$_,4;
    next unless $#F == 3;
    if ( $F[1] =~ /([^:]+):([^:]+)/ )   {
        $srvs{$F[0]}{addr} = $1;
        $srvs{$F[0]}{port} = $2;
    }
    else    {
        $srvs{$F[0]}{addr} = $F[1];
        $srvs{$F[0]}{port} = 21;
    }
    $srvs{$F[0]}{user} = $F[2];
    $srvs{$F[0]}{pass} = $F[3];
    $srvs{$F[0]}{stat} = '*** Unknown';
}

for my $key ( keys %srvs ) {
    my $pid = $pm->start($key) and next;
    &ftpcheck($key);
    $pm->finish($key);
}

$pm->wait_all_children;
print $srvs{$_}{stat} for sort keys %srvs;
