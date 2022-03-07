# manifest.t
use strict;
use warnings FATAL => 'all';
use Test::More;

require ExtUtils::Manifest;
is_deeply [ExtUtils::Manifest::manicheck()], [], 'missing';
is_deeply [ExtUtils::Manifest::filecheck()], [], 'extra';

done_testing();
