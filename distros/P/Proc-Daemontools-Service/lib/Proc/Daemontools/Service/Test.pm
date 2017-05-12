package Proc::Daemontools::Service::Test;

=head1 NAME

Proc::Daemontools::Service::Test

=head1 DESCRIPTION

This is a simple service for testing.

You probably don't want to use it.

=cut

use strict;
use warnings;
use base qw(Proc::Daemontools::Service);

=head1 METHODS

=head2 C<< svc_run >>

=head2 C<< svc_hangup >>

=head2 C<< svc_exit >>

=cut

sub svc_run {
  sleep 1 while 1;
}

sub _write {
  my $str = shift;
  my $fh;
  open $fh, ">test.out" or die "Can't open test.out: $!";
  print $fh $str;
  close $fh;
}

sub _read {
  my $fh;
  open $fh, "<test.out" or die "Can't open test.out: $!";
  my $line = <$fh>;
  close $fh;
  return $line;
}

sub svc_hangup {
  _write("hangup");
}

sub svc_exit {
  _write("exit");
}

1;
