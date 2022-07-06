use strict;
use Test::More;
use File::Temp ();

use Net::Dropbear::SSHd;
use Net::Dropbear::XS;
use IPC::Open3;
use IO::Pty;
use Try::Tiny;

use FindBin;
require "$FindBin::Bin/Helper.pm";

our $port;
our $key_fh;
our $key_filename;
our $sshd;
our $planned;

use POSIX qw/WNOHANG/;

my $sshd = Net::Dropbear::SSHd->new(
  addrs          => $port,
  noauthpass     => 0,
  keys           => $key_filename,
);

$sshd->run;

$planned++;
cmp_ok( waitpid( $sshd->child->pid, WNOHANG ), '>=', 0, 'SSHd started' );

# Give SSHd some time to come up, incase the stop signal is ineffective
sleep 0.1;
$sshd->stop;
$sshd->wait;

$planned++;
cmp_ok( waitpid( $sshd->child->pid, WNOHANG ), '<', 0, 'SSHd stopped' );

done_testing($planned);
