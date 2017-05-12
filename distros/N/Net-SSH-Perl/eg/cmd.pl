#!/usr/bin/perl -w
# $Id: cmd.pl,v 1.4 2001/02/22 00:14:48 btrott Exp $

use strict;

use Net::SSH::Perl;
use Net::SSH::Perl::Cipher;

chomp(my $this_host = `hostname`);
print "Enter a host name to connect to: [$this_host] ";
chomp(my $host = <STDIN>);
print "\n";

print "Enter the port number of the remote sshd: [ssh] ";
chomp(my $port = <STDIN>);
print "\n";

print "Choose a cipher from the list:\n";
my $supp = Net::SSH::Perl::Cipher::supported();
for my $ciph (sort @$supp) {
    printf "    [%d] %s\n", $ciph, Net::SSH::Perl::Cipher::name($ciph);
}
printf "Enter a number: [%d] ", Net::SSH::Perl::Cipher::id('IDEA');
chomp(my $c = <STDIN>);
print "\n";
my $ssh = Net::SSH::Perl->new($host || $this_host,
    port => $port || 'ssh',
    cipher => Net::SSH::Perl::Cipher::name($c),
    debug => 1);

my $this_user = $ENV{USERNAME} || scalar getpwuid($<);
print "Enter your username on that host: [$this_user] ";
chomp(my $user = <STDIN>);

use Term::ReadKey;

print "And your password: ";
ReadMode('noecho');
chomp(my $pass = ReadLine(0));
ReadMode('restore');
print "\n";

$ssh->login($user || $this_user, $pass);

print "Enter a command to execute: [ls -l] ";
chomp(my $cmd = <STDIN>);

my($out, $err) = $ssh->cmd($cmd || "ls -l");
print $out;
