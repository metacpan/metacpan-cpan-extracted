package Sub::Op::LexicalSub;

use strict;
use warnings;

our ($VERSION, @ISA);

use Sub::Op;

BEGIN {
 $VERSION = '0.02';
 require DynaLoader;
 push @ISA, 'DynaLoader';
 __PACKAGE__->bootstrap($VERSION);
}

sub import {
 shift;

 my ($name, $cb) = @_;

 _init($name, $cb);

 Sub::Op::enable($name => scalar caller);
}

1;
