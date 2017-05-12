#!/perl

use strict;

my %test_arg;
BEGIN {
  %test_arg = ( tests => 2 );
  eval { require Term::Size };
  if($@) {
    %test_arg = (skip_all => 'Term::Size is required for testing Term::Completion qw(:POSIX)');
  }
}
use Test::More %test_arg;

SKIP: {
  eval "use Term::Completion qw(:stty)";

  skip 'no stty executable available', 1 if($@ && $@ =~ /no stty executable found in/);
  ok(!$@, "Term::Completion qw(:stty) loaded OK");

  my $tc = Term::Completion->new();
  ok(eval { $tc->set_raw_tty; $tc->reset_tty; 1; } && !$@, "stty tty methods work OK");
}

