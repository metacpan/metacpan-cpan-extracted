#!/usr/bin/perl

use strict;

my %test_arg;
BEGIN {
  %test_arg = ( tests => 7 );
  eval { require Term::Size; };
  if($@) {
    %test_arg = (skip_all => 'Term::Size is required for testing Term::Completion');
  }
  unless(-t STDIN && -t STDOUT) {
    %test_arg = (skip_all => 'This test works only in interactive mode');
  }
}
use Test::More %test_arg;

use_ok('Term::Completion');

my $winch = 0;
my $get_tc;
my $winch_sig = $SIG{WINCH} = sub {
  ok(1, "In ".__FILE__.' '.__LINE__." WINCH signal processed.\r\n");
  my ($c, $r) = Term::Size::chars(\*STDOUT);
  my ($c2, $r2) = &$get_tc();
  is($c2, $c, "new columns updated correctly in Term::Completion\r\n");
  is($r2, $r, "new rows updated correctly in Term::Completion\r\n");
  $winch++;
};
diag("Installed WINCH signal: ".$SIG{WINCH}."\n");

my $tc = Term::Completion->new(
  prompt => 'please resize window, then press ENTER: ',
  choices => [qw(one two three four)] );
$get_tc = sub {
  return($tc->get_term_size());
};

local $\ = "\r\n";
$tc->complete();

my $winch_sig = $SIG{WINCH} = sub {
  ok(1, "In ".__FILE__.' '.__LINE__." WINCH signal processed.\r\n");
  $winch++;
};
diag("Installed new WINCH signal: ".$SIG{WINCH}."\n");

$tc = $tc->new(
    columns => 20,
    rows => 3,
    prompt => 'Press CTRL-D, SPACE, resize window, ENTER, Q, ENTER: ',
    choices => [qw(one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty)] );
$get_tc = sub {
  return($tc->get_term_size());
};
$tc->complete();

ok($winch==2, "Terminal size changed twice");
undef $get_tc;
undef $tc;

is($SIG{WINCH}, $winch_sig, "WINCH signal handler correctly restored");

exit 0;

