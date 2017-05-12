#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";   

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok 'Combined', qw/Foo2Alias MTFNPY NonEmptyStr/ }

# test that a type from TestLibrary was exported
ok Foo2Alias;

# test that a type from TestLibrary2 was exported
ok MTFNPY;

is NonEmptyStr->name, 'TestLibrary2::NonEmptyStr',
    'precedence for conflicting types is correct';

throws_ok { Combined->import('NonExistentType') }
qr/\Qmain asked for a type (NonExistentType) which is not found in any of the type libraries (TestLibrary TestLibrary2) combined by Combined/,
'asking for a non-existent type from a combined type library gives a useful error';
