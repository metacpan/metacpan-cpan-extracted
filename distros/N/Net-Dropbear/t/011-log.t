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

my $start_str = 'Dropbear started';

$sshd = Net::Dropbear::SSHd->new(
  addrs          => $port,
  noauthpass     => 0,
  keys           => $key_filename,
  hooks          => {
    on_start => sub
    {
      $sshd->comm->printflush("$start_str\n");
      return 1;
    },
    on_log => sub
    {
      shift;
      $sshd->comm->printflush(shift . "\n");
      return 1;
    },
  },
);

$sshd->run;

needed_output(
  undef, {
    $start_str => 'Saw the startup of Dropbear',
  }
);

{
  my %ssh = ssh();
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      'Login attempt for nonexistent user' => 'Got output from logging',
    }
  );

  kill( $ssh{pid} );
}

$sshd->stop;
$sshd->wait;

done_testing($planned);
