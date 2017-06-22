use strict;
use warnings;

use Test::More 0.88;
use Module::Reader qw(:all);
use lib 't/test-data/lib';

my $mod_content = do {
  open my $fh, '<'.Module::Reader::_OPEN_LAYERS, 't/test-data/lib/MyTestModule.pm';
  local $/;
  <$fh>;
};

is module_content('MyTestModule'), $mod_content, 'correctly load module from disk';

done_testing;
