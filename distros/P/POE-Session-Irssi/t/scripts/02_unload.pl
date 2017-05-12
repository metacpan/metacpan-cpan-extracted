use lib 'blib/lib';
local $/;
warn "\nfoo\n";
use Test::More;
#eval "use Test::More tests => 1;";
Test::More::plan tests => 5;
#close STDOUT;

use strict;
use Glib;
use POE qw/Loop::Glib/;
Test::More::use_ok('POE::Session::Irssi');

my $s = POE::Session::Irssi->create(
  irssi_commands => {
    "foo" => sub { warn "\n"; Test::More::ok(1, "BEEP"); },
  },
  inline_states => {
    _start => sub {
      Test::More::ok(1, 'loaded');
    },
    _stop => sub {
      Test::More::ok(1, 'unloaded');
      warn "\n";
    },
  },
);

isa_ok($s, 'POE::Session::Irssi');
