use strict;
use warnings;

use Test::More 0.88;
use Module::Reader qw(:all);
use lib 't/lib';

my $mod_content = do {
  open my $fh, '<'.Module::Reader::_OPEN_LAYERS, 't/lib/TestLib.pm';
  local $/;
  <$fh>;
};

is module_content('TestLib'), $mod_content, 'correctly load module from disk';

done_testing;
