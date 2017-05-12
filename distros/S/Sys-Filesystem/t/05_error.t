#!perl

use strict;
use warnings;

use Test::More;
use Sys::Filesystem;

my $fs;
eval { $fs = Sys::Filesystem->new(); };

$@ and plan skip_all => "Cannot initialize Sys::Filesystem: $@";

eval { $fs = $fs->new(); };
like( $@, qr/Class name required/, "No object new" );

eval { $fs = Sys::Filesystem->new( insane => 1 ); };
like( $@, qr/Unrecognised.*insane.*/, "No insane parameters" );

eval { $fs = Sys::Filesystem->new('insane'); };
like( $@, qr/Odd number of elements passed when even number was expected/, "No odd parameter list" );

done_testing();
