#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('MojoX::Renderer::WriteExcel') || print "Bail out!
";
}

diag(
  "Testing MojoX::Renderer::WriteExcel $MojoX::Renderer::WriteExcel::VERSION, Perl $], $^X"
);
