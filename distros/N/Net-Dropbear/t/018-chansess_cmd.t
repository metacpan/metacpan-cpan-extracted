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
my $ok_str    = "IN on_chansess_command";
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
    on_chansess_command => sub
    {
      $sshd->comm->printflush("$ok_str\n");
      my $csa = shift;
      my $cmd = $csa->cmd;
      if ($cmd =~ m/^~/)
      {
        $cmd =~ s/^~//;
        $csa->cmd($cmd);
      }

      undef $cmd;

      $sshd->comm->printflush("cmd: " . $csa->cmd . "\n");
      if ($csa->cmd eq 'false')
      {
        return 0;
      }
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
      $ok_str => 'Got into the channel command hook',
      'cmd: false' => 'Ran the command false',
    }
  );

  kill( $ssh{pid} );
}

{
  my %ssh = ssh( password => $passwd, cmd => '~false');
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str => 'Got into the channel command hook',
      'cmd: false' => 'Can override the command',
      '!sh: 1: ~false: not found' => 'The bad command never runs',
    }
  );

  kill( $ssh{pid} );
}

{
  my $cmd = 'echo asdf';
  my %ssh = ssh( password => $passwd, cmd => $cmd);
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str => 'Got into the channel command hook',
      "cmd: $cmd" => "Cmd is seen as '$cmd'",
    },
    $pty, {
      'exec request failed' => 'The disallowed command does not run',
      '!asdf' => 'The disallowed command does not produce output',
    }
  );

  kill( $ssh{pid} );
}

$sshd->stop;
$sshd->wait;

done_testing($planned);
