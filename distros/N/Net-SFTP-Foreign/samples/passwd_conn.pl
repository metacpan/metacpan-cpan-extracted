#!/usr/bin/perl

# This sample is obsolete and should not be used as a reference.
#
# Current versions of Net::SFTP::Foreign support password
# authentication as long as the IO::Pty module is installed:
#
#     my $sftp = Net::SFTP::Foreign->new($host,
#                                        user => "me",
#                                        passwd => "quite-secret-passwd");
#     $sftp->error and die "unable to connect ro $host";
#

use strict;
use warnings;

use Expect;
use Net::SFTP::Foreign;

$| = 1;

my $errstr = "unable to stablish SSH connection with remote host";
my $timeout = 60;

@ARGV >= 3 or die <<USAGE;
Usage:

    $0 host user password dir

USAGE

my $host = shift;
my $user = shift;
my $passwd = shift;
my @dir = @ARGV ? @ARGV : ('/');

# initialize an Expect object:
my $conn = Expect->new;
$conn->raw_pty(1);
$conn->log_user(0);

# spawn a new SSH process:
$conn->spawn('/usr/bin/ssh', -l => $user, $host, -s => 'sftp')
    or die $errstr;

# wait for the password prompt:
$conn->expect($timeout, "Password:")
    or die "Password not requested as expected";

$conn->send("$passwd\n");

# SSH echoes the "\n" after the password, remove it from the stream:
$conn->expect($timeout, "\n");

# and finally run SFTP over the ssh connection:
my $sftp = Net::SFTP::Foreign->new(transport => $conn);
$sftp->error and die "$errstr: " . $sftp->error;

# and do whatever you want with it...
for my $dir (@dir) {
    my $ls = $sftp->ls($dir);
    if ($ls) {
        print "$dir\n";
        print "  - $_->{filename}\n" for @$ls;
        print "\n";
    }
    else {
        print STDERR "Unable to retrieve directory listing for '$dir': " . $sftp->error . "\n"
    }
}


