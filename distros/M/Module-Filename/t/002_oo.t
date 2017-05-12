# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Module::Filename' ); }

my $mf = Module::Filename->new ();
isa_ok ($mf, 'Module::Filename');

is($mf->filename("XXX::YYY::ZZZ::NotGoingToExist"), undef, "undef");
like($mf->filename("strict"),           qr/strict\.pm$/,   "strict");
like($mf->filename("warnings"),         qr/warnings\.pm$/, "warnings");
like($mf->filename("Test::More"),       qr/More\.pm$/,     "Test::More");
like($mf->filename("Path::Class"),      qr/Class\.pm$/,    "Path::Class");
