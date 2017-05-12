use strict;
use warnings;
use utf8;
use Test::More;
use Test::CallCounter;

use File::Spec;

my $g = Test::CallCounter->new('File::Spec', 'tmpdir');

File::Spec->tmpdir;

is($g->count, 1);

File::Spec->tmpdir;

is($g->count, 2);

done_testing;

