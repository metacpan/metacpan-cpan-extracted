#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my %connection_details = ( host => 'localhost', @ARGV);
my $ssh = ssh_connection(%connection_details);
print "ssh: ", Dumper($ssh), "\n";
exit (0);

BEGIN {
    eval {
        require Net::SSH2;
        warn "Net::SSH2 loaded";
        1;
    } or eval {
        require Net::OpenSSH::Compat::SSH2;
        Net::OpenSSH::Compat::SSH2->import(':supplant');
        warn "Net::SSH2 supplanted";
        1;
    } or die "unable to load any SSH module: $@";
    Net::SSH2->import();
}


sub ssh_connection {
    my (%connection_info) = @_;

    ## Connect to the ssh server
    my $ssh = Net::SSH2->new();

    $ssh->connect($connection_info{'host'},22)
        or die "Unable to connect to the remote ssh server \n\n $@";

    ## Login to ssh server
    $ssh->auth_password($connection_info{'user'},$connection_info{'pass'})
        or die "Unable to login Check username and password. \n\n $@\n";

    return $ssh;
}
