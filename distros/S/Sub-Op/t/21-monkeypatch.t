#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
 if (exists $INC{'B.pm'} or exists $INC{'B/Deparse.pm'}) {
  plan skip_all => 'Test::More loaded B or B::Deparse for some reason';
 } else {
  plan tests => 5;
 }
}

use Sub::Op;

sub stash_keys {
 my ($pkg) = @_;

 no strict 'refs';
 keys %{"${pkg}::"};
}

BEGIN {
 is_deeply [ sort +stash_keys 'B' ], [ sort
  qw/OP:: Deparse:: Hooks::/,
  qw/svref_2object/,
 ], 'No extra symbols in B::';
 is_deeply [ sort +stash_keys 'B::Deparse' ], [ ], 'No symbols in B::Deparse';
}

use B;

BEGIN {
 for my $meth (qw/first can/) {
  ok do { no strict 'refs'; defined &{"B::OP::$meth"} },
                                      "B::OP::$meth is now defined";
 }
}

use B::Deparse;

BEGIN {
 for my $meth (qw/pp_custom/) {
  ok do { no strict 'refs'; defined &{"B::Deparse::$meth"} },
                                      "B::Deparse::$meth is now defined";
 }
}
