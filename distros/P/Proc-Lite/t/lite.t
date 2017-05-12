#!perl -T

use strict;
use warnings;

use Test::More;
use Proc::Lite;


eval { Proc::Lite->new( fake => ) };
like( $@, qr/^Odd number of parameters/, 'odd parameters' );

eval { Proc::Lite->new( fake => 'fake' ) };
like( $@, qr/^command: Required parameter/, 'odd parameters' );

{
  my $proc = Proc::Lite->new( command => \&command )->run;
  ok( $proc->status == 0, 'new->run: status' );
  ok( $proc->success, 'new->run: success' );
}

{
  my $proc = Proc::Lite->exec( \&command, stdout => 'STDOUT', stderr => 'STDERR' );
  is(   $proc->stdout->[0], 'STDOUT', 'exec: stdout: scalar' );
  is(   $proc->stderr->[0], 'STDERR', 'exec: stderr: scalar' );
  is( ( $proc->stdout )[0], 'STDOUT', 'exec: stdout: list: ' );
  is( ( $proc->stderr )[0], 'STDERR', 'exec: stderr: list' );
}

{
  my $info;

  my $proc = Proc::Lite->new(
    parent  => sub { $info = $$. ':'. $_[0] },
    child   => sub { $info = $_[0]. ':'. $$ },
    command => sub { print $info },
  )->run;

  is( $proc->stdout->[0], $info, 'parent/child callbacks' );
}

{
  my $proc = Proc::Lite->new(
    priority => 1,
    command  => sub { },
  )->run;

  ok( $proc->status == 0, 'priority' );
}

done_testing;


sub command {
  my %args = @_;

  print STDOUT $args{stdout}, "\n"
    if defined $args{stdout};

  print STDERR $args{stderr}, "\n"
    if defined $args{stderr};
}
