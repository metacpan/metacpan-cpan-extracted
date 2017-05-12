package builder::MyBuilder;

use strict;
use warnings;
use parent qw/Module::Build/;

die 'OS unsupported'  if ($^O =~ /^(MSWin32|cygwin)$/);

1;
