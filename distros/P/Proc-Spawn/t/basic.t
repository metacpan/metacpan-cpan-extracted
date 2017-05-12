# -*- mode: perl -*-

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Proc::Spawn;
$loaded = 1;
print "ok 1\n";

# Test counter
my $i = 2;

# Test values
my $Cmd    = "/bin/cat";
my $ErrCmd = "/bin/cat 1>&2";
my $Data   = "testing testing testing\r\n";

# Pipes
eval {
  my ($pid, $in_fh, $out_fh, $err_fh) = spawn($Cmd);
  $in_fh->print($Data);
  $in_fh->flush;
  my $out = <$out_fh>;
  die "Invalid output" unless ( $out and $out eq $Data );
};
print ($@ ? "not ok $i" : "ok $i\n"); $i++;

eval {
  my ($pid, $in_fh, $out_fh, $err_fh) = spawn($ErrCmd);
  $in_fh->print($Data);
  $in_fh->flush;
  my $err = <$err_fh>;
  die "Invalid output" unless ( $err and $err eq $Data );
};
print ($@ ? "not ok $i" : "ok $i\n"); $i++;

# Pty
eval {
  my ($pid, $pty_fh) = spawn_pty($Cmd);
  $pty_fh->print($Data);
  $pty_fh->flush;
  my $out = <$pty_fh>;
  die "Invalid output" unless ( $out and $out eq $Data );
};
print ($@ ? "not ok $i and $@ ($$)" : "ok $i\n"); $i++;

eval {
  my ($pid, $pty_fh) = spawn_pty($Cmd);
  $pty_fh->print($Data);
  $pty_fh->flush;
  my $err = <$pty_fh>;
  die "Invalid output" unless ( $err and $err eq $Data );
};
print ($@ ? "not ok $i ($$)" : "ok $i\n"); $i++;
