use strict;
use Test::More;
use File::Temp ();

use Net::Dropbear::SSHd;
use Net::Dropbear::XS;
use IPC::Open3;
use IO::Pty;
use Try::Tiny;

if ( $> == 0 ) { plan skip_all => 'Test in ineffective as root' }

use FindBin;
require "$FindBin::Bin/Helper.pm";

our $port;
our $key_fh;
our $key_filename;
our $sshd;
our $planned;

my $start_str = 'Dropbear started';

$sshd = Net::Dropbear::SSHd->new(
  addrs      => $port,
  noauthpass => 0,
  keys       => $key_filename,
  hooks      => {
    on_start => sub
    {
      $sshd->comm->printflush("$start_str\n");
      return 1;
    },
    on_log => sub
    {
      shift;

      $sshd->comm->printflush( shift . "\n" );
      return 1;
    },
  },
);

$sshd->run;

needed_output(
  undef,
  {
    $start_str => 'Saw the startup of Dropbear',
    '!Failed loading /etc/dropbear/dropbear_rsa_host_key' =>
        'Did not attempt to include default rsa host key',
    '!Failed loading /etc/dropbear/dropbear_dss_host_key' =>
        'Did not attempt to include default dsa host key',
    '!Failed loading /etc/dropbear/dropbear_ecdsa_host_key' =>
        'Did not attempt to include default ecdsa host key',
    q/!Failed listening on '22': Error listening: Permission denied/ =>
        'Did not attempt to bind to port 22',
  }
);

$sshd->stop;
$sshd->wait;

done_testing($planned);
