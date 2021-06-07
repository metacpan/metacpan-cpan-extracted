use strict;
use Test::More;
use File::Temp ();

use Net::Dropbear::SSHd;
use Net::Dropbear::XS;
use IPC::Open3;
use Try::Tiny;

use FindBin;
require "$FindBin::Bin/Helper.pm";

our $port;
our $key_fh;
our $key_filename;
our $sshd;
our $planned;

my $start_str      = "ON_START";
my $ok_str         = "IN on_passwd_fill";
my $not_forced_str = "Not forcing username";
my $forced_str     = "Forcing username";

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
      my $auth_state = shift;
      my $username   = shift;
      $sshd->comm->printflush("$ok_str\n");
      if ( $username ne $port )
      {
        $sshd->comm->printflush("$forced_str\n");
        $auth_state->pw_name($port);
      }
      else
      {
        $sshd->comm->printflush("$not_forced_str\n");
      }

      if ( $username eq 'shell' )
      {
        note('Setting the shell to something invalid');
        $auth_state->pw_shell('/');
      }

      return 1;
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
  my %ssh = ssh();
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str         => 'Got into the passwd hook',
      $not_forced_str => 'Did not force username',
      'Exit before auth from <' => 'SSH quit before auth',
      "/(user '$port', 0 fails)" => 'SSH quit with a good username',
    }
  );

  kill( $ssh{pid} );
}

{
  my %ssh = ssh(username => "a$port");
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str     => 'Got into the passwd hook',
      $forced_str => 'Did force username',
      'Exit before auth from <' => 'SSH quit before auth',
      "/(user '$port', 0 fails)" => 'SSH quit with an overridden bad username',
    }
  );

  kill( $ssh{pid} );
}

{
  my %ssh = ssh(username => 'shell');
  my $pty = $ssh{pty};

  needed_output(
    undef, {
      $ok_str     => 'Got into the passwd hook',
      $forced_str => 'Did force username',
      "User '$port' has invalid shell, rejected" =>
          'SSH errored on a bad shell',
    }
  );

  kill( $ssh{pid} );
}

$sshd->stop;
$sshd->wait;

done_testing($planned);
