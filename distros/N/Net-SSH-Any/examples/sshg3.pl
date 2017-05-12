#!/usr/bin/perl

use strict;
use warnings;

use Net::SSH::Any;

my $uri = shift;

my $ssh = Net::SSH::Any->new($uri, backend => 'Sshg3_Cmd');
$ssh->die_on_error('unable to connect to $uri');
my $sftp = $ssh->sftp;
$ssh->die_on_error('unable to create SFTP connection');

my @out = $ssh->capture('ls -a ~/');
my $ls = $sftp->ls('.', names_only => 1);

printf "exec ls count: %d, sftp ls count: %d\n", scalar(@out), scalar(@$ls);
