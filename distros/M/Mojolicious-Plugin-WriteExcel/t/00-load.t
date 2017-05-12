#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Mojolicious::Plugin::WriteExcel') || print "Bail out!
";
}

diag(
  "Testing Mojolicious::Plugin::WriteExcel $Mojolicious::Plugin::WriteExcel::VERSION, Perl $], $^X"
);
