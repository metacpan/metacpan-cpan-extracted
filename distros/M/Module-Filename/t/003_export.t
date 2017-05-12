# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;

use Module::Filename qw{module_filename};

is(module_filename("XXX::YYY::ZZZ::NotGoingToExist"), undef, "undef");
like(module_filename("strict"),           qr/strict\.pm$/,   "strict");
like(module_filename("warnings"),         qr/warnings\.pm$/, "warnings");
like(module_filename("Test::More"),       qr/More\.pm$/,     "Test::More");
like(module_filename("Path::Class"),      qr/Class\.pm$/,    "Path::Class");
