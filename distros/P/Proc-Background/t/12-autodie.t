use strict;
use Test;
BEGIN { plan tests => 7; }
use FindBin;
use Cwd qw( abs_path getcwd );
use Proc::Background;

=head1 DESCRIPTION

This tests the option 'cwd' that runs the child in a different directory.

=cut

sub new_and_catch {
  my @args= @_;
  local $@;
  my ($proc, $err);
  unless (eval {
    $proc= Proc::Background->new(@args);
    1;
  }) { $err= $@; }
  #use DDP; &p([$proc, $err, $@]);
  return ($proc, $err);
}

my ($proc, $err)= new_and_catch('command_that_does_not_exist', '');
ok( $proc, undef );  # 1
ok( $err, undef );   # 2

($proc, $err)= new_and_catch({ autodie => 1 }, 'command_that_does_not_exist', '');
$proc->wait if defined $proc;
ok( $err ); # 3

($proc, $err)= new_and_catch({ cwd => 'path_that_does_not_exist' }, $^X, '-v' );
ok( $proc, undef ); # 4
$proc->wait if defined $proc;
ok( $err, undef ); # 5

($proc, $err)= new_and_catch({ autodie => 1, cwd => 'path_that_does_not_exist' }, $^X, '-v' );
ok( $proc, undef ); # 6
$proc->wait if defined $proc;
ok( $err ); # 7
