use strict;
use warnings;

use Test::More tests => 4;

use Moose::Autobox ();

foreach my $stem (qw(SCALAR ARRAY HASH CODE)) {
  my $class = "Moose::Autobox::${stem}";
  ok(!$class->isa('Moose::Object'), "${class} !isa Moose::Object");
}
