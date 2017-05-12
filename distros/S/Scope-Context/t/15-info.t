#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 2 + 3 + 2;

use Scope::Context;

{
 package Scope::Context::TestA;
 {
  my $line = __LINE__;
  package Scope::Context::TestB;
  my $cxt  = Scope::Context->new;
  package Scope::Context::TestC;
  ::is $cxt->package,   'Scope::Context::TestA';
  ::is $cxt->file,      __FILE__;
  ::is $cxt->line,      $line;
  ::is $cxt->sub_name,  undef;
  ::is $cxt->eval_text, undef;
 }
}

sub flurbz {
 my $cxt = Scope::Context->new;
 [ $cxt->sub_name, $cxt->sub_has_args ]
}

{
 my $info = flurbz();
 is($info->[0], 'main::flurbz');
 is($info->[1], !!1);
}

{
 {
  is(Scope::Context->new->gimme, undef, 'gimme in void context');
 }
 my $s = do {
  is(Scope::Context->new->gimme, !!'', 'gimme in scalar context');
 };
 my @a = do {
  is(Scope::Context->new->gimme, !!1, 'gimme in list context');
 }
}

{
 my $src  = <<' SRC';
  my $cxt = Scope::Context->new;
  [ $cxt->eval_text, $cxt->is_require ];
 SRC
 my $info = do {
  local $@;
  eval $src;
 };
 my $eval_text = $info->[0];
 s/[\s;]*$//g for $eval_text, $src;
 is $eval_text, $src, 'eval_text in eval';
 is $info->[1], !!'', 'is_require in eval';
}
