use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'Template::Plugin::StringDump' }

diag "Testing Template::Plugin::StringDump "
   . "$Template::Plugin::StringDump::VERSION, Perl $], $^X";
