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

# Didn't test pw_uid or pw_gid because those are cast to int's
my @auth_fields = qw/pw_dir pw_shell pw_name pw_passwd/;
my $teststr = '/tmp';

package asdf;
  use Moo;
  foreach my $field (@auth_fields)
  {
    has $field => ( is => 'ro', default => "$field:$teststr" );
  }
package main;

my $self = asdf->new();
use Data::Dumper;

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
      my ( $auth_state, $username ) = @_;

      $sshd->comm->printflush("$ok_str\n");

      foreach my $field (@auth_fields)
      {
        $auth_state->$field($self->$field);
        $sshd->comm->print("self-$field: " . $self->$field() . "\n");
        $sshd->comm->print("auth-$field: " . $auth_state->$field() . "\n");
      }

      $sshd->comm->printflush();

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

  my %tests;
      foreach my $field (@auth_fields)
      {
        my $str = "-$field: " . $self->$field();
        $tests{"self$str"} = "Does not corrupt $field in self";
        $tests{"auth$str"} = "Does not corrupt $field in auth_state";
      }

  needed_output(
    undef, {
      %tests,
      $ok_str         => 'Got into the passwd hook',
    }
  );

  kill( $ssh{pid} );
}

$sshd->stop;
$sshd->wait;

done_testing($planned);

