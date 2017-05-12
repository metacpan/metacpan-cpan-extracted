#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;
use Test::Exception;

{
  package FooTest;
  use Mouse;
  use MouseX::Types::Common::String (
    qw(SimpleStr NonEmptySimpleStr Password StrongPassword NonEmptyStr),
  );

  has simplestr => ( is => 'rw', isa => SimpleStr);
  has nestr => ( is => 'rw', isa => NonEmptyStr);
  has nesimplestr => ( is => 'rw', isa => NonEmptySimpleStr);
  has password => ( is => 'rw', isa => Password);
  has strongpassword => ( is => 'rw', isa => StrongPassword);
}

my $ins = FooTest->new;

lives_ok { $ins->simplestr('') } 'SimpleStr';
lives_ok { $ins->simplestr('good string') } 'SimpleStr 2';
dies_ok { $ins->simplestr("bad\nstring") } 'SimpleStr 3';
dies_ok { $ins->simplestr(join('', ("long string" x 25))) } 'SimpleStr 4';

dies_ok { $ins->nestr('') } 'NonEmptyStr';
lives_ok { $ins->nestr('good string') } 'NonEmptyStr 2';
lives_ok { $ins->nestr("bad\nstring") } 'NonEmptyStr 3';
lives_ok { $ins->nestr(join('', ("long string" x 25))) } 'NonEmptyStr 4';

lives_ok { $ins->nesimplestr('good str') } 'NonEmptySimplrStr ';
dies_ok { $ins->nesimplestr('') } 'NonEmptyStr 2';

dies_ok { $ins->password('no') } 'Password';
lives_ok { $ins->password('okay') } 'Password 2';

dies_ok { $ins->strongpassword('notokay') } 'StrongPassword';
lives_ok { $ins->strongpassword('83773r_ch01c3') } 'StrongPassword 2';
