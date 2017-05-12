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

my $start_str = "ON_START";
my $ok_str    = "IN on_new_channel";
my $passwd    = 'asdf';

$sshd = Net::Dropbear::SSHd->new(
  addrs      => $port,
  noauthpass => 0,
  keys       => $key_filename,
  hooks      => {
    on_log => sub
    {
      shift;
      $sshd->comm->printflush( shift . "\n" );
      return 1;
    },
    on_start => sub
    {
      $sshd->comm->printflush("$start_str\n");
      return 1;
    },
    on_passwd_fill => sub
    {
      return 1;
    },
    on_shadow_fill => sub
    {
      $_[0] = crypt( $passwd, 'aa' );
      return 1;
    },
    on_new_channel => sub
    {
      $sshd->comm->printflush("$ok_str\n");
      $sshd->comm->printflush("New channel: " . shift . "\n");
      return -1;
    },
  },
);

$sshd->run;

needed_output(
  undef, {
    $start_str => 'Dropbear started',
  }
);

{
  my %ssh = ssh( password => $passwd );
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str => 'Got into the new channel hook',
      'New channel: session' => 'Can request a new channel',
    },
    $pty, {
      'channel 0: open failed: administratively prohibited:' => 'Can deny a new channel',
    }
  );

  kill( $ssh{pid} );
}

$sshd->stop;
$sshd->wait;

done_testing($planned);
