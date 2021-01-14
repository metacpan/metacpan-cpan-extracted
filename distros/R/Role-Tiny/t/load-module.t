use strict;
use warnings;
no warnings 'once';
use Test::More;
use Role::Tiny ();

use lib 't/lib';

Role::Tiny::_load_module('TrueModule');

is do {
  no strict 'refs';
  ${"TrueModule::LOADED"}
}, 1, 'normal module loaded properly';

{
  package ExistingModule;
  our $LOADED = 0;
}

Role::Tiny::_load_module('ExistingModule');
is do {
  no strict 'refs';
  ${"ExistingModule::LOADED"}
}, 0, 'modules not loaded if symbol table entries exist';

eval { Role::Tiny::_load_module('BrokenModule') };
like "$@", qr/Compilation failed/,
  'broken modules throw errors';
eval { require BrokenModule };
like "$@", qr/Compilation failed/,
  ' ... and still fail if required again';

eval { Role::Tiny::_load_module('FalseModule') };
like "$@", qr/did not return a true value/,
  'modules returning false throw errors';
eval { require FalseModule };
like "$@", qr/did not return a true value/,
  ' ... and still fail if required again';

done_testing;
