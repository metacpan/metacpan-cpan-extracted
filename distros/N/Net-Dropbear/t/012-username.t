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
my $ok_str    = "IN on_username";
my $nok_str   = "IN on_passwd_fill";

$sshd = Net::Dropbear::SSHd->new(
  addrs          => $port,
  allowblankpass => 1,
  noauthpass     => 0,
  keys           => $key_filename,
  hooks          => {
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
    on_username => sub
    {
      $sshd->comm->printflush("$ok_str\n");
      return shift eq $port ? 1 : -1;
    },
    on_passwd_fill => sub
    {
      $sshd->comm->printflush("$nok_str\n");
      return 0;
    }
  },
);

$sshd->run;

needed_output(
  undef, {
    $start_str => 'Dropbear started',
  }
);

{
  my %ssh = ssh();
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str            => 'Got into the username hook',
      'Exit before auth' => 'SSH quit with a good username',
      "!$nok_str" => 'Did not enter on_passwd_fill',
    }
  );

  kill( $ssh{pid} );
  note("SSH output");
  note($_) while <$pty>;
}

{
  my %ssh = ssh( username => "a$port" );
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str => 'Got into the username hook',
      'Login attempt for nonexistent user' => 'Incorrect username causes failure',
      "!$nok_str" => 'Did not enter on_passwd_fill',
    }
  );

  kill( $ssh{pid} );
  note("SSH output");
  note($_) while <$pty>;
}

$sshd->stop;
$sshd->wait;

done_testing($planned);
