#!/perl

use strict;

my %test_arg;
BEGIN {
  %test_arg = ( tests => 4 );
  eval { require POSIX; require Term::Size; };
  if($@) {
    %test_arg = (skip_all => 'POSIX and Term::Size are required for testing Term::Completion qw(:POSIX)');
  }
  elsif($^O =~ /\bwin/i && $^O !~ /cygwin/i) {
    %test_arg = (skip_all => 'This test does not work on native Windows');
  }
}
use Test::More %test_arg;

eval "use Term::Completion qw(:foobarxyz);";
like($@||'',qr/Term::Completion does not export ':foobarxyz'/, "import recognizes wrong tags");

BEGIN { use_ok('Term::Completion' => qw(:posix)) };

my $tc = Term::Completion->new();

ok(eval { $tc->set_raw_tty; $tc->reset_tty; 1; } && !$@, "POSIX tty methods work OK");

ok(eval { $tc->get_term_size; 1; } && !$@, "POSIX get terminal size method works OK");

