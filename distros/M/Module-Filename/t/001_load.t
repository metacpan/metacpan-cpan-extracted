# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok( 'Module::Filename' ); }
BEGIN { use_ok( 'Path::Class' ); }

my $mf = Module::Filename->new;
isa_ok ($mf, 'Module::Filename');
can_ok($mf, qw{new initialize});
can_ok($mf, qw{filename});
