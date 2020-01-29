use strict;
use warnings;

use Test::More;

system('unzip');
skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);
use_ok 'Qiime2::Artifact';

done_testing();
